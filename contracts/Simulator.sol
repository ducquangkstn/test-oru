// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./libraries/Tree.sol";
import "./libraries/Bytes.sol";
import "./libraries/Types.sol";

import "./Deserializer.sol";
import "./interface/ILayer2.sol";
import "./utils/PermissionGroups.sol";

contract Simulator is Deserializer, PermissionGroups {
    struct MiniBlockProof {
        bytes32[] sibling;
    }

    struct PrevMiniBlockStateHashProof {
        bytes32 commitment;
        bytes32 stateHash;
        bytes32[] sibling;
    }

    struct PrevBlockStateHashProof {
        uint128 timestamp;
        uint8 k;
        bytes32 blockInfoHash;
    }

    struct StateData {
        bytes32 stateRoot;
        bytes32 looRoot;
        uint32 accountMax;
        uint48 looMax;
    }

    struct FraudProofData {
        uint256 blockNumber;
        uint256 miniBlockNumber;
        StateData stateData;
        bytes32 blockInfoHash;
        bytes32 blockRoot;
        bytes miniBlockData;
        bytes miniBlockProof;
        bytes preStateHashProof;
        uint256 blockFee;
    }

    ILayer2 public immutable l2;

    constructor(address _admin, ILayer2 _l2) public PermissionGroups(_admin) {
        l2 = _l2;
    }

    function accuseUsingBlockFraudProof(
        uint256 blockNumber,
        uint256 miniBlockNumber,
        bytes calldata _miniBlockData,
        bytes calldata _miniBlockProof,
        bytes calldata _preStateHashProof,
        bytes[] calldata /*_executionProof*/
    ) external {
        FraudProofData memory data;
        data.blockNumber = blockNumber;
        data.miniBlockNumber = miniBlockNumber;
        data.miniBlockData = _miniBlockData;
        data.miniBlockProof = _miniBlockProof;
        data.preStateHashProof = _preStateHashProof;

        (, bytes32 currentStateHash) = Bytes.readBytes32(data.miniBlockData, 0);
        bytes32 miniBlockHash = getMiniBlockHash(data.miniBlockData);
        {
            uint256 offset = 0;
            bytes32 blockInfoHash;
            (offset, blockInfoHash) = calculateBlockInfoHash(
                miniBlockHash,
                data.miniBlockNumber,
                data.miniBlockProof,
                offset
            );

            verifyBlockInfoHash(blockInfoHash, data.blockNumber, data.miniBlockProof, offset);
            data.stateData = readAndVerifyPreStateData(
                data.blockNumber,
                data.miniBlockNumber,
                blockInfoHash,
                data.preStateHashProof
            );
        }
        // Verifying preStateData and stateHash is completed, now replay block 1 by 1
        {
            uint256 offset = 64; // skip 2 word for stateHash and commitment
            uint256 proofIndex = 0;
            while (offset < data.miniBlockData.length) {
                // 1st 4 bit for OpcodeType
                OpType opType = OpType(uint8(data.miniBlockData[offset]) >> 4);
                if (
                    opType == OpType.SettlementOp11 ||
                    opType == OpType.SettlementOp12 ||
                    opType == OpType.SettlementOp13
                ) {
                    offset += SETTLEMENT1_BYTES_SIZE;
                } else {
                    revert("slashing: invalid Optype");
                }
                //         // Deposit memory deposit = readDepositData(pubData, offset);
                //         // rootHash = simulateDeposit(deposit, rootHash, proof[proofIndex]);
                //         offset += DEPOSIT_MSG_SIZE;
                //     } else if (opType == OpType.Transfer) {
                //         // Transfer memory transfer = readTransferData(pubData, offset);
                //         // rootHash = simulateTransfer(transfer, rootHash, proof[proofIndex]);
                //         offset += TRANSFER_MSG_SIZE;
                //     } else {
                //         revert("unexpected op type"); // op type is invalid
                //     }
                //     proofIndex++;
                //     require(rootHash != FRAUD_PROOF_HASH, "op is invalid"); // slash and revert
                // }
                // require(rootHash == currentBlockStore.rootHash, "final root hash is miss-match");
            }
        }
    }

    function verifyBlockInfoHash(
        bytes32 blockInfoHash,
        uint256 blockNumber,
        bytes memory pubData,
        uint256 _offset
    ) internal view returns (uint256 offset) {
        bytes32 preBlockRoot = l2.getBlock(blockNumber - 1);
        bytes32 finalStateHash;
        bytes32 currentBlockRoot;
        (offset, finalStateHash) = Bytes.readBytes32(pubData, _offset);
        (offset, currentBlockRoot) = calculateBlockRoot(
            blockNumber,
            blockInfoHash,
            preBlockRoot,
            finalStateHash,
            pubData,
            offset
        );
        require(currentBlockRoot == l2.getBlock(blockNumber), "currentBlockRoot is miss-match");
    }

    /// @dev calculates the block root from proofdata and given params
    function calculateBlockRoot(
        uint256 blockNumber,
        bytes32 blockInfoHash,
        bytes32 preBlockRoot,
        bytes32 preStateHash,
        bytes memory pubData,
        uint256 _offset
    ) internal pure returns (uint256 offset, bytes32 blockRoot) {
        PrevBlockStateHashProof memory proof;
        (offset, proof.k) = Bytes.readUInt8(pubData, _offset);
        (offset, proof.timestamp) = Bytes.readUInt32(pubData, offset);
        blockRoot = keccak256(
            abi.encodePacked(
                preBlockRoot,
                blockInfoHash,
                proof.timestamp,
                blockNumber,
                proof.k,
                preStateHash
            )
        );
    }

    // ok
    function calculateBlockInfoHash(
        bytes32 miniBlockHash,
        uint256 miniBlockNumber,
        bytes memory pubData,
        uint256 _offset
    ) internal pure returns (uint256 offset, bytes32 blockInfoHash) {
        uint8 miniBlocksDeep;
        (offset, miniBlocksDeep) = Bytes.readUInt8(pubData, _offset);
        require(miniBlocksDeep <= 5, "miniBlockDeep too big");
        bytes32[] memory siblings = new bytes32[](uint256(miniBlocksDeep));
        for (uint256 i = 0; i < siblings.length; i++) {
            (offset, siblings[i]) = Bytes.readBytes32(pubData, offset);
        }
        blockInfoHash = RollUpLib.merkleRoot(miniBlockHash, miniBlockNumber, siblings);
    }

    function readAndVerifyPreStateData(
        uint256 blockNumber,
        uint256 miniBlockNumber,
        bytes32 blockInfoHash,
        bytes memory preStateHashProof
    ) internal view returns (StateData memory parsed) {
        require(blockNumber > 0, "zero blockNumber");
        if (blockNumber == 1 && miniBlockNumber == 0) {
            (parsed.stateRoot, parsed.looRoot, parsed.accountMax, parsed.looMax) = l2
                .getGenesisStateData();
            return parsed;
        }

        uint256 offset = 0;
        // normal case verify StateData from stateHash from previos miniBlock
        (parsed, offset) = readStateData(preStateHashProof, offset);
        bytes32 preStateHash = keccak256(
            abi.encodePacked(parsed.stateRoot, parsed.looRoot, parsed.accountMax, parsed.looMax)
        );

        // in this block data, blockNumber >=2 and this is the 1st miniBlock
        if (miniBlockNumber == 0) {
            bytes32 preBlockRoot = l2.getBlock(blockNumber - 1);
            bytes32 beforePreBlockRoot = l2.getBlock(blockNumber - 2);
            PrevBlockStateHashProof memory proof;
            (offset, proof.k) = Bytes.readUInt8(preStateHashProof, offset);
            (offset, proof.timestamp) = Bytes.readUInt32(preStateHashProof, offset);
            (offset, proof.blockInfoHash) = Bytes.readBytes32(preStateHashProof, offset);
            require(
                preBlockRoot ==
                    keccak256(
                        abi.encodePacked(
                            beforePreBlockRoot,
                            proof.blockInfoHash,
                            proof.timestamp,
                            blockNumber - 1,
                            proof.k,
                            preStateHash
                        )
                    ),
                "proof miss-match pre block root"
            );
            return parsed;
        }

        bytes32 commitment;
        bytes32 txRoot;

        (offset, commitment) = Bytes.readBytes32(preStateHashProof, offset);
        (offset, txRoot) = Bytes.readBytes32(preStateHashProof, offset);

        bytes32 preMiniBlockHash = keccak256(abi.encodePacked(preStateHash, commitment, txRoot));
        bytes32 calculatedBlockInfoHash;
        (offset, calculatedBlockInfoHash) = calculateBlockInfoHash(
            preMiniBlockHash,
            miniBlockNumber - 1,
            preStateHashProof,
            offset
        );
        require(blockInfoHash == calculatedBlockInfoHash, "blockInfoHash is miss-match");
    }

    function readStateData(bytes memory pubData, uint256 _offset)
        internal
        pure
        returns (StateData memory parsed, uint256 newOffset)
    {
        newOffset = _offset;
        (newOffset, parsed.stateRoot) = Bytes.readBytes32(pubData, newOffset);
        (newOffset, parsed.looRoot) = Bytes.readBytes32(pubData, newOffset);
        (newOffset, parsed.accountMax) = Bytes.readUInt32(pubData, newOffset);
        (newOffset, parsed.looMax) = Bytes.readUInt48(pubData, newOffset);
    }

    function verifyMiniBlockData() internal pure returns (bool) {}

    function verifyPreStateHashProof() internal pure returns (bool) {}
}
