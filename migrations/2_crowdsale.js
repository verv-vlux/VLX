'use strict';

const util = require('../helper/util');
const VervVluxCrowdsale = artifacts.require('./VervVluxCrowdsale.sol');

module.exports = (deployer, network, accounts) => {
  const addresses = util.accounts(util.isTest() ? accounts : []);
  /*
  const addresses = {
    owner: accounts[7],
    companyWallet: accounts[8],
    wallet: accounts[9],
  }
  */

  deployer.deploy(
    VervVluxCrowdsale,
    addresses.owner,
    addresses.companyWallet,
    addresses.wallet,
    util.toWei(util.cfg.cap, 'ether'),
    util.START_TIME,
    { gas: util.gas.amount.VervVluxCrowdsale }
  );
};
