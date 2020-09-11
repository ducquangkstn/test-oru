pragma solidity 0.6.6;

pragma experimental ABIEncoderV2;

import {RollUpLib} from "./libraries/Tree.sol";
import {Utils} from "./libraries/Utils.sol";
import {Bytes} from "./libraries/Bytes.sol";
import "./Operations.sol";


// import "@nomiclabs/buidler/console.sol";

contract L2 is Operations {
    bytes32 constant FRAUD_PROOF_HASH = bytes32(uint256(-1));

    enum OpType {Noop, Transfer, Deposit}

    struct BlockStore {
        bytes32 rootHash;
        bytes32 blockHash;
        bool isConfirmed;
    }

    BlockStore[] public blocks;

    constructor() public {
        blocks.push(BlockStore({blockHash: bytes32(0), rootHash: bytes32(0), isConfirmed: true}));
    }

    function lastestBlock()
        external
        view
        returns (bytes32 blockHash, bytes32 rootHash, uint256 blockNumber)
    {
        blockHash = blocks[blocks.length - 1].blockHash;
        rootHash = blocks[blocks.length - 1].rootHash;
        blockNumber = blocks.length - 1;
    }

    function submitBlock(
        bytes32 _preHash,
        bytes32 _rootHash,
        bytes32 _blockHash,
        bytes calldata /* pubData */
    ) external {
        require(blocks[blocks.length - 1].blockHash == _preHash, "prehash not match");
        blocks.push(BlockStore({rootHash: _rootHash, blockHash: _blockHash, isConfirmed: false}));
    }

    function simulatedBlock(uint256 index, bytes calldata _pubData, bytes[] calldata proof)
        external
    {
        BlockStore memory prevBlockStore = blocks[index - 1];
        BlockStore memory currentBlockStore = blocks[index];

        bytes memory pubData = _pubData;
        {
            bytes32 txsHash = keccak256(pubData);
            require(
                bytes32(
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
        {
            bytes32 rootHash = prevBlockStore.rootHash;

            uint256 offset = 0;
            uint256 proofIndex = 0;

            while (offset < pubData.length) {
                OpType opType = OpType(uint8(pubData[offset]));
                offset++;
                if (opType == OpType.Deposit) {
                    Deposit memory deposit = readDepositData(pubData, offset);
                    rootHash = simulateDeposit(deposit, rootHash, proof[proofIndex]);
                    offset += DEPOSIT_MSG_SIZE;
                } else if (opType == OpType.Transfer) {
                    Transfer memory transfer = readTransferData(pubData, offset);
                    rootHash = simulateTransfer(transfer, rootHash, proof[proofIndex]);
                    offset += TRANSFER_MSG_SIZE;
                } else {
                    revert("unexpected op type"); // op type is invalid
                }
                proofIndex++;
                require(rootHash != FRAUD_PROOF_HASH, "op is invalid"); // slash and revert
            }
            require(rootHash == currentBlockStore.rootHash, "final root hash is miss-match"); //slash and revert
        }
        blocks[index].isConfirmed = true;
    }

    function simulateDeposit(Deposit memory deposit, bytes32 preRootHash, bytes memory proof)
        internal
        pure
        returns (bytes32 newRootHash)
    {
        DepositProof memory depositProof = readDepositProof(proof);
        bytes32 accountHash;
        bytes32 accountRootHash;
        //verify the prevRoot is match with root hash of prev block
        accountRootHash = RollUpLib.merkleTokenRoot(deposit.tokenId, depositProof.tokenAmount, depositProof.tokenProof);
        accountHash = getAccountHash(accountRootHash, depositProof.nonce);
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                deposit.senderId,
                depositProof.accountSiblings
            ) == preRootHash,
            "L2::simulateDeposit: pre rootHash is miss-match"
        );

        depositProof.tokenAmount += deposit.amount;
        accountRootHash = RollUpLib.merkleTokenRoot(deposit.tokenId, depositProof.tokenAmount, depositProof.tokenProof);

        if (deposit.nonce != depositProof.nonce) return FRAUD_PROOF_HASH;

        accountHash = getAccountHash(accountRootHash, depositProof.nonce + 1);
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            deposit.senderId,
            depositProof.accountSiblings
        );
    }

    function simulateTransfer(Transfer memory transfer, bytes32 preRootHash, bytes memory proof)
        internal
        pure
        returns (bytes32 newRootHash)
    {
        TransferProof memory transferProof = readTransferProof(proof);
        bytes32 accountHash;
        bytes32 accountRootHash;

        //verify the prevRoot is match with root hash of prev block
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.senderTokenAmount,
            transferProof.senderTokenProof
        );
        accountHash = getAccountHash(accountRootHash, transferProof.senderNonce);
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                transfer.senderId,
                transferProof.senderAccountSiblings
            ) == preRootHash,
            "L2::simulateTransfer pre rootHash is miss-match"
        );
        //verify if this is an valid transaction
        if (transfer.nonce != transferProof.senderNonce) {
            return FRAUD_PROOF_HASH;
        }
        if (transferProof.senderTokenAmount < transfer.amount) {
            return FRAUD_PROOF_HASH;
        }
        transferProof.senderTokenAmount -= transfer.amount;
        // calculate new root hash
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.senderTokenAmount,
            transferProof.senderTokenProof
        );
        accountHash = getAccountHash(accountRootHash, transferProof.senderNonce + 1);
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            transfer.senderId,
            transferProof.senderAccountSiblings
        );
        //verify receiver proof is correct
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.receiverTokenAmount,
            transferProof.receiverTokenProof
        );
        accountHash = getAccountHash(accountRootHash, transferProof.receiverNonce);
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                transfer.receiverId,
                transferProof.receiverAccountSiblings
            ) == newRootHash,
            "L2::simulateTransfer pre rootHash is miss-match"
        );
        transferProof.receiverTokenAmount += transfer.amount;
        // calculate the new root hash
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.receiverTokenAmount,
            transferProof.receiverTokenProof
        );
        accountHash = getAccountHash(accountRootHash, transferProof.receiverNonce);
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            transfer.receiverId,
            transferProof.receiverAccountSiblings
        );
    }
}
