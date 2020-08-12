pragma solidity 0.6.6;


import "@nomiclabs/buidler/console.sol";


/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol

struct Hasher {
    function (uint, uint) internal pure returns (uint) parentOf;
    uint[] preHashedZero;
}


library RollUpLib {
    /// @dev check if the leaf value and its siblings are match with given merkle root
    function merkleProof(
        Hasher memory self,
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        return merkleRoot(self, leaf, index, siblings) == root;
    }

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleRoot(
        Hasher memory self,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (uint) {
        uint path = index;
        uint node = leaf;
        for(uint i = 0; i < siblings.length; i++) {
            if((path & 1) == 0) {
                // right sibling
                node = self.parentOf(node, siblings[i]);
            } else {
                // left sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
            //console.log('aaa',node);
        }
        return node;
    }
}