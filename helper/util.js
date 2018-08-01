'use strict';

const Web3 = require('web3');
const fs = require('fs');
const path = require('path');
const etherscanLink = require('etherscan-link');
const chalk = require('chalk');

const _accountsToSkip = [];
const cfgFile = `../${ process.env.ICO_NETWORK || 'test' }.config.json`;
const cfg = require(cfgFile);
const gas = require('../gas.json');

const web3 = new Web3();

const { toWei, fromWei, toBigNumber } = web3;

function logEnvVar(key, meaning) {
  console.info('[INFO]', chalk.yellow(key), chalk.gray(meaning));
}

function logAddress(name, address) {
  console.info(name, '>', chalk.green(createAccountLink(address)));
}

function logTx(name, hash) {
  console.info(name, '>', chalk.green(createExplorerLink(hash)));
}

function logTxStatus(status) {
  const succeed = status === '0x1';
  const color = succeed ? 'green' : 'red';
  const text = succeed ? 'Succeed' : 'Failed';

  console.info('status >', chalk.blue(status), chalk[color](`(${ text })`));
}

function logVar(name, value) {
  console.info(name, '>', chalk.blue(value));
}

function networkId() {
  switch(process.env.ICO_NETWORK) {
    case 'mainnet':
      return 1;
    default:
      return 3;
  }
}

function createAccountLink(account) {
  return etherscanLink.createAccountLink(account, networkId());
}

function createExplorerLink(hash) {
  return etherscanLink.createExplorerLink(hash, networkId());
}

function toTime(str) {
  return Math.ceil(new Date(str).getTime() / 1000);
}

function isTest() {
  return process.argv[2].toLowerCase() === 'test';
}

function accounts(accounts) {
  const result = {};
  const keys = Object.keys(cfg)
    .filter(k => cfg[k] && cfg[k].indexOf('0x') === 0);

  for (let i in keys) {
    const key = keys[i];
    result[key] = isTest() ? accounts[i] : cfg[key];
    _accountsToSkip.push(result[key]);
  }

  return result;
}

class AccountsHelper {
  constructor(accounts, toSkip = []) {
    this.toSkip = toSkip;
    this.accounts = [].concat(accounts);
    this.unusedAccounts = [].concat(accounts);
    this.usedAccounts = [];
    this._current = null;
  }
  
  next() {
    do {
      this._current = this.unusedAccounts.shift();
    } while (this.toSkip.indexOf(this._current) !== -1);

    this.usedAccounts.push(this._current);

    return this.current;
  }

  get current() {
    return this._current;
  }
}

class EVMHelper {
  constructor(web3) {
    this.web3 = web3;
    this.lastTraveledTo = EVMHelper.now();
    this.logger = console.info;
  }

  static now() {
    return Math.ceil(Date.now() / 1000);
  }

  _formatLog(header, msg = null) {
    return `    > ${ msg ? `${ header }: ${ msg }` : header }`;
  }

  timeTravelTo(time, mine = true) {
    const travelDiff = parseInt(time) - this.lastTraveledTo;

    if (travelDiff < 0) {
      return Promise.reject(new Error('Unable to travel back in time.'));
    } else if (travelDiff === 0) {
      return Promise.resolve();
    }

    return this.timeTravel(travelDiff, mine);
  }

  timeTravel(time, mine = true) {
    return new Promise((resolve, reject) => {
      this.lastTraveledTo += time;
 
      this.logger(this._formatLog('Travel in time', new Date(this.lastTraveledTo * 1000).toISOString()));
  
      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [ time ],
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }
        
        resolve();
      });
    }).then(() => mine ? this.mineBlock() : undefined);
  }

  mineBlock() {
    return new Promise((resolve, reject) => {
      this.logger(this._formatLog('Mine block'));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: EVMHelper.now(),
      }, (error, result) => error ? reject(error) : resolve());
    });
  }

  snapshot() {
    return new Promise((resolve, reject) => {
      this.logger(this._formatLog('Take snapshot'));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_snapshot',
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }
        
        resolve(result.result);
      });
    });
  }

  revert(snapshot, mine = true) {
    return new Promise((resolve, reject) => {
      this.logger(this._formatLog('Revert to state', snapshot));

      this.web3.currentProvider.sendAsync({
        jsonrpc: '2.0',
        method: 'evm_revert',
        params: [ snapshot ],
        id: EVMHelper.now(),
      }, (error, result) => {
        if (error) {
          return reject(error);
        }
        
        resolve();
      });
    }).then(() => mine ? this.mineBlock() : undefined);
  }
}

const Stages = {
  PreSale: '0',
  Sale: '1',
  SaleOver: '2',
};

const VestingDuration = {
  Mo3: '0',
  Mo6: '1',
  Mo9: '2',
  Mo12: '3',
};

const START_TIME = toTime('Thursday, August 2, 2018 0:00:00 AM GMT+00:00');
const END_TIME = toTime('Sunday, August 5, 2018 0:00:00 AM GMT+00:00');

module.exports = {
  toWei, fromWei, toBigNumber,
  logEnvVar, logAddress, logTx,
  logTxStatus, logVar, networkId,
  createAccountLink, createExplorerLink,
  toTime, isTest, AccountsHelper, EVMHelper,
  evm: web3 => new EVMHelper(web3),
  identity: accounts => new AccountsHelper(accounts, _accountsToSkip),
  gas, accounts, cfg, Stages, VestingDuration,
  START_TIME, END_TIME,
};
