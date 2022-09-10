require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
require('hardhat-tracer');
require('@nomiclabs/hardhat-etherscan');
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: '0.8.7',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
        },
    },
    networks: {
        rinkeby: {
            url: "https://rinkeby.infura.io/v3/3dd98184c72b4d33b8a14df118295912",
            accounts: ["0x665ba4a3166c25b10fd1a4d3fcf330666164cc8e9a4f50cd06ef6e2fbf0a3183"]
        },
        mainnet: {
            url: "https://mainnet.infura.io/v3/3dd98184c72b4d33b8a14df118295912",
            accounts: ["0x665ba4a3166c25b10fd1a4d3fcf330666164cc8e9a4f50cd06ef6e2fbf0a3183"]
        }
    }
};
