pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
    ERC20 erc20;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;          // Account used to deploy contract
    address private contractAddress;
    bool private operational = true;        // Blocks all state changes throughout the contract if false

    uint256 private totalBalance = 0;       // total of funds raised by companies
    uint256 private totalAirlines = 0;      // totalt number of registered airlines

    struct Airline {
        address airline;
        bool registered;
        bool funded;
        bytes32[] flightID;
    }

    mapping (address => Airline) Airlines;

    // flight structure
    struct Flight {
        bytes32 flightsID;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;   
        address airline;     
        bytes32[] insuranceID;
    }

    mapping (bytes32 => Flight) Flights;

    struct Insurance {
        bytes32 insuranceID;
        bytes32 flightID;
        address passenger;
        uint256 value;
    }

    mapping (bytes32 => Insurance) Insurances;

/********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsRegistered(address _airline)
    {
        require(Airlines[_airline].registered == true, "Airline is not registered");
        _;
    }

    modifier requireIsNotRegistered(address _airline)
    {
        require(Airlines[_airline].registered == false, "Airline is already registered");
        _;
    }
    modifier requireIsNotFunded(address _airline)
    {
        require(Airlines[_airline].funded == false, "Airline is already funded");
        _;
    }

    modifier requireIsFlightRegistered(address _airline)
    {
        require(Airlines[_airline].registered == true, "Airline is not registered");
        _;
    }

    /********************************************************************************************/
    /*                                       EVENT DECLARATION                                */
    /********************************************************************************************/

    event AirlineWasRegistered(address airline, bool registered);
    event AirlineWasFunded(address airline, uint256 amount, bool funded);
    event funded(address airline, address contractAddress, uint256 amount);
    event FlightWasRegistered(bytes32 _flightID, string _flightName, uint256 _timeStamp, uint8 _statusCode, address _airline);
    event newInsurance(bytes32 insuranceID, string flightName, address passenger, uint256 value);

    /********************************************************************************************/
    /*                                         CONSTRUCTOR                                      */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        contractAddress = address(this);
        totalAirlines = 0;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            external 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _airline
                            )
                            external
                            requireIsOperational
                            requireIsNotRegistered(_airline)
    {
        // Initiate airline into Airlines mapping
        Airlines[_airline].airline = _airline;
        Airlines[_airline].registered = true;
        Airlines[_airline].funded = false;
        // Add 1 to the airline's count
        totalAirlines = totalAirlines.add(1);
        // emit event
        emit AirlineWasRegistered(_airline, Airlines[_airline].registered);
    }

    // Return true if an airline is registered
    function isAirline 
                        (
                            address _airline 
                        )
                        external 
                        view 
                        requireIsOperational
                        returns(bool)
    {
        return Airlines[_airline].registered;
    }

    // Return the number of registered airlines
    function howManyRegisteredAirlines 
                        ()
                        external
                        view
                        requireIsOperational 
                        returns(uint256)
    {
        return totalAirlines;
    }

   /**
    * @dev Fund an airline
    *
    */   
    function submitFundsAirline
                            (   
                                address _airline,
                                uint256 _amount
                            )
                            external
                            payable
                            requireIsOperational
                            requireIsRegistered(_airline)
                            requireIsNotFunded(_airline)

    {
        // Store the actual balance of the contract
        uint256 beforeBalance = totalBalance;
        // Send the amount to the fund function
        // to transfer the amount to the contract address
        // and add the amount to the contract balance
        fund(_airline, _amount);
        // Check if the balance has been increased
        require(totalBalance.sub(beforeBalance) == _amount, "Funds have not been provided");
        // Mark the airline as "funded"
        
        // Airlines[_airline] = Airline({airline: _airline, registered: true, funded: true, flight: });
        Airlines[_airline].funded = true;
        emit AirlineWasFunded(_airline, _amount, Airlines[_airline].funded);
    }

    // Return true if an airline is funded
    function isFundedAirline 
                        (
                            address _airline 
                        )
                        external
                        view 
                        requireIsOperational
                        returns(bool)
    {
        return Airlines[_airline].funded;
    }

   /**
    * @dev Add a flight 
    *      Can only be called from FlightSuretyApp contract
    *
    */ 

    function registerFlight
                            (   
                                string _flightName,
                                uint256 _timeStamp,
                                uint8 _statusCode,
                                address _airline
                            )
                            external
                            requireIsOperational
    {
        // Get a unique 32 bytes ID to the flight given airline, flight name and timestamp
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp);
        // Check if the flight has not been registered yet
        require(Flights[_flightID].isRegistered == false, "Flight is already registered");
        // Initiate flight into flight's mapping
        Flights[_flightID].flightsID = _flightID;
        Flights[_flightID].isRegistered = true;
        Flights[_flightID].statusCode = _statusCode;
        Flights[_flightID].updatedTimestamp = _timeStamp;
        Flights[_flightID].airline = _airline;
        // Add flight ID to Airline in airlines mapping
        Airlines[_airline].flightID.push(_flightID);
        // Emit event
        emit FlightWasRegistered(_flightID, _flightName, _timeStamp, _statusCode, _airline);
    }

    // Return true if flight is registered
    function isFlight 
                        (
                            string _flightName,
                            uint256 _timeStamp,
                            address _airline
                        )
                        external
                        view 
                        requireIsOperational
                        returns(bool)
    {
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp);
        return Flights[_flightID].isRegistered;
    }

    // Return status code of a flight
    function viewFlightSatus 
                            (
                                string _flightName,
                                address _airline,
                                uint256 _timeStamp                              
                            )
                            returns(uint256)
    {
        // Get a unique 32 bytes ID to the flight given airline, flight name and timestamp
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp); 
        // Check if the flight is registered
        require(Flights[_flightID].isRegistered == true, "Flight must first be registered before to get status");
        return Flights[_flightID].statusCode;  
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buyInsurance
                            (   
                                    string _flightName,
                                    uint256 _timeStamp,
                                    address _airline,
                                    address _passenger,
                                    uint256 _value                       
                            )
                            external
                            payable
    {
        // Record account balance before it changes
        uint256 beforeBalance = totalBalance;
        // Get a unique 32 bytes ID to the flight given airline, flight name and timestamp
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp); 
        // Check if the flight is registered
        require(Flights[_flightID].isRegistered == true, "Flight is not registered");
        // Get a unique 32 bytes ID to the insurance given flight id, passenger address and amount given.
        bytes32 _insuranceID = getInsuranceKey(_flightID, _passenger, _value); 
        // Fund contract with insurance
        fund(_passenger, _value);
        // Check if the balance has been increased
        require(totalBalance.sub(beforeBalance) == _value, "Funds have not been provided");
        // Initiate insurance in insurance mapping
        Insurances[_insuranceID] = Insurance({insuranceID: _insuranceID, flightID: _flightID, passenger: _passenger, value: _value});
        // Add insurance ID to flight in flights mapping
        Flights[_flightID].insuranceID.push(_insuranceID);
        // Emit event
        emit newInsurance(_insuranceID, _flightName, _passenger, _value);
    }

    // return true if the passenger is insured for a flight
    function isInsured
                        (
                            string _flightName,
                            uint256 _timeStamp,
                            address _airline,
                            address _passenger,
                            uint256 _value
                        )
                        returns(bool)
    {
        // Get a unique 32 bytes ID to the flight given airline, flight name and timestamp
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp); 
        // Check if the flight is registered
        require(Flights[_flightID].isRegistered == true, "Flight is not registered");
        // Get a unique 32 bytes ID to the insurance given flight id, passenger address and amount given.
        bytes32 _insuranceID = getInsuranceKey(_flightID, _passenger, _value);
        // check if insurance has been initiate
        if(Insurances[_insuranceID].passenger == _passenger) return true;   
        return false;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    
    /**
     *  @dev Buy insurance for a flight
     *
    */
    function buy
                            (
                            )
                            external
                            pure
    {
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address _account,
                                uint256 _amount
                            )
                            public
                            payable
    {
        // Transfer the amount to the contract address
        emit funded(_account, contractOwner, _amount);
        // erc20.transferFrom(_account, contractOwner, _amount);
        // contractOwner.transfer(_amount);
        // Increase the balance of the contract
        totalBalance = totalBalance.add(_amount);
    }

    function getBalance
                            (
                            )
                            external
                            view
                            returns(uint256)
    {
        return totalBalance;
    }

    function getFlightKey
                        (
                            address _airline,
                            string memory _flight,
                            uint256 _timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(_airline, _flight, _timestamp));
    }

        function getInsuranceKey
                        (
                            bytes32 _flightID,
                            address _passenger,
                            uint256 _value
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(_flightID, _passenger, _value));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund(msg.sender, msg.value);
    }


}

