const BN = web3.utils.BN;

const L2 = artifacts.require('L2');

const blockchain = require('../test/blockchain');

async function main () {
  let accounts = await web3.eth.getAccounts();

  console.log(accounts[0]);

  let bc = new blockchain.Blockchain();
  // add block to blockchain
  let block = new blockchain.Block(new BN(0));
  for (let i = 0; i < 10; i++) {
    block.addTransaction(new blockchain.Deposit(rand(2 ** 30 - 1), rand(2 ** 10 - 1), new BN(2 ** 32 - 1), 0));
  }

  // let l2 = await L2.new();
  let l2 = await L2.at('0x5d6fbfd41c9381d1e3f194cf99e86ac463de66c3');
  await submitAndSimulateBlock(l2, bc, block);
}

async function submitAndSimulateBlock (l2, bc, block) {
  let {blockHash, blockNumber} = await l2.lastestBlock();

  let [bcProof, txProofs] = bc.addBlock(block);

  let newBlockHash = block.hash();
  let blockPubData = '0x' + block.toBuffer().toString('hex');

  await l2.submitBlock(blockHash, bc.tree.rootHash(), newBlockHash, blockPubData);
  let result = await l2.simulatedBlock(
    blockNumber.add(new BN(1)),
    blockPubData,
    '0x' + bcProof.toBuffer().toString('hex'),
    txProofs
  );
  console.log(result.receipt);
  console.log('gas used', result.receipt.gasUsed);
}

function rand (value) {
  return Math.floor(Math.random() * value);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
