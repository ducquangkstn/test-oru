const MockTree = artifacts.require('MockTree');

const BN = web3.utils.BN;

const {hexToBN} = require('./helpers');

contract('RollUpLib', accounts => {
  it('test batch proof multiple accounts', async () => {
    let tree = await MockTree.new();
    let accountIDs = [new BN(0), new BN(3), new BN(7)];
    let accountHashes = [new BN(10), new BN(13), new BN(17)];
    let siblingHashes = [new BN(11), new BN(12), new BN(16), new BN(45)];
    console.log(await tree.getRoot(accountIDs, accountHashes, siblingHashes, new BN(3)));

    let root01 = keccakParentOf(new BN(10), new BN(11));
    let root23 = keccakParentOf(new BN(12), new BN(13));
    let root03 = keccakParentOf(root01, root23);
    let root47 = keccakParentOf(new BN(45), keccakParentOf(new BN(16), new BN(17)));
    console.log(keccakParentOf(root03, root47));

    let out = await tree.test(accountIDs, accountHashes, siblingHashes, new BN(3));
    console.log(out);
  });
});

function keccakParentOf (left, right) {
  return hexToBN(web3.utils.soliditySha3(web3.eth.abi.encodeParameters(['uint256', 'uint256'], [left, right])));
}
