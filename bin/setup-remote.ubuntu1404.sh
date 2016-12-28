#!/usr/bin/env bash

# This setup works on Ubuntu 14.04 (Tested on EC2 instance).


# Get Node and NPM
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

# Get extra optional build tools
sudo apt-get install -y build-essential

# Get Git
sudo apt-get install git

# Get mongo
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Set Port 80 (http) to reroute to port 3000, where we run our app.
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3000

# Print versions
npm --version
node --version
mongo --version

