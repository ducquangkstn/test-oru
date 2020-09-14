'use strict';

const L2 = artifacts.require('L2');

const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const BN = web3.utils.BN;

const blockchain = require('./blockchain');
const benchmark = require('./benchmark/random');

const fs = require('fs');
const {assert} = require('console');

let admin;
let operator;

contract('L2', accounts => {
  before('init ', async () => {
    admin = accounts[1];
    operator = accounts[2];
  });
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

    it('benchmark deposit', async () => {
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
      for (let i = 0; i < 60; i++) {
        depositBlock.addTransaction(
          new blockchain.Deposit(depositData.senderIDs[i], depositData.tokenIDs[i], new BN(depositData.amounts[i]), 1)
        );
      }
      await submitAndSimulateBlock(l2, bc, depositBlock);
    });

    it('benchmark deposit2', async () => {
      let l2 = await L2.new();

      let bc = new blockchain.Blockchain();
      // add block to blockchain
      let block = new blockchain.Block(new BN(0));
      let data = benchmark.readInfo();
      for (let i = 0; i < data.userIDs.length; i++) {
        block.addTransaction(new blockchain.Deposit(data.userIDs[i], data.tokenIDs[i], new BN(data.balances[i]), 0));
      }

      let depositData = benchmark.readInfoDeposit();
      for (let i = 0; i < 30; i++) {
        block.addTransaction(
          new blockchain.Deposit(
            depositData.senderIDs[30] + i + 1,
            depositData.tokenIDs[i],
            new BN(depositData.amounts[i]),
            0
          )
        );
      }

      await addBlock(l2, bc, block);

      let depositBlock = new blockchain.Block(bc.head());
      for (let i = 0; i < 30; i++) {
        depositBlock.addTransaction(
          new blockchain.Deposit(depositData.senderIDs[i], depositData.tokenIDs[i], new BN(depositData.amounts[i]), 1)
        );
      }
      for (let i = 0; i < 30; i++) {
        depositBlock.addTransaction(
          new blockchain.Deposit(
            depositData.senderIDs[30] + i + 1,
            depositData.tokenIDs[i],
            new BN(depositData.amounts[i]),
            1
          )
        );
      }
      await submitAndSimulateBlock(l2, bc, depositBlock);
    });

    it('benchmark transfer', async () => {
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
      let depositData = benchmark.readInfoTransfer();
      for (let i = 0; i < 10; i++) {
        depositBlock.addTransaction(
          new blockchain.Transfer(
            depositData.senderIDs[i],
            depositData.receiverIDs[i],
            depositData.tokenIDs[i],
            new BN(depositData.amounts[i]),
            1
          )
        );
      }
      await submitAndSimulateBlock(l2, bc, depositBlock);
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

    it.only('test submitBlock', async () => {
      let l2 = await L2.new(admin);
      l2.addOperator(operator, {from: admin});

      let testSuit = JSON.parse(fs.readFileSync('./testSample/test.json'));
      await l2.submitBlock(new BN(1), testSuit.miniBlocks, new BN(testSuit.timestamp), {from: operator});
      let result = await l2.lastestBlock();
      assert(result.blockHash == testSuit.expectedBlockRoot, 'unexpected block root');
    });
  });
});

async function addBlock (l2, bc, block) {
  let {blockHash, blockNumber} = await l2.lastestBlock();

  let [bcProof, txProofs] = bc.addBlock(block);
  let newBlockHash = block.hash();
  let blockPubData = '0x' + block.toBuffer().toString('hex');
  await l2.submitBlock(blockHash, '0x' + bc.tree.rootHash().toJSON(), newBlockHash, blockPubData);
}

async function submitAndSimulateBlock (l2, bc, block) {
  let {blockHash, blockNumber} = await l2.lastestBlock();

  let proofs = bc.addBlock(block);
  let newBlockHash = block.hash();
  let blockPubData = '0x' + block.toBuffer().toString('hex');

  await l2.submitBlock(blockHash, '0x' + bc.tree.rootHash().toJSON(), newBlockHash, blockPubData);
  let result = await l2.simulatedBlock(blockNumber.add(new BN(1)), blockPubData, proofs);

  console.log('gas used', result.receipt.gasUsed);
}

function rand (value) {
  return Math.floor(Math.random() * value);
}
