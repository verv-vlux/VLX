'use strict';

const util = require('./helper/util');

module.exports = {
  networks: {
    test: {
      host: "127.0.0.1",
      port: 8546,
      network_id: "*",
    },
    testnet: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 3,
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
