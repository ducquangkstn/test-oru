import { task, usePlugin } from "@nomiclabs/buidler/config";
const web3 = require('web3')

usePlugin('@nomiclabs/buidler-truffle5')

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await web3.eth.getAccounts()

  for (const account of accounts) {
    console.log(account)
  }
})

module.exports = {
  solc: {
    version: '0.6.6', // Fetch exact version from solc-bin (default: truffle's version)
    docker: true, // Use "0.5.1" you've installed locally with docker (default: false)
    settings: {
      // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: false,
        runs: 200
      },
      evmVersion: 'istanbul'
    }
  },
  network: {
    buidlerevm: {
      blockGasLimit: 12500000
    }
  },
  mocha: {
    enableTimeouts: false
  }
}
