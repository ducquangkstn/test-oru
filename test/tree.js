const MockTree = artifacts.require('MockTree');

const BN = web3.utils.BN;

const Helpers = require('./treeHelpers');
const {MerkleTree} = require('./treeHelpers');

contract('RollUpLib', (accounts) => {
  it('test batch proof multiple accounts', async () => {
    let tree = await MockTree.new();
    let accountIDs = [new BN(0), new BN(3), new BN(7)];
    let accountHashes = [new BN(10), new BN(13), new BN(17)];
    let siblingHashes = [new BN(11), new BN(12), new BN(16), new BN(45)];
    console.log(await tree.getRoot(accountIDs, accountHashes, siblingHashes, new BN(3)));

    let root01 = Helpers.keccakParentOf(new BN(10), new BN(11));
    let root23 = Helpers.keccakParentOf(new BN(12), new BN(13));
    let root03 = Helpers.keccakParentOf(root01, root23);
    let root47 = Helpers.keccakParentOf(new BN(45), keccakParentOf(new BN(16), new BN(17)));
    console.log(Helpers.keccakParentOf(root03, root47));

    let out = await tree.test(accountIDs, accountHashes, siblingHashes, new BN(3));
    console.log(out);
  });

  it('test get batch proof from merkle tree', async () => {
    let localTree = await new MerkleTree(4);
    localTree.update(new BN(0), new BN(1));
    localTree.update(new BN(1), new BN(2));
    localTree.update(new BN(4), new BN(5));
    localTree.update(new BN(7), new BN(8));
    let localRootHash = localTree.rootHash();

    let keys = [new BN(0), new BN(2), new BN(7)];
    let [values, siblings] = localTree.getProofBatch(keys);

    let tree = await MockTree.new();
    let scRootHash = await tree.test(keys, values, siblings, new BN(3));
    assert(scRootHash.eq(localRootHash), 'rootHash is mismatch');
  });
});
