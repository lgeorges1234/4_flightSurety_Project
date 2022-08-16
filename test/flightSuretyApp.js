
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety App Tests ', async (accounts) => {

  let AIRLINE_REGISTRATION_FEE = web3.utils.toWei("10", "ether");
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/


  it(`(multiparty) FlighySuretyApp can reach isOperational() value from FlightSuretyData`, async function () {

    // Get operating status
    let status = await config.flightSuretyApp.isOperational.call();
    let dataStatus = await config.flightSuretyData.isOperational.call();
    assert.equal(status, dataStatus, "Incorrect initial operating status value");
  });

  // it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

  //     // Ensure that access is denied for non-Contract Owner account
  //     let accessDenied = false;
  //     try 
  //     {
  //         await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
  //     }
  //     catch(e) {
  //         accessDenied = true;
  //     }
  //     assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  // });

  // it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

  //     // Ensure that access is allowed for Contract Owner account
  //     let accessDenied = false;
  //     try 
  //     {
  //         await config.flightSuretyData.setOperatingStatus(false);
  //     }
  //     catch(e) {
  //         accessDenied = true;
  //     }
  //     assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  // });

  // it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

  //     await config.flightSuretyData.setOperatingStatus(false);

  //     let reverted = false;
  //     try 
  //     {
  //         await config.flightSurety.setTestingMode(true);
  //     }
  //     catch(e) {
  //         reverted = true;
  //     }
  //     assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

  //     // Set it back for other tests to work
  //     await config.flightSuretyData.setOperatingStatus(true);

  // });


  it('(contractOwner) can register the first Airline using registerAirline()', async () => {
    
    // ARRANGE
    let registerFirstAirlineResult;
    // ACT
    try {
      registerFirstAirlineResult = await config.flightSuretyApp.registerFirstAirline(config.firstAirline, {from: config.owner});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(config.firstAirline);
    // ASSERT
    assert.equal(result, true, "ContractOwner should be able to register the first airline");
    assert.equal(registerFirstAirlineResult.logs[0].event , "AirlineWasRegisteredApp", "Event AirlineWasRegisteredApp was not emitted");
  });


  it('(airline) can fund the firstAirline using submitFundsAirline()', async () => {

    
    // ARRANGE
    let submitFundsResult;
    let contractBalanceBefore = await config.flightSuretyData.getBalance.call();
    // ACT
    try {
      submitFundsResult = await config.flightSuretyApp.submitFundsAirline({from: config.firstAirline, value:AIRLINE_REGISTRATION_FEE});
    }
    catch(e) {

    }

    let result = await config.flightSuretyData.isFundedAirline.call(config.firstAirline); 
    
    let contractBalanceAfter = await config.flightSuretyData.getBalance.call();
    // ASSERT
    assert.equal(result, true, "Airline should be able to fund the contract");
    assert.equal(contractBalanceAfter - contractBalanceBefore, AIRLINE_REGISTRATION_FEE, "Balance has not been increased from funds")
    assert.equal(submitFundsResult.logs[0].event , "AirlineWasFundedApp", "Event AirlineWasFundedApp was not emitted");
  });

    it('(airline) can register an Airline using registerAirline()', async () => {
    
      // ARRANGE
      let registerResult;
      let newAirline = accounts[2];
      // ACT
      try {
        registerResult = await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        }
      catch(e) {      
      }

      let result = await config.flightSuretyData.isAirline.call(newAirline); 

      // ASSERT
      assert.equal(result, true, "Airline should be able to register another airline");
      assert.equal(registerResult.logs[0].event , "AirlineWasRegisteredApp", "Event AirlineWasFundedApp was not emitted");
    });


    it('(airline) cannot register an Airline using registerAirline() if not registered', async () => {
    
      // ARRANGE
      let newAirline = accounts[6];
      let notRegisteredAirline = accounts[7];
      
      // ACT
      try {
        await config.flightSuretyApp.registerAirline(newAirline, {from:notRegisteredAirline})
      }
      catch(e) {
      }
      let result = await config.flightSuretyData.isAirline.call(newAirline); 
  
      // ASSERT
      assert.equal(result, false, "Airline should not be able to register another airline if it is not registered");
    })


  it('(airline) cannot register an Airline using registerAirline() if not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[4];
    let notFundedAirline = accounts[5];
    await config.flightSuretyApp.registerAirline(notFundedAirline, {from:config.firstAirline})

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: notFundedAirline});
    }
    catch(e) {
    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
 
});
