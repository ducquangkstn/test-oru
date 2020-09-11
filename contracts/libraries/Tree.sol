pragma solidity 0.6.6;

import "@nomiclabs/buidler/console.sol";


/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol
library RollUpLib {
    bytes32 public constant NULL_NODE = 0;

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleAccountRoot(bytes32 leaf, uint32 index, bytes32[32] memory siblings)
        internal
        pure
        returns (bytes32)
    {
        uint32 path = index;
        bytes32 node = leaf;
        for (uint256 i = 0; i < siblings.length; i++) {
            if (node == NULL_NODE && siblings[i] == NULL_NODE) {
                path >>= 1;
                continue;
            }
            if ((path & 1) == 0) {
                // right sibling
                node = keccak256(abi.encodePacked(node, siblings[i]));
            } else {
                // left sibling
                node = keccak256(abi.encodePacked(siblings[i], node));
            }
            path >>= 1;
        }
        return node;
    }

    function merkleTokenRoot(uint16 tokenId, uint48 tokenAmount, bytes32[12] memory tokenProof)
        internal
        pure
        returns (bytes32)
    {
        uint16 path = tokenId;
        bytes32 node = bytes32(uint256(tokenAmount));
        for (uint256 i = 0; i < tokenProof.length; i++) {
            if (node == NULL_NODE && tokenProof[i] == NULL_NODE) {
                path >>= 1;
                continue;
            }
            if ((path & 1) == 0) {
                // right sibling
                node = keccak256(abi.encodePacked(node, tokenProof[i]));
            } else {
                // left sibling
                node = keccak256(abi.encodePacked(tokenProof[i], node));
            }
            path >>= 1;
        }
        return node;
    }
}
