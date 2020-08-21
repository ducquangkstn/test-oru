pragma solidity 0.6.6;


/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol
library RollUpLib {
    uint256 public constant NULL_NODE = 0;

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleAccountRoot(uint256 leaf, uint256 index, uint256[32] memory siblings)
        internal
        pure
        returns (uint256)
    {
        uint256 path = index;
        uint256 node = leaf;
        for (uint256 i = 0; i < siblings.length; i++) {
            if (node == NULL_NODE && siblings[i] == NULL_NODE) {
                path >>= 1;
                continue;
            }
            if ((path & 1) == 0) {
                // right sibling
                node = uint256(keccak256(abi.encodePacked(node, siblings[i])));
            } else {
                // left sibling
                node = uint256(keccak256(abi.encodePacked(siblings[i], node)));
            }
            path >>= 1;
        }
        return node;
    }


    function merkleTokenRoot(uint32 tokenId, uint256[13] memory tokenProof)
        internal
        pure
        returns (uint256)
    {
        uint32 path = tokenId;
        uint256 node = tokenProof[0];
        require(tokenProof.length >= 2, "token proof is too short");
        for (uint256 i = 1; i < tokenProof.length; i++) {
            if (node == NULL_NODE && tokenProof[i] == NULL_NODE) {
                path >>= 1;
                continue;
            }
            if ((path & 1) == 0) {
                // right sibling
                node = uint256(keccak256(abi.encodePacked(node, tokenProof[i])));
            } else {
                // left sibling
                node = uint256(keccak256(abi.encodePacked(tokenProof[i], node)));
            }
            path >>= 1;
        }
        return node;
    }
}
