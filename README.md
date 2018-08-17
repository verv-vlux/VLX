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

Linux:

If not already installed, install docker from your chosen repository.

Below is the command for ubuntu based distributions:

```bash
sudo apt-get install docker
```
In a directory of your choosing, pull/download the repository.

You should notice there is a Dockerfile included with the repository.
This contains the configuration of packages necessary to run the test environment.

This Dockerfile contains the following:

```
FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y sudo && sudo apt-get update --fix-missing
RUN sudo apt-get install -y curl wget nano git
RUN sudo apt-get install -y build-essential
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN sudo apt-get install -y nodejs

WORKDIR /root/
```

While having the terminal in this directory, run the following command to generate your docker image.

```bash
docker build -t <IMAGE NAME> .
```

Next, in the same directory where you chose to store the repository files, start the docker container with a shared folder.

```bash
docker run -v $(pwd):/root/ -it --name <CONTAINER NAME> <IMAGE NAME>
```
This should start bash in the new docker container.
Next, try executing the command below and verify all the repository files are present
```bash
ls
```
You should see the following:

![1 ls](https://user-images.githubusercontent.com/41786403/43727142-0f82c00e-9999-11e8-997f-70354ec566ea.png)

Once you have verified all the files are present, you must now install the required modules:

```bash
npm install
```
Ensure that all the neccessary packages have been installed without error:

![npminstall](https://user-images.githubusercontent.com/41786403/43769472-b2970802-9a31-11e8-9ec9-b3919784dbe5.png)

You can now launch the test environment in the background with access to logs:

```bash
nohup npm run testrpc > log.txt 2> log.txt &
```

This should launch the wallets in the background without having to open another window:

![npmruntestrpc](https://user-images.githubusercontent.com/41786403/43769696-3d734102-9a32-11e8-98c1-df26050c4317.png)


Finally execute the tests with:

```bash
npm run test
```

If successful, you should see the tests pass like below:

![npmtest](https://user-images.githubusercontent.com/41786403/43769803-8c1dd8da-9a32-11e8-9f19-799de57bd2b7.png)


## Usage with Truffle Flattener

You are also able to verify contracts that were developed with Truffle on Etherscan using a flattened solidty file.

Installation:

If you would like to verify the smart contracts using truffle flattener, install the package while in your docker container:

```bash
npm install truffle-flattener -g
```

While in the main directory, navigate to where the smart contracts are located:

```bash
cd contracts
```
Run the following  with your files of choice to generate your flattened file:

```bash
truffle-flattener <solidity-files>
```

Alternatively you can use the already generated file located in the the same contracts folder. 

## Architectural and Security Overview

The following documents were automatically generated by [solco](https://www.npmjs.com/package/solco) utility:

- `VervFluxCrowdsale.sol`
  1. [Flow Diagram](docs/flow-VervFluxCrowdsale.svg)
  2. [Interface](docs/interface-VervFluxCrowdsale.txt)
  3. [Formal Analysis](docs/analysis-VervFluxCrowdsale.txt)

## License

?
