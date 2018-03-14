# Verv Flux ICO

This repository contains Verv Flux ICO contracts

## Requirements

Token requirements:

- [x] Standard: “ERC20”
- [x] Decimals: “18”
- [x] Name “Verv Flux”
- [x] Symbol “FLX”
- [x] Extends “MintableToken”
- [x] Extends “Ownable”
- [x] Initial supply is undefined

ICO requirements:

- [x] Extends “Ownable”
- [x] Extends “Pausable”
- [x] Start time is “Saturday, March 31, 2018 12:00:00 AM” editable before start
- [x] End time is “Wednesday, April 4, 2018 12:00:00 AM” editable before start
- [x] Rate is “2000 FLX/ETH” editable before start
- [x] Investments are transferred to a multisig “wallet”
- [x] Tokens retained by the “company” - 34% transferred after sale end
- [x] Ability to add addresses to whitelist available before start
- [x] Bonus day 1 - “15%”
- [x] Bonus day 2 - “12.5%”
- [x] Bonus day 3 - “10%”
- [x] Day 1 allows whitelisted addresses to contribute a maximal amount of “10 ETH”
- [x] Day 2 allows whitelisted addresses to contribute any amount
- [x] Day 3 allows anyone to contribute any amount
- [x] Presale investment using function distributePreBuyersLkdRewards(investor, tokens, vesting)” available before start
- [x] Presale investment using function disbursePreBuyersLkdContributions(investor, rate, vesting)” available before start (must be used real ether)
- [x] Maximal rate for presale investment (disbursePreBuyersLkdContributions) is 8000
- [x] Make possible updating ETH cap where `newCap > oldCap` (to match £20M target)
- [x] Finish minting after the ICO ends

Vesting requirements:

- [x] Lockup period is calculated from the sale end time
- [x] Non revocable (once created we can not revoke distributed tokens)
- [x] Available vesting duration periods - 3 months, 6 months, 12 months
- [x] Vesting occurs second-by-second (after 3 months lockup period)

> Requirements document can be found [here](https://docs.google.com/document/d/1vlb29sP17eWXRxJUBcBjonPCEwwmjEJO5mrtQ1uvc-4/edit)

## Prerequisites

- NodeJS >= v8.x
- Linux/MacOS

## Installation

```bash
npm install
```

## Configuration

In order to configure ICO edit:

- [MAINNET configuration](mainnet.config.json)
- [TESTNET configuration](testnet.config.json)
- [TEST configuration](test.config.json) (`npm run test`)

## Usage

Testing:

```bash
npm run testrpc
npm run test
```

> Note that you have to rerun the `testrpc` because EVM traveled in time...

Deplying to [test network](https://ropsten.etherscan.io) (`Ropsten`):

```bash
# 1.a.  geth --testnet --verbosity 4 --rpc --rpcapi db,debug,net,personal,shh,txpool,admin,eth,miner,web3 --cache 1024 --vmdebug
# 1.b.  parity --chain ropsten --jsonrpc-apis="all" --geth -l sync=trace --cache-size 2048
# 2.    geth attach http://127.0.0.1:8545
# 3.    (geth console)> personal.unlockAccount('{admin_wallet}', '{admin_password}', 86400)
npm run deploy:testnet
```

Deplying to [main network](https://etherscan.io):

Before deploying to `mainnet` ensure you set optimal gas price in `gas.json`. Use [ethgasstation.info](https://ethgasstation.info) for this purpose.

```bash
# 1.a.  geth --verbosity 4 --rpc --rpcapi db,debug,net,personal,shh,txpool,admin,eth,miner,web3 --cache 1024 --vmdebug
# 1.b.  parity --jsonrpc-apis="all" --geth -l sync=trace --cache-size 2048
# 2.    geth attach http://127.0.0.1:8545
# 3.    (geth console)> personal.unlockAccount('{admin_wallet}', '{admin_password}', 86400)
npm run deploy:mainnet
```

> If there are problems w/ `UPnP not discovered` when running `geth` use `geth --nat "extip:$(dig +short myip.opendns.com @resolver1.opendns.com)"` followed by desired parameters.
> If there are no peers connected to geth (`No discv4 seed nodes found`) use `geth attach http://127.0.0.1:8545` and than ass notes manually from `https://gist.github.com/rfikki/` (`ropsten-peers-latest.txt` for testnet and `mainnet-peers-latest.txt` for mainnet).

Run wallet application:

- To run `Ethereum Wallet` on Mac use `/Applications/Ethereum\ Wallet.app/Contents/MacOS/Ethereum\ Wallet --rpc http://127.0.0.1:8545`
- To run `Mist` on Mac use `/Applications/Mist.app/Contents/MacOS/Mist --rpc http://127.0.0.1:8545`

## Architectural and Security Overview

The following documents were automatically generated by [solco](https://www.npmjs.com/package/solco) utility.

- `VervFluxCrowdsale.sol`
  1. [Flow Diagram](docs/flow-VervFluxCrowdsale.svg)
  2. [Interface](docs/interface-VervFluxCrowdsale.txt)
  3. [Formal Analysis](docs/analysis-VervFluxCrowdsale.txt)