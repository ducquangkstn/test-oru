pragma solidity 0.6.6;

pragma experimental ABIEncoderV2;

import {RollUpLib} from "./libraries/Tree.sol";
import {Utils} from "./libraries/Utils.sol";
import {Bytes} from "./libraries/Bytes.sol";
import "./Operations.sol";

import "@nomiclabs/buidler/console.sol";

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
        returns (
            uint256 blockHash,
            uint256 rootHash,
            uint256 blockNumber
        )
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
        require(
            blocks[blocks.length - 1].blockHash == _preHash,
            "prehash not match"
        );
        blocks.push(
            BlockStore({
                rootHash: _rootHash,
                blockHash: _blockHash,
                isConfirmed: false
            })
        );
    }

    function simulatedBlock(
        uint256 index,
        bytes calldata _pubData,
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
        {
            uint256 rootHash = prevBlockStore.rootHash;

            uint256 offset = 0;
            uint256 proofIndex = 0;

            while (offset < pubData.length) {
                OpType opType = OpType(uint8(pubData[offset]));
                offset++;
                if (opType == OpType.Deposit) {
                    Deposit memory deposit = readDepositData(pubData, offset);

                    rootHash = simulateDeposit(
                        deposit,
                        rootHash,
                        proof[proofIndex]
                    );
                    offset += DEPOSIT_MSG_SIZE;
                } else if (opType == OpType.Transfer) {
                    Transfer memory transfer = readTransferData(
                        pubData,
                        offset
                    );
                    rootHash = simulateTransfer(
                        transfer,
                        rootHash,
                        proof[proofIndex]
                    );
                    offset += TRANSFER_MSG_SIZE;
                } else {
                    revert("unexpected op type"); // op type is invalid
                }
                proofIndex++;
                require(rootHash != FRAUD_PROOF_HASH, "op is invalid"); // slash and revert
            }
            require(
                rootHash == currentBlockStore.rootHash,
                "final root hash is miss-match"
            ); //slash and revert
        }

        blocks[index].isConfirmed = true;
    }

    function simulateDeposit(
        Deposit memory deposit,
        uint256 preRootHash,
        bytes memory proof
    ) internal pure returns (uint256 newRootHash) {
        DepositProof memory depositProof = readDepositProof(proof);
        uint256 accountHash;
        uint256 accountRootHash;
        //verify the prevRoot is match with root hash of prev block
        accountRootHash = RollUpLib.merkleTokenRoot(
            deposit.tokenId,
            depositProof.tokenProof
        );
        accountHash = getAccountHash(accountRootHash, depositProof.nonce);
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                deposit.senderId,
                depositProof.accountSiblings
            ) == preRootHash,
            "L2::simulateDeposit: pre rootHash is miss-match"
        );

        depositProof.tokenProof[0] += deposit.amount;
        accountRootHash = RollUpLib.merkleTokenRoot(
            deposit.tokenId,
            depositProof.tokenProof
        );

        if (deposit.nonce != depositProof.nonce) return FRAUD_PROOF_HASH;

        accountHash = getAccountHash(accountRootHash, depositProof.nonce + 1);
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            deposit.senderId,
            depositProof.accountSiblings
        );
    }

    function simulateTransfer(
        Transfer memory transfer,
        uint256 preRootHash,
        bytes memory proof
    ) internal pure returns (uint256 newRootHash) {
        TransferProof memory transferProof = readTransferProof(proof);
        uint256 accountHash;
        uint256 accountRootHash;

        //verify the prevRoot is match with root hash of prev block
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.senderTokenProof
        );
        accountHash = getAccountHash(
            accountRootHash,
            transferProof.senderNonce
        );
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                transfer.senderId,
                transferProof.senderAccountSiblings
            ) == preRootHash,
            "L2::simulateTransfer pre rootHash is miss-match"
        );

        if (transfer.nonce != transferProof.senderNonce)
            return FRAUD_PROOF_HASH;
        if (transferProof.senderTokenProof[0] < transfer.amount)
            return FRAUD_PROOF_HASH;
        transferProof.senderTokenProof[0] -= transfer.amount;
        // calculate new root hash
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.senderTokenProof
        );
        accountHash = getAccountHash(
            accountRootHash,
            transferProof.senderNonce + 1
        );
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            transfer.senderId,
            transferProof.senderAccountSiblings
        );
        //verify receiver proof is correct
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.receiverTokenProof
        );
        accountHash = getAccountHash(
            accountRootHash,
            transferProof.receiverNonce
        );
        require(
            RollUpLib.merkleAccountRoot(
                accountHash,
                transfer.receiverId,
                transferProof.receiverAccountSiblings
            ) == newRootHash,
            "L2::simulateTransfer pre rootHash is miss-match"
        );
        transferProof.receiverTokenProof[0] += transfer.amount;
        // calculate the new root hash
        accountRootHash = RollUpLib.merkleTokenRoot(
            transfer.tokenId,
            transferProof.receiverTokenProof
        );
        accountHash = getAccountHash(
            accountRootHash,
            transferProof.receiverNonce
        );
        newRootHash = RollUpLib.merkleAccountRoot(
            accountHash,
            transfer.receiverId,
            transferProof.receiverAccountSiblings
        );
    }
}
