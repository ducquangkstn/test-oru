const MockTree = artifacts.require('MockTree');

const fs = require('fs');

const {assert} = require('chai');

let tree;

contract('Tree', accounts => {
  before('init tree', async () => {
    tree = await MockTree.new();
  });
  describe('test get block info hash', async () => {
    let testSuits = JSON.parse(fs.readFileSync('./testdata/merkleTxsRoot.json'));
    testSuits.forEach(testSuit => {
      it(`test with miniBlockHashes lenghth=${testSuit.MiniBlockHashes.length}`, async () => {
        assert.equal(await tree.merkleTxsRoot(testSuit.MiniBlockHashes), testSuit.ExpectedBlockInfoHash);
      });
    });
  });
});
