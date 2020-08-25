pragma solidity 0.6.6;

import "@nomiclabs/buidler/console.sol";

/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol
library RollUpLib {
    uint256 public constant NULL_NODE = 0;

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleAccountRoot(
        uint256 leaf,
        uint32 index,
        uint256[32] memory siblings
    ) internal pure returns (uint256) {
        uint32 path = index;
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

    function merkleTokenRoot(uint16 tokenId, uint256[13] memory tokenProof)
        internal
        pure
        returns (uint256)
    {
        uint16 path = tokenId;
        uint256 node = tokenProof[0];
        require(tokenProof.length >= 2, "token proof is too short");
        for (uint256 i = 1; i < tokenProof.length; i++) {
            if (node == NULL_NODE && tokenProof[i] == NULL_NODE) {
                path >>= 1;
                continue;
            }
            if ((path & 1) == 0) {
                // right sibling
                node = uint256(
                    keccak256(abi.encodePacked(node, tokenProof[i]))
                );
            } else {
                // left sibling
                node = uint256(
                    keccak256(abi.encodePacked(tokenProof[i], node))
                );
            }
            path >>= 1;
        }
        return node;
    }

    function merkleAccountRoot(
        uint32[] memory accountIDs,
        uint256[] memory accountHashes,
        uint256[] memory siblings,
        uint256 maxDepth
    ) internal pure returns (uint256) {
        uint256 siblingIndex = 0;
        for (uint256 depth = 0; depth < maxDepth; depth++) {
            uint256 count = 0;
            uint256 i = 0;
            uint32[] memory tmpAccountIDs;
            uint256[] memory tmpAccountHashs;
            while (i < accountIDs.length) {
                if (i == accountIDs.length - 1) {
                    count++;
                    break;
                }

                if (accountIDs[i] / 2 == accountIDs[i + 1] / 2) {
                    count++;
                    i += 2;
                } else {
                    count++;
                    i++;
                }
            }

            tmpAccountIDs = new uint32[](count);
            tmpAccountHashs = new uint256[](count);
            uint256 accountIndex = 0;

            i = 0;
            while (i < accountIDs.length) {
                if (
                    i != accountIDs.length - 1 &&
                    accountIDs[i] / 2 == accountIDs[i + 1] / 2
                ) {
                    tmpAccountIDs[accountIndex] = accountIDs[i] / 2;
                    tmpAccountHashs[accountIndex] = uint256(
                        keccak256(
                            abi.encodePacked(
                                accountHashes[i],
                                accountHashes[i + 1]
                            )
                        )
                    );
                    i += 2;
                    accountIndex++;
                    continue;
                }
                tmpAccountIDs[accountIndex] = accountIDs[i] / 2;
                if ((accountIDs[i] & 1) == 0) {
                    tmpAccountHashs[accountIndex] = uint256(
                        keccak256(
                            abi.encodePacked(
                                accountHashes[i],
                                siblings[siblingIndex]
                            )
                        )
                    );
                } else {
                    tmpAccountHashs[accountIndex] = uint256(
                        keccak256(
                            abi.encodePacked(
                                siblings[siblingIndex],
                                accountHashes[i]
                            )
                        )
                    );
                }
                accountIndex++;
                siblingIndex++;
                i++;
            }
            accountIDs = tmpAccountIDs;
            accountHashes = tmpAccountHashs;
        }
        return accountHashes[0];
    }
}
