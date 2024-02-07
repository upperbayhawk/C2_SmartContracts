require("@nomicfoundation/hardhat-toolbox");
//require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    goerli: {
      url: "https://eth-goerli.public.blastapi.io",
      accounts: ["0x9e07a5d23dd4eb1a551bcbe7364deb089d991aeb5ec6b323f71d9329b71a3bd4"]
    }
  }
};
