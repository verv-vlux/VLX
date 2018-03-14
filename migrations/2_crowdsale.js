'use strict';

const util = require('../helper/util');
const VervFluxCrowdsale = artifacts.require('./VervFluxCrowdsale.sol');

module.exports = (deployer, network, accounts) => {
  const addresses = util.accounts(util.isTest() ? accounts : []);

  deployer.deploy(
    VervFluxCrowdsale,
    addresses.owner,
    addresses.companyWallet,
    addresses.wallet,
    util.toWei(util.cfg.cap, 'ether'),
    { gas: util.gas.amount.VervFluxCrowdsale }
  );
};
