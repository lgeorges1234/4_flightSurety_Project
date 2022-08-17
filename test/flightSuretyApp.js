
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


  // it('(contractOwner) can register the first Airline using registerAirline()', async () => {
    
  //   // ARRANGE
  //   let registerFirstAirlineResult;
  //   // ACT
  //   try {
  //     registerFirstAirlineResult = await config.flightSuretyApp.registerFirstAirline(config.firstAirline, {from: config.owner});
  //   }
  //   catch(e) {

  //   }
  //   let result = await config.flightSuretyData.isAirline.call(config.firstAirline);
  //   // ASSERT
  //   assert.equal(result, true, "ContractOwner should be able to register the first airline");
  //   assert.equal(registerFirstAirlineResult.logs[0].event , "AirlineWasRegisteredApp", "Event AirlineWasRegisteredApp was not emitted");
  // });


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
      let newAirline = accounts[3];
      let notRegisteredAirline = accounts[4];
      
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
    let newAirline = accounts[5];
    let notFundedAirline = accounts[6];
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
 
  it('(airline) cannnot register a new airline using registerAirline() if it has not a majority of votes', async () => {
    
    // ARRANGE
    let airlineTwo = accounts[2];
    let airlineThree = accounts[3];
    let airlineFour= accounts[6];
    let airlineHasToBeValidated = accounts[7];

    await config.flightSuretyApp.registerAirline(airlineThree, {from:config.firstAirline});

    await config.flightSuretyApp.submitFundsAirline({from: airlineTwo, value:AIRLINE_REGISTRATION_FEE});
    await config.flightSuretyApp.submitFundsAirline({from: airlineThree, value:AIRLINE_REGISTRATION_FEE});
    await config.flightSuretyApp.submitFundsAirline({from: airlineFour, value:AIRLINE_REGISTRATION_FEE});

    // ACT
    try {
      await config.flightSuretyApp.registerAirline(airlineHasToBeValidated, {from:config.firstAirline});
    }
    catch(e) {

    }

    
    let howManyRegisteredAirlinesResult = await config.flightSuretyData.howManyRegisteredAirlines();
    let isRegisteredResult = await config.flightSuretyData.isAirline.call(airlineHasToBeValidated); 

    // ASSERT
    assert.equal(isRegisteredResult, false, "Airline should have not been registered")
    assert.equal(howManyRegisteredAirlinesResult, 4, "Airline registered number should not be increased by one");
  });

  it('(airline) cannnot register a new airline using registerAirline() if the voter has already voted', async () => {
    
    // ARRANGE
    let airlineTwo = accounts[2];
    let airlineThree = accounts[3];
    let airlineFour= accounts[6];
    let airlineHasToBeValidated = accounts[7];

    let hasAlreadyVoted = false;

    // ACT
    try {
      await config.flightSuretyApp.registerAirline(airlineHasToBeValidated, {from:config.firstAirline});
    }
    catch(e) {
      hasAlreadyVoted = true;
    }

    let howManyRegisteredAirlinesResult = await config.flightSuretyData.howManyRegisteredAirlines();
    let isRegisteredResult = await config.flightSuretyData.isAirline.call(airlineHasToBeValidated); 

    // ASSERT
    assert.equal(hasAlreadyVoted, true, "Airline should not be able to vote a second time")
    assert.equal(isRegisteredResult, false, "Airline should have not been registered")
    assert.equal(howManyRegisteredAirlinesResult, 4, "Airline registered number should not be increased by one");
  });

  it('(airline) needs majority of votes to register a new airline using registerAirline()', async () => {
    
    // ARRANGE
    let airlineTwo = accounts[2];
    let airlineThree = accounts[3];
    let airlineFour= accounts[6];
    let airlineHasToBeValidated = accounts[8];

    let voteIncrease1;
    let voteIncrease2;
    let voteIncrease3;

    // await config.flightSuretyApp.registerAirline(airlineTwo, {from:config.firstAirline});
    // await config.flightSuretyApp.registerAirline(airlineThree, {from:config.firstAirline});
    // await config.flightSuretyApp.registerAirline(airlineFour, {from:config.firstAirline});

    // console.log(await config.flightSuretyData.isAirline.call(airlineTwo))
    // console.log(await config.flightSuretyData.isAirline.call(airlineThree))
    // console.log(await config.flightSuretyData.isAirline.call(airlineFour))

    // await config.flightSuretyApp.submitFundsAirline({from: airlineTwo, value:AIRLINE_REGISTRATION_FEE});
    // await config.flightSuretyApp.submitFundsAirline({from: airlineThree, value:AIRLINE_REGISTRATION_FEE});
    // await config.flightSuretyApp.submitFundsAirline({from: airlineFour, value:AIRLINE_REGISTRATION_FEE});

    // console.log(await config.flightSuretyData.isFundedAirline.call(airlineTwo))
    // console.log(await config.flightSuretyData.isFundedAirline.call(airlineThree))
    // console.log(await config.flightSuretyData.isFundedAirline.call(airlineFour))


    // ACT
    try {
      voteIncrease1 = await config.flightSuretyApp.registerAirline(airlineHasToBeValidated, {from:config.firstAirline});
      voteIncrease2 = await config.flightSuretyApp.registerAirline(airlineHasToBeValidated, {from:airlineTwo});
    }
    catch(e) {
      console.log(e);
    }

    let howManyRegisteredAirlinesResult = await config.flightSuretyData.howManyRegisteredAirlines();
    let result = await config.flightSuretyData.isAirline.call(airlineHasToBeValidated); 

    // ASSERT
    assert.equal(result, true, "Airline has not obtained enough votes");
    assert.equal(howManyRegisteredAirlinesResult, 5, "Airline registered number should not be increased by one");
  });


});
