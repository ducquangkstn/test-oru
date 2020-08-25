const MockOperations = artifacts.require('MockOperations');


const Web3 = require("web3");
const web3 = new Web3();
const BN = web3.utils.BN;

var coder = require('web3-eth-abi');


contract('Operation', accounts => {
  it('test batch proof multiple accounts', async () => {
    let operation = await MockOperations.new();
    
    let data = web3.eth.abi.encodeParameters(['uint256[]', 'uint256[]', 'tuple(uint256[], uint256[], uint256[], uint256)[]'], 
        [
            [new BN(0), new BN(1)],
            [new BN(2), new BN(3)],
            [
                [ // account0
                    [new BN(5), new BN(6)],
                    [new BN(7)],
                    [new BN(8)],
                    new BN(4)
                ]
            ]
        ]);
    // let data = coder.encodeParameters(['uint256[]'], [[new BN(0), new BN(1)]]);
    console.log(data);


    // let result = operation.readBlockchainProof(data);
    // console.log(result)
  });
});
