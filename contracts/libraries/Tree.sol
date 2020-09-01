pragma solidity 0.6.6;



/// @dev https://github.com/zkopru-network/zkopru/blob/1e65597833e47d8b34019c705576debd02765990/packages/contracts/contracts/libraries/Tree.sol
library RollUpLib {
    uint256 public constant NULL_NODE = 0;

    bytes32 public constant NULL_NODE_BYTES32 = bytes32(0);

    function merkleAccountRoot(
        uint32[] memory accountIDs,
        bytes32[] memory accountHashes,
        bytes32[] memory siblings,
        uint256 maxDepth
    ) internal pure returns (bytes32) {
        uint256 siblingIndex = 0;

        uint32[] memory tmpTokenIDs = new uint32[](accountIDs.length);
        for (uint256 i = 0; i < accountIDs.length; i++) {
            tmpTokenIDs[i] = accountIDs[i];
        }
        bytes32[] memory tmpAccountHashes = new bytes32[](accountHashes.length);
        for (uint256 i = 0; i < accountHashes.length; i++) {
            tmpAccountHashes[i] = bytes32(accountHashes[i]);
        }

        uint256 numAccount = accountIDs.length;
        for (uint256 depth = 0; depth < maxDepth; depth++) {
            uint256 i = 0;
            uint256 accountIDIndex = 0;
            while (i < numAccount) {
                if (i != numAccount - 1 && tmpTokenIDs[i] / 2 == tmpTokenIDs[i + 1] / 2) {
                    tmpTokenIDs[accountIDIndex] = tmpTokenIDs[i] / 2;
                    if (
                        tmpAccountHashes[i] == NULL_NODE_BYTES32 &&
                        tmpAccountHashes[i + 1] == NULL_NODE_BYTES32
                    ) {
                        tmpAccountHashes[accountIDIndex] = NULL_NODE_BYTES32;
                    } else {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(tmpAccountHashes[i], tmpAccountHashes[i + 1])
                        );
                    }
                    accountIDIndex++;
                    i += 2;
                    continue;
                }
                if (
                    tmpAccountHashes[i] == NULL_NODE_BYTES32 && siblings[siblingIndex] == NULL_NODE_BYTES32
                ) {
                    tmpAccountHashes[accountIDIndex] = NULL_NODE_BYTES32;
                } else {
                    if ((tmpTokenIDs[i] & 1) == 0) {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(tmpAccountHashes[i], siblings[siblingIndex])
                        );
                    } else {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(siblings[siblingIndex], tmpAccountHashes[i])
                        );
                    }
                }
                tmpTokenIDs[accountIDIndex] = tmpTokenIDs[i] / 2;
                accountIDIndex++;
                siblingIndex++;
                i += 1;
            }
            numAccount = accountIDIndex;
        }
        return tmpAccountHashes[0];
    }

    function merkleTokenRoot(
        uint16[] memory tokenIDs,
        uint48[] memory tokenAmounts,
        bytes32[] memory siblings,
        uint256 maxDepth
    ) internal pure returns (bytes32) {
        uint256 siblingIndex = 0;

        uint16[] memory tmpTokenIDs = new uint16[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            tmpTokenIDs[i] = tokenIDs[i];
        }
        bytes32[] memory tmpAccountHashes = new bytes32[](tokenAmounts.length);
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            tmpAccountHashes[i] = bytes32(uint256(tokenAmounts[i]));
        }
        uint256 numAccount = tokenIDs.length;
        for (uint256 depth = 0; depth < maxDepth; depth++) {
            uint256 i = 0;
            uint256 accountIDIndex = 0;
            while (i < numAccount) {
                if (i != numAccount - 1 && tmpTokenIDs[i] / 2 == tmpTokenIDs[i + 1] / 2) {
                    tmpTokenIDs[accountIDIndex] = tmpTokenIDs[i] / 2;
                    if (
                        tmpAccountHashes[i] == NULL_NODE_BYTES32 &&
                        tmpAccountHashes[i + 1] == NULL_NODE_BYTES32
                    ) {
                        tmpAccountHashes[accountIDIndex] = NULL_NODE_BYTES32;
                    } else {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(tmpAccountHashes[i], tmpAccountHashes[i + 1])
                        );
                    }
                    accountIDIndex++;
                    i += 2;
                    continue;
                }
                if (
                    tmpAccountHashes[i] == NULL_NODE_BYTES32 && siblings[siblingIndex] == NULL_NODE_BYTES32
                ) {
                    tmpAccountHashes[accountIDIndex] = NULL_NODE_BYTES32;
                } else {
                    if ((tmpTokenIDs[i] & 1) == 0) {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(tmpAccountHashes[i], siblings[siblingIndex])
                        );
                    } else {
                        tmpAccountHashes[accountIDIndex] = keccak256(
                            abi.encodePacked(siblings[siblingIndex], tmpAccountHashes[i])
                        );
                    }
                }
                tmpTokenIDs[accountIDIndex] = tmpTokenIDs[i] / 2;
                accountIDIndex++;
                siblingIndex++;
                i += 1;
            }
            numAccount = accountIDIndex;
        }
        return tmpAccountHashes[0];
    }
}
