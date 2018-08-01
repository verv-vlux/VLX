FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y sudo
RUN sudo apt-get install -y curl wget nano git
RUN sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN sudo apt-get install -y nodejs

WORKDIR /root/
