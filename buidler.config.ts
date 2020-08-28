import {task, usePlugin} from '@nomiclabs/buidler/config';
const web3 = require('web3');

usePlugin('@nomiclabs/buidler-truffle5');
usePlugin('@nomiclabs/buidler-web3');

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await web3.eth.getAccounts();

  for (const account of accounts) {
    console.log(account);
  }
});

require('dotenv').config();

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solc: {
    version: '0.6.6', // Fetch exact version from solc-bin (default: truffle's version)
    docker: true, // Use "0.5.1" you've installed locally with docker (default: false)
    settings: {
      // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: 'istanbul'
    }
  },
  networks: {
    develop: {
      url: "http://127.0.0.1:8545",
      gas: 6000000,
      timeout: 20000
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
      gasPrice: 90000000000
    }
  }
};
