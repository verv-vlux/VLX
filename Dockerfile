FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y sudo && sudo apt-get update --fix-missing
RUN sudo apt-get install -y curl wget nano git
RUN sudo apt-get install -y build-essential
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN sudo apt-get install -y nodejs

WORKDIR /root/
