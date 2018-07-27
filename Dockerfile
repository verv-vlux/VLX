FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y sudo
RUN sudo apt-get install -y curl wget nano git
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN sudo apt-get install -y nodejs
RUN sudo npm install -g axios@0.17.1
RUN sudo npm install -g chalk@2.3.1
RUN sudo npm install -g etherscan-link@1.0.2
RUN sudo npm install -g ganache-cli@6.1.0-beta.0
RUN sudo npm install -g solco@0.2.0
RUN sudo npm install -g truffle@4.0.6
RUN sudo npm install -g web3@0.20.5
RUN sudo npm install -g zeppelin-solidity@1.6.0
RUN ln -s /usr/lib/node_modules /root/

WORKDIR /root/
