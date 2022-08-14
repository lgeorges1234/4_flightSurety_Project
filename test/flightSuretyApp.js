
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

    // ACT
    try {
      await config.flightSuretyApp.registerFirstAirline.call(config.firstAirline, {from: config.owner});
      }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(config.firstAirline);
    // ASSERT
    assert.equal(result, true, "ContractOwner should be able to register the first airline");

  });

  it('(airline) can fund the airline when registered using submitFundsAirline()', async () => {
    
    // ARRANGE
    let contractBalanceBefore = await config.flightSuretyData.getBalance.call();
    console.log(contractBalanceBefore.toString())
    let re = await config.flightSuretyData.isFundedAirline.call(config.firstAirline); 
    console.log(`data isFundedAirline before: ${re}`)
    // ACT
    try {

    }
    catch(e) {

    }

    let res = await config.flightSuretyApp.submitFundsAirline.call({from: config.firstAirline, value:AIRLINE_REGISTRATION_FEE});
    console.log(`app submitFundsAirline return: ${res}`)

    let result = await config.flightSuretyData.isFundedAirline.call(config.firstAirline); 
    console.log(`data isFundedAirline after: ${result}`)
    let contractBalanceAfter = await config.flightSuretyData.getBalance.call();
    console.log(contractBalanceAfter.toString())
    // ASSERT
    assert.equal(result, true, "Airline should be able to fund the contract");

  });

    it('(airline) can register an Airline using registerAirline()', async () => {
    
      // ARRANGE
      let newAirline = accounts[2];
      await config.flightSuretyApp.submitFundsAirline.call({from: config.firstAirline, value:AIRLINE_REGISTRATION_FEE});

      // ACT
      try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        }
      catch(e) {

      }
      let result = await config.flightSuretyData.isAirline.call(newAirline); 

  
      // ASSERT
      assert.equal(result, true, "Airline should be able to register another airline");
    });


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
      console.log(e)
    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
 

});
