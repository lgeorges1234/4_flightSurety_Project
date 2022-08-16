pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;          // Account used to deploy contract
    address private contractAddress;
    bool private operational = true;        // Blocks all state changes throughout the contract if false

    uint256 private totalBalance;           // total of funds raised by companies

    struct Airline {
        address airline;
        bool registered;
        bool funded;
    }

    mapping (address => Airline) Airlines;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineWasRegistered(address airline, bool registered);
    event AirlineWasFunded(address airline, uint256 amount, bool funded);

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
    }

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

    modifier requireIsRegistered(address airline)
    {
        require(Airlines[airline].registered == true);
        _;
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
                            returns(bool)
    {
        Airlines[_airline] = Airline({airline: _airline, registered: true, funded: false});
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
        Airlines[_airline] = Airline({airline: _airline, registered: true, funded: true});
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
                            payable
    {
        // Transfer the amount to the contract address
        // contractAddress.transfer(_amount);
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
        // fund(address, uint256);
    }


}

