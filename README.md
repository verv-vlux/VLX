# Verv Vlux ITO

This repository contains Verv Vlux ITO contracts

## Prerequisites

- NodeJS >= v8.x
- Linux/MacOS

## Installation

```bash
npm install
```

## Configuration

In order to configure ITO edit:

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

## Usage With Docker

Testing with Docker needs the following Dockerfile:

Linux:

If not already installed, install docker from the ubuntu repositories with:

```bash
sudo apt-get install docker
```

In a directory of your choosing, create a Dockerfile with exact name "DockerFile"
Note: Capital "D" for the file name is neccessary for docker to recognise the configuration

Copy the configuration below into this file and save

```
FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y sudo
RUN sudo apt-get install -y curl wget nano git
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN sudo apt-get install -y nodejs
WORKDIR /root/
```

After building the container run the tests with the same steps described above.

## Architectural and Security Overview

The following documents were automatically generated by [solco](https://www.npmjs.com/package/solco) utility.

- `VervFluxCrowdsale.sol`
  1. [Flow Diagram](docs/flow-VervFluxCrowdsale.svg)
  2. [Interface](docs/interface-VervFluxCrowdsale.txt)
  3. [Formal Analysis](docs/analysis-VervFluxCrowdsale.txt)

## License

?

