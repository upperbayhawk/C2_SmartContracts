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
    },
    volta: {
      url: "https://volta-rpc.energyweb.org",
      accounts: ["0x0949a8d20891952dbc52ec59a2aaf36dcd97b5a114103ba4c949fdc0652a2a7f"]
    },
    ewc: {
      url: "https://rpc.energyweb.org",
      accounts: ["0x0949a8d20891952dbc52ec59a2aaf36dcd97b5a114103ba4c949fdc0652a2a7f"]
    }
  }
};
