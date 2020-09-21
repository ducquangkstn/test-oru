'use strict';

const L2 = artifacts.require('L2');

const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const BN = web3.utils.BN;

const blockchain = require('./blockchain');
const benchmark = require('./benchmark/random');

const fs = require('fs');
const {assert} = require('chai');

let admin;
let operator;

contract('L2', accounts => {
  before('init ', async () => {
    admin = accounts[1];
    operator = accounts[2];
  });
  describe('test', async () => {
    describe('test submitBlock', async () => {
      let testSuits = JSON.parse(fs.readFileSync('./testdata/submitBlock.json'));
      testSuits.forEach(testSuit => {
        it(`submitBlock with length=${testSuit.MiniBlocks.length}`, async () => {
          let l2 = await L2.new(admin);
          l2.addOperator(operator, {from: admin});
          await l2.submitBlock(new BN(1), testSuit.MiniBlocks, new BN(testSuit.TimeStamp), {from: operator});
          let result = await l2.lastestBlock();
          assert.equal(result.blockRoot, testSuit.ExpectedNewBlockRoot, 'unexpected block root');
        });
      });
    });
  });
});
