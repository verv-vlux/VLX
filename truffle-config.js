'use strict';

const util = require('./helper/util');

module.exports = {
  networks: {
    test: {
      host: "127.0.0.1",
      port: 8546,
      network_id: "*",
      gasPrice: 1000000000,
    },
    testnet: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 3,
      gasPrice: 30000000000,
      gas: util.gas.maxGas,
    },
    mainnet: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 1,
      gas: util.gas.maxGas,
      gasPrice: util.gas.price,
    },
  },
  solc: { optimizer: { enabled: true, runs: 200 } },
};
