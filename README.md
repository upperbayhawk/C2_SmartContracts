# Hardhat is a development environment for Ethereum software. It consists of different components for editing, compiling, debugging and deploying your smart contracts and dApps, all of which work together to create a complete development environment.

# https://hardhat.org/hardhat-runner/docs/getting-started

# setup
# https://hardhat.org/tutorial/setting-up-the-environment
install git
install node.js

cd "smart contract dir"
npm init -y
npm install hardhat
# npx hardhat init

# compile contracts
npx hardhat compile

# test deployment
npx hardhat run scripts\deploy.js

# deploy contract to blockchain
npx hardhat run scripts\deploy.js --network goerli
npx hardhat run scripts\deploy.js --network volta
npx hardhat run scripts\deploy.js --network ewc



