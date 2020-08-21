const Test = artifacts.require('Test');
const L2 = artifacts.require('L2');

const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const BN = web3.utils.BN;

const {MerkleTree} = require('./treeHelpers');
const blockchain = require('./blockchain');
const Helpers = require('./helpers');

contract('L2', accounts => {
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

async function submitAndSimulateBlock (l2, bc, block) {
  let {blockHash, blockNumber} = await l2.lastestBlock();

  let proofs = bc.addBlock(block);
  let newBlockHash = block.hash();
  let blockPubData = '0x' + block.toBuffer().toString('hex');

  await l2.submitBlock(blockHash, bc.tree.rootHash(), newBlockHash, blockPubData);
  await l2.simulatedBlock(blockNumber.add(new BN(1)), blockPubData, proofs);
}
