'use strict';

const util = require('../helper/util');
const Migrations = artifacts.require('./Migrations.sol');

module.exports = deployer => {
  deployer.deploy(Migrations, { gas: util.gas.amount.Migrations });
};
