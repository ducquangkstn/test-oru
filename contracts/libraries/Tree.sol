pragma solidity 0.6.6;

import "@nomiclabs/buidler/console.sol";


/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol
library RollUpLib {
    uint256 public constant NULL_NODE = 0;

    /// @dev get the merkle root from the leaf node and its siblings
    function merkleAccountRoot(uint256 leaf, uint32 index, uint256[32] memory siblings)
        internal
        pure
        returns (uint256)
    {
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
                node = uint256(keccak256(abi.encodePacked(node, tokenProof[i])));
            } else {
                // left sibling
                node = uint256(keccak256(abi.encodePacked(tokenProof[i], node)));
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
                if (i != accountIDs.length - 1 && accountIDs[i] / 2 == accountIDs[i + 1] / 2) {
                    tmpAccountIDs[accountIndex] = accountIDs[i] / 2;
                    tmpAccountHashs[accountIndex] = merkleRoot(
                        accountHashes[i],
                        accountHashes[i + 1]
                    );
                    i += 2;
                    accountIndex++;
                    continue;
                }
                tmpAccountIDs[accountIndex] = accountIDs[i] / 2;
                bool isLeft = (accountIDs[i] & 1) == 0;
                tmpAccountHashs[accountIndex] = merkleRoot(
                    accountHashes[i],
                    siblings[siblingIndex],
                    isLeft
                );
                accountIndex++;
                siblingIndex++;
                i++;
            }
            accountIDs = tmpAccountIDs;
            accountHashes = tmpAccountHashs;
        }
        return accountHashes[0];
    }

    function merkleTokenRoot(
        uint16[] memory tokenIDs,
        uint48[] memory tokenAmounts,
        uint256[] memory siblings,
        uint256 maxDepth
    ) internal pure returns (uint256) {
        uint256 siblingIndex = 0;

        uint256[] memory accountHashes = new uint256[](tokenAmounts.length);
        for(uint256 i=0;i< tokenAmounts.length;i ++){
            accountHashes[i] = uint256(tokenAmounts[i]);
        }

        for (uint256 depth = 0; depth < maxDepth; depth++) {
            uint256 count = 0;
            uint256 i = 0;
            uint16[] memory tmpAccountIDs;
            uint256[] memory tmpAccountHashs;
            while (i < tokenIDs.length) {
                if (i == tokenIDs.length - 1) {
                    count++;
                    break;
                }

                if (tokenIDs[i] / 2 == tokenIDs[i + 1] / 2) {
                    count++;
                    i += 2;
                } else {
                    count++;
                    i++;
                }
            }

            tmpAccountIDs = new uint16[](count);
            tmpAccountHashs = new uint256[](count);
            uint256 accountIndex = 0;

            i = 0;
            while (i < tokenIDs.length) {
                if (i != tokenIDs.length - 1 && tokenIDs[i] / 2 == tokenIDs[i + 1] / 2) {
                    tmpAccountIDs[accountIndex] = tokenIDs[i] / 2;
                    tmpAccountHashs[accountIndex] = merkleRoot(accountHashes[i], accountHashes[i + 1]);
                    i += 2;
                    accountIndex++;
                    continue;
                }
                tmpAccountIDs[accountIndex] = tokenIDs[i] / 2;
                bool isLeft = (tokenIDs[i] & 1) == 0;
                tmpAccountHashs[accountIndex] = merkleRoot(
                    accountHashes[i],
                    siblings[siblingIndex],
                    isLeft
                );
                accountIndex++;
                siblingIndex++;
                i++;
            }
            tokenIDs = tmpAccountIDs;
            accountHashes = tmpAccountHashs;
        }
        return accountHashes[0];
    }

    function merkleRoot(uint256 current, uint256 sibling, bool isLeft)
        internal
        pure
        returns (uint256)
    {
        if (current == 0 && sibling == 0) {
            return 0;
        }

        if (isLeft) {
            return uint256(keccak256(abi.encodePacked(current, sibling)));
        } else {
            return uint256(keccak256(abi.encodePacked(sibling, current)));
        }
    }

    function merkleRoot(uint256 left, uint256 right) internal pure returns (uint256) {
        return merkleRoot(left, right, true);
    }
}
