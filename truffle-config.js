var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
var mnemonic2 = "access swallow wasp glory anger domain adult cousin ignore month put apple";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      accounts: 50
    },
    dev: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      accounts: 50
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  },
  mocha: {
    useColors: true
  }
};