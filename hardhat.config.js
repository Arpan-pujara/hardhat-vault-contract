require('@nomicfoundation/hardhat-toolbox');
require('hardhat-gas-reporter');
require('hardhat-contract-sizer');
require('dotenv').config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {},
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.GORELI_ALCHEMY_KEY}`,
     accounts: [`0x${PRIVATE_KEY}`]
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.SEPOLIA_ALCHEMY_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.MAINNET_ALCHEMY_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  // gasReporter: {
  //   enabled: true,
  //   currency: 'INR',
  //   coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  //   token: "ETH"
  // },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
    strict: true,
    except: [],
  },
};
