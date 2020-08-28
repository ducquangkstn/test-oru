const L2 = artifacts.require('L2');

const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const BN = web3.utils.BN;

const {MerkleTree} = require('./treeHelpers');
const blockchain = require('./blockchain');
const Helpers = require('./helpers');

contract('L2', (accounts) => {
  describe('test', async () => {
    it('test deposit', async () => {
      let bc = new blockchain.Blockchain();
      // add block to blockchain
      let block = new blockchain.Block(new BN(0));
      block.addTransaction(new blockchain.Deposit(1, 0, new BN(234), 0));
      let l2 = await L2.new();
      await submitAndSimulateBlock(l2, bc, block);
      // add to existing account with
      let block2 = new blockchain.Block(bc.head());
      block2.addTransaction(new blockchain.Deposit(1, 1, new BN(89), 1));
      block2.addTransaction(new blockchain.Deposit(1, 0, new BN(6), 2));
      await submitAndSimulateBlock(l2, bc, block2);
    });

    it.only('bench mark deposit', async() => {
      let bc = new blockchain.Blockchain();
      // add block to blockchain
      let block = new blockchain.Block(new BN(0));
      for(let i =0; i< 10;i++){
        block.addTransaction(new blockchain.Deposit(rand(2**30 -1), rand(2**10 -1), new BN(2**32 -1), 0));
      }

      let l2 = await L2.new();
      await submitAndSimulateBlock(l2, bc, block);
    });

    it('test transfer', async () => {
      let bc = new blockchain.Blockchain();
      // add block to blockchain
      let block = new blockchain.Block(new BN(0));
      block.addTransaction(new blockchain.Deposit(1, 0, new BN(234), 0));
      block.addTransaction(new blockchain.Transfer(1, 2, 0, new BN(5), 1));

      let l2 = await L2.new();
      await submitAndSimulateBlock(l2, bc, block);
    });
  });
});

async function submitAndSimulateBlock(l2, bc, block) {
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