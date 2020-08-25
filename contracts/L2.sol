pragma solidity 0.6.6;

pragma experimental ABIEncoderV2;

import {RollUpLib} from "./libraries/Tree.sol";
import {Utils} from "./libraries/Utils.sol";
import {Bytes} from "./libraries/Bytes.sol";
import "./Operations.sol";


// import "@nomiclabs/buidler/console.sol";

contract L2 is Operations {
    uint256 constant FRAUD_PROOF_HASH = uint256(-1);

    enum OpType {Noop, Transfer, Deposit}

    struct BlockStore {
        uint256 rootHash;
        uint256 blockHash;
        bool isConfirmed;
    }

    BlockStore[] public blocks;

    constructor() public {
        blocks.push(BlockStore({blockHash: 0, rootHash: 0, isConfirmed: true}));
    }

    function lastestBlock()
        external
        view
        returns (uint256 blockHash, uint256 rootHash, uint256 blockNumber)
    {
        blockHash = blocks[blocks.length - 1].blockHash;
        rootHash = blocks[blocks.length - 1].rootHash;
        blockNumber = blocks.length - 1;
    }

    function submitBlock(
        uint256 _preHash,
        uint256 _rootHash,
        uint256 _blockHash,
        bytes calldata /* pubData */
    ) external {
        require(blocks[blocks.length - 1].blockHash == _preHash, "prehash not match");
        blocks.push(BlockStore({rootHash: _rootHash, blockHash: _blockHash, isConfirmed: false}));
    }

    function simulatedBlock(
        uint256 index,
        bytes calldata _pubData,
        bytes calldata blockChainProofData,
        bytes[] calldata proof
    ) external {
        BlockStore memory prevBlockStore = blocks[index - 1];
        BlockStore memory currentBlockStore = blocks[index];

        bytes memory pubData = _pubData;
        {
            uint256 txsHash = uint256(keccak256(pubData));
            require(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            prevBlockStore.blockHash,
                            currentBlockStore.rootHash,
                            txsHash
                        )
                    )
                ) == currentBlockStore.blockHash,
                "blockHash is missmatch"
            );
        }
        BlockchainProof memory bcProof = readBlockchainProof(blockChainProofData);
        require(getBlockchainRoot(bcProof) == prevBlockStore.rootHash);
        // read calldata
        {
            bool isValid = true;
            uint256 offset = 0;
            uint256 proofIndex = 0;

            while (offset < pubData.length) {
                OpType opType = OpType(uint8(pubData[offset]));
                offset++;
                if (opType == OpType.Deposit) {
                    Deposit memory deposit = readDepositData(pubData, offset);
                    isValid = simulateDeposit(deposit, bcProof, proof[proofIndex]);
                    offset += DEPOSIT_MSG_SIZE;
                } else if (opType == OpType.Transfer) {
                    Transfer memory transfer = readTransferData(pubData, offset);
                    isValid = simulateTransfer(transfer, bcProof, proof[proofIndex]);
                    offset += TRANSFER_MSG_SIZE;
                } else {
                    revert("unexpected op type"); // op type is invalid, slash and revert
                }
                proofIndex++;
                require(isValid, "op is invalid"); // slash and revert
            }
        }
        require(getBlockchainRoot(bcProof) == currentBlockStore.rootHash); //slash and revert
        blocks[index].isConfirmed = true;
    }

    function getBlockchainRoot(BlockchainProof memory bcProof) internal pure returns (uint256) {
        uint256[] memory accountHashes = new uint256[](bcProof.accountIDs.length);
        for (uint256 i = 0; i < bcProof.accountIDs.length; i++) {
            uint256 accountRoot = RollUpLib.merkleTokenRoot(
                bcProof.accounts[i].tokenIDs,
                bcProof.accounts[i].tokenAmounts,
                bcProof.accounts[i].siblings,
                12
            );
            accountHashes[i] = getAccountHash(accountRoot, bcProof.accounts[i].nonce);
        }
        return
            RollUpLib.merkleAccountRoot(bcProof.accountIDs, accountHashes, bcProof.siblings, 32);
    }

    function simulateDeposit(
        Deposit memory deposit,
        BlockchainProof memory bcProof,
        bytes memory proof
    ) internal pure returns (bool isValid) {
        DepositProof memory depositProof = readDepositProof(proof);
        require(
            deposit.senderId == bcProof.accountIDs[depositProof.accountIndex],
            "senderId is miss-match"
        );

        if (deposit.nonce != bcProof.accounts[depositProof.accountIndex].nonce) {
            return false;
        }

        require(
            deposit.tokenId ==
                bcProof.accounts[depositProof.accountIndex].tokenIDs[depositProof.tokenIndex]
        );

        bcProof.accounts[depositProof.accountIndex].nonce++;
        bcProof.accounts[depositProof.accountIndex].tokenAmounts[depositProof
            .tokenIndex] += deposit.amount;
        return true;
    }

    function simulateTransfer(
        Transfer memory transfer,
        BlockchainProof memory bcProof,
        bytes memory proof
    ) internal pure returns (bool isValid) {
        TransferProof memory transferProof = readTransferProof(proof);
        require(
            transfer.senderId == bcProof.accountIDs[transferProof.senderAccountIndex],
            "senderAccountIndex is miss-match"
        );

        if (transfer.nonce != bcProof.accounts[transferProof.senderAccountIndex].nonce) {
            return false;
        }

        require(
            transfer.tokenId ==
                bcProof.accounts[transferProof.senderAccountIndex].tokenIDs[transferProof
                    .senderTokenIndex],
            "tokenSenderIndex is miss-match"
        );

        if (
            transfer.amount >
            bcProof.accounts[transferProof.senderAccountIndex].tokenAmounts[transferProof
                .senderTokenIndex]
        ) {
            return false;
        }

        require(
            transfer.receiverId == bcProof.accountIDs[transferProof.receiverAccountIndex],
            "receiverAccountIndex is miss-match"
        );

        require(
            transfer.tokenId ==
                bcProof.accounts[transferProof.receiverAccountIndex].tokenIDs[transferProof
                    .receiverTokenIndex],
            "receiverTokenIndex is miss-match"
        );

        bcProof.accounts[transferProof.senderAccountIndex].nonce++;
        bcProof.accounts[transferProof.senderAccountIndex].tokenAmounts[transferProof
            .senderTokenIndex] -= transfer.amount;
        bcProof.accounts[transferProof.receiverAccountIndex].tokenAmounts[transferProof
            .receiverTokenIndex] += transfer.amount;
        return true;
    }
}
