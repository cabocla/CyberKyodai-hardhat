require("@nomicfoundation/hardhat-toolbox");
require("hardhat-contract-sizer");
require("@openzeppelin/hardhat-upgrades");
require("@truffle/dashboard-hardhat-plugin");
require("dotenv").config();
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    goerli: {
      url: process.env.GOERLI_INFURA_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: process.env.MUMBAI_INFURA_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    "truffle-dashboard": {
      url: "http://localhost:24012/rpc",
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API,
    // apiKey: process.env.POLYSCAN_API,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    // only: [':ERC20$'],
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    enabled: true,
  },
};
