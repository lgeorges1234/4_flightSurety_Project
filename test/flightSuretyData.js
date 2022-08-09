
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var AIRLINE_SEED_FUNDING = 10;

contract('Flight Surety Data Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) FlighySuretyData has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });



  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) can register an Airline using registerAirline()', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyData.registerAirline(newAirline, {from: config.firstAirline});
      }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 
    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline");

  });

  it('(airline) can provide seed funds using submitFundsAirline) ', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let AIRLINE_SEED_FUNDING = web3.utils.toWei("10", "ether");
    // ACT
    try {
        await config.flightSuretyData.registerAirline(newAirline, {from: config.firstAirline});
        await config.flightSuretyData.submitFundsAirline(newAirline, {from: newAirline, value: AIRLINE_SEED_FUNDING});
    }
    catch(e) {

    }
    await config.flightSuretyData.isAirline.call(newAirline); 

    let result = await config.flightSuretyData.isFundedAirline.call(newAirline); 
    // ASSERT
    assert.equal(result, true, "Airline has not provided funding");
    
  });
 

});