// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./libraries/Tree.sol";
import "./libraries/Bytes.sol";
import "./libraries/Types.sol";

import "./ExecutionProof.sol";
import "./Deserializer.sol";
import "./interface/ILayer2.sol";
import "./utils/PermissionGroups.sol";

contract Simulator is Deserializer, PermissionGroups, ExecutionProof {
    uint16 private constant FEE_TOKEN_INDEX = 0;
    uint32 private constant ADMIN_ACCOUNT_INDEX = 0;

    enum FraudProofType {Valid, SettlementRateMissMatch, InvalidPartialFilled, InsufficientAmount}
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
        bytes[] calldata _executionProof
    ) external returns (FraudProofType fpType) {
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
                    SettlementOp1 memory settlement1 = readSettlementOp1(
                        data.miniBlockData,
                        offset,
                        opType
                    );
                    fpType = simulateSettlement1(settlement1, data, _executionProof[proofIndex]);
                    if (fpType != FraudProofType.Valid) {
                        return fpType;
                    }
                    offset += SETTLEMENT1_BYTES_SIZE;
                } else {
                    revert("slashing: invalid Optype");
                }
                proofIndex++;
            }
            simulatedAddFee(data, _executionProof[proofIndex]);
            require(
                currentStateHash ==
                    keccak256(
                        abi.encodePacked(
                            data.stateData.stateRoot,
                            data.stateData.looRoot,
                            data.stateData.accountMax,
                            data.stateData.looMax
                        )
                    ),
                "unexpected end stateHash"
            );
        }
    }

    function simulatedAddFee(FraudProofData memory data, bytes memory proofData) internal pure {
        AddFeeProof memory proof = readAddFeeProof(proofData);
        // verify previous stateRoot
        bytes32 accountRoot = Tree.merkleTokenRoot(
            FEE_TOKEN_INDEX,
            proof.tokenProof.amount,
            proof.tokenProof.tokenSiblings
        );
        require(
            data.stateData.stateRoot ==
                Tree.merkleAccountRoot(
                    ADMIN_ACCOUNT_INDEX,
                    keccak256(abi.encodePacked(accountRoot, proof.pubAccountHash)),
                    proof.accountSiblings
                ),
            "miss-match stateRoot"
        );
        // calculate newStateRoot
        accountRoot = Tree.merkleTokenRoot(
            FEE_TOKEN_INDEX,
            proof.tokenProof.amount + data.blockFee,
            proof.tokenProof.tokenSiblings
        );
        data.stateData.stateRoot = Tree.merkleAccountRoot(
            ADMIN_ACCOUNT_INDEX,
            keccak256(abi.encodePacked(accountRoot, proof.pubAccountHash)),
            proof.accountSiblings
        );
    }

    function simulateSettlement1(
        SettlementOp1 memory s,
        FraudProofData memory data,
        bytes memory proofData
    ) internal pure returns (FraudProofType) {
        if (s.rate1 * s.rate2 > 1e36) {
            return FraudProofType.SettlementRateMissMatch;
        }

        (
            uint256 amount1,
            uint256 amount2,
            uint256 fee1,
            uint256 fee2,
            bytes32 looHash
        ) = calculateSettlement1Result(s);

        if (amount1< s.amount1 && s.opType != OpType.SettlementOp11) {
            return FraudProofType.InvalidPartialFilled;
        }

        if (amount2 < s.amount2 && s.opType == OpType.SettlementOp13) {
            return FraudProofType.InvalidPartialFilled;
        }
        // proof acc1 has x token1
        (uint256 offset, SettlementProof memory proof) = readSettlementProof(proofData);
        bytes32 accountRoot = Tree.merkleTokenRoot(
            s.tokenID1,
            proof.accountProof1.tokenProof1.amount,
            proof.accountProof1.tokenProof1.tokenSiblings
        );
        require(
            data.stateData.stateRoot ==
                Tree.merkleAccountRoot(
                    s.accountID1,
                    keccak256(abi.encodePacked(accountRoot, proof.accountProof1.pubAccountHash)),
                    proof.accountProof1.accountSiblings
                ),
            "miss-match stateRoot"
        );
        // account.token1.amount1 -= amount1
        if (proof.accountProof1.tokenProof1.amount < amount1) {
            return FraudProofType.InsufficientAmount;
        }
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID1,
            proof.accountProof1.tokenProof1.amount - amount1,
            proof.accountProof1.tokenProof1.tokenSiblings
        );
        // account1.token2.amount += amount2
        require(
            accountRoot ==
                Tree.merkleTokenRoot(
                    s.tokenID2,
                    proof.accountProof1.tokenProof2.amount,
                    proof.accountProof1.tokenProof2.tokenSiblings
                ),
            "accountRoot is miss-match"
        );
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID2,
            proof.accountProof1.tokenProof2.amount + amount2,
            proof.accountProof1.tokenProof2.tokenSiblings
        );
        // account1.feeToken -= fee1;
        require(
            accountRoot ==
                Tree.merkleTokenRoot(
                    FEE_TOKEN_INDEX,
                    proof.accountProof1.tokenProof0.amount,
                    proof.accountProof1.tokenProof0.tokenSiblings
                ),
            "accountRoot is miss-match"
        );
        if(proof.accountProof1.tokenProof0.amount < fee1) {
            return FraudProofType.InsufficientAmount;
        }
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID2,
            proof.accountProof1.tokenProof0.amount - fee1,
            proof.accountProof1.tokenProof0.tokenSiblings
        );
        data.stateData.stateRoot = Tree.merkleAccountRoot(
            s.accountID1,
            keccak256(abi.encodePacked(accountRoot, proof.accountProof1.pubAccountHash)),
            proof.accountProof1.accountSiblings
        );

        // verify the proof for account 2 is correct
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID2,
            proof.accountProof2.tokenProof2.amount,
            proof.accountProof2.tokenProof2.tokenSiblings
        );
        require(
            data.stateData.stateRoot ==
                Tree.merkleAccountRoot(
                    s.accountID2,
                    keccak256(abi.encodePacked(accountRoot, proof.accountProof2.pubAccountHash)),
                    proof.accountProof2.accountSiblings
                ),
            "miss-match stateRoot"
        );

        // account2.token2 -= amount2
        if (proof.accountProof2.tokenProof2.amount < amount2) {
            return FraudProofType.InsufficientAmount;
        }
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID2,
            proof.accountProof2.tokenProof2.amount - amount2,
            proof.accountProof2.tokenProof2.tokenSiblings
        );
        // account1.token1 += amount1
        require(
            accountRoot ==
                Tree.merkleTokenRoot(
                    s.tokenID1,
                    proof.accountProof2.tokenProof1.amount,
                    proof.accountProof2.tokenProof1.tokenSiblings
                ),
            "accountRoot21 is miss-match"
        );
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID1,
            proof.accountProof2.tokenProof1.amount + amount1,
            proof.accountProof2.tokenProof1.tokenSiblings
        );
        // account2.feeToken -= fee2;
        require(
            accountRoot ==
                Tree.merkleTokenRoot(
                    FEE_TOKEN_INDEX,
                    proof.accountProof2.tokenProof0.amount,
                    proof.accountProof2.tokenProof0.tokenSiblings
                ),
            "accountRoot is miss-match"
        );
        if(proof.accountProof2.tokenProof0.amount < fee2) {
            return FraudProofType.InsufficientAmount;
        }
        accountRoot = Tree.merkleTokenRoot(
            s.tokenID2,
            proof.accountProof2.tokenProof0.amount - fee2,
            proof.accountProof2.tokenProof0.tokenSiblings
        );

        data.stateData.stateRoot = Tree.merkleAccountRoot(
            s.accountID2,
            keccak256(abi.encodePacked(accountRoot, proof.accountProof2.pubAccountHash)),
            proof.accountProof2.accountSiblings
        );

        if (looHash != bytes32(0)) {
            // verifyAndCalculateLooRoot
            data.stateData.looMax += 1;
            bytes32[] memory looSiblings = new bytes32[](44);
            for (uint256 i = 0; i < 44; i++) {
                (offset, looSiblings[i]) = Bytes.readBytes32(proofData, offset);
            }
            require(
                data.stateData.looRoot ==
                    Tree.merkleRoot(bytes32(0), uint256(data.stateData.looMax), looSiblings),
                "looRoot is miss-match"
            );
            data.stateData.looRoot = Tree.merkleRoot(
                looHash,
                uint256(data.stateData.looMax),
                looSiblings
            );
        }
        require(offset == proofData.length, "not eof");
        data.blockFee += fee1 + fee2;
    }

    function calculateSettlement1Result(SettlementOp1 memory s)
        internal
        pure
        returns (
            uint256 amount1,
            uint256 amount2,
            uint256 fee1,
            uint256 fee2,
            bytes32 looHash
        )
    {
        if (s.validSince1 <= s.validSince2) {
            // fill with rate = s.rate1
            amount2 = calAmountOut(s.amount1, s.rate1);
            if (amount2 > s.amount2) {
                amount2 = s.amount2;
                amount1 = calAmountIn(s.amount2, s.rate1);
            } else {
                amount1 = s.amount1;
            }
        } else {
            // fill with rate = s.rate2
            amount1 = calAmountOut(s.amount2, s.rate2);
            if (amount1 > s.amount1) {
                amount1 = s.amount1;
                amount2 = calAmountIn(s.amount1, s.rate2);
            } else {
                amount2 = s.amount2;
            }
        }

        fee1 = s.fee1;
        fee2 = s.fee2;
        if (amount1 < s.amount1) { // partial fill on order 1
            fee1 = (s.fee1 * amount1) / s.amount1;
            looHash = keccak256(
                abi.encodePacked(
                    s.accountID1,
                    s.tokenID1,
                    s.tokenID2,
                    s.amount1,
                    s.fee1 - fee1,
                    s.rate1,
                    s.validSince1,
                    s.validPeriod1
                )
            );
        } else if (amount2 < s.amount2) { // partial fill on order 2
            fee2 = (s.fee2 * amount2) / s.amount2;
            looHash = keccak256(
                abi.encodePacked(
                    s.accountID2,
                    s.tokenID2,
                    s.tokenID1,
                    s.amount2 - amount2,
                    fee2,
                    s.rate2,
                    s.validSince2,
                    s.validPeriod2
                )
            );
        } else {
            looHash = bytes32(0);
        }
    }

    function calAmountOut(uint256 amountIn, uint256 rate) internal pure returns (uint256) {
        return (amountIn * rate) / 1e18;
    }

    function calAmountIn(uint256 amountOut, uint256 rate) internal pure returns (uint256) {
        return (amountOut * 1e18 + rate - 1) / rate;
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
        blockInfoHash = Tree.merkleRoot(miniBlockHash, miniBlockNumber, siblings);
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
