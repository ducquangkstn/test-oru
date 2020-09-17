// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Tree {
    bytes32 public constant NULL_NODE = 0;

    function merkleRoot(
        bytes32 leaf,
        uint256 index,
        bytes32[] memory siblings
    ) internal pure returns (bytes32) {
        uint256 path = index;
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

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleAccountRoot(
        uint32 accountID,
        bytes32 leaf,
        bytes32[32] memory siblings
    ) internal pure returns (bytes32) {
        uint32 path = accountID;
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

    function merkleTokenRoot(
        uint16 tokenId,
        uint256 tokenAmount,
        bytes32[10] memory tokenProof
    ) internal pure returns (bytes32) {
        uint16 path = tokenId;
        bytes32 node = bytes32(tokenAmount);
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

    function merkleTxsRoot(bytes32[] memory miniBlockHashes) internal pure returns (bytes32) {
        uint256 size = miniBlockHashes.length;
        bytes32[] memory tmpMiniBlockHashes = miniBlockHashes;
        while (size != 1) {
            for (uint256 i = 0; i * 2 < size; i++) {
                if (i * 2 == size - 1) {
                    tmpMiniBlockHashes[i] = keccak256(
                        abi.encodePacked(tmpMiniBlockHashes[i * 2], NULL_NODE)
                    );
                } else {
                    tmpMiniBlockHashes[i] = keccak256(
                        abi.encodePacked(tmpMiniBlockHashes[i * 2], tmpMiniBlockHashes[i * 2 + 1])
                    );
                }
            }
            size = (size + 1) / 2;
        }
        return tmpMiniBlockHashes[0];
    }
}
