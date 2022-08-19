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
        bytes32[] flight;
    }

    mapping (address => Airline) Airlines;

    // flight structure
    struct Flight {
        bytes32 flightsID;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;   
        address airline;     
    }

    mapping (bytes32 => Flight) Flights;

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
        Airlines[_airline].airline = _airline;
        Airlines[_airline].registered = true;
        Airlines[_airline].funded = false;
        totalAirlines = totalAirlines.add(1);
        emit AirlineWasRegistered(_airline, Airlines[_airline].registered);
    }

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
    * @dev Add a flight to the registration queue
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
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp);
        Flights[_flightID] = Flight({flightsID: _flightID, isRegistered: true, statusCode: _statusCode, updatedTimestamp: _timeStamp, airline: _airline});
        Airlines[_airline].flight.push(_flightID);
        emit FlightWasRegistered(_flightID, _flightName, _timeStamp, _statusCode, _airline);
    }

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

    function viewFlightSatus 
                            (
                                string _flightName,
                                address _airline,
                                uint256 _timeStamp                              
                            )
                            returns(uint256)
    {
        bytes32 _flightID = getFlightKey(_airline, _flightName, _timeStamp); 
        require(Flights[_flightID].isRegistered == true, "Flight must first be registered before to get status");
        return Flights[_flightID].statusCode;  
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

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
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
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

