const BN = web3.utils.BN;

const L2 = artifacts.require('L2');

const blockchain = require('../test/blockchain');
const benchmark = require("../test/benchmark/random");

async function main () {
  let l2 = await L2.new();

  let bc = new blockchain.Blockchain();
  // add block to blockchain
  let block = new blockchain.Block(new BN(0));
  let data = benchmark.readInfo();
  for (let i = 0; i < data.userIDs.length; i++) {
    block.addTransaction(new blockchain.Deposit(data.userIDs[i], data.tokenIDs[i], new BN(data.balances[i]), 0));
  }
  await addBlock(l2, bc, block);

  let depositBlock = new blockchain.Block(bc.head());
  let depositData = benchmark.readInfoDeposit();
  for (let i = 0; i < 20; i++) {
    depositBlock.addTransaction(
      new blockchain.Deposit(depositData.senderIDs[i], depositData.tokenIDs[i], new BN(depositData.amounts[i]), 1)
    );
  }
  await submitAndSimulateBlock(l2, bc, depositBlock);
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

async function addBlock (l2, bc, block) {
  let {blockHash, blockNumber} = await l2.lastestBlock();

  let [bcProof, txProofs] = bc.addBlock(block);
  let newBlockHash = block.hash();
  let blockPubData = '0x' + block.toBuffer().toString('hex');
  await l2.submitBlock(blockHash, bc.tree.rootHash(), newBlockHash, blockPubData);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
