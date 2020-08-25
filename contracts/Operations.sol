pragma solidity 0.6.6;

import {Bytes} from "./libraries/Bytes.sol";


contract Operations {
    // 4 bytes senderId, 4 bytes nonce, 2 bytes tokenId, 32 bytes amount
    uint256 constant DEPOSIT_MSG_SIZE = 42;
    // 4 bytes senderId, 4 bytes receiverId, 4 bytes nonce, 2 bytes tokenId, 32 bytes amount
    uint256 constant TRANSFER_MSG_SIZE = 46;

    struct Deposit {
        uint32 senderId;
        uint32 nonce;
        uint16 tokenId;
        uint256 amount;
    }

    struct Transfer {
        uint32 senderId;
        uint32 receiverId;
        uint32 nonce;
        uint16 tokenId;
        uint256 amount;
    }

    struct DepositProof {
        uint16 tokenIndex;
        uint16 accountIndex;
    }

    struct TransferProof {
        uint16 senderTokenIndex;
        uint16 senderAccountIndex;
        uint16 receiverTokenIndex;
        uint16 receiverAccountIndex;
    }

    struct BlockchainProof {
        uint32[] accountIDs;
        uint256[] siblings;
        AccountProof[] accounts;
    }

    struct AccountProof {
        uint16[] tokenIDs;
        uint256[] tokenAmounts;
        uint256[] siblings;
        uint32 nonce;
    }

    function getAccountHash(uint256 accountRootHash, uint32 nonce)
        internal
        pure
        returns (uint256)
    {
        if (accountRootHash == 0 && nonce == 0) {
            return 0;
        }
        // TODO: fix this to uint32
        return uint256(keccak256(abi.encodePacked(accountRootHash, uint256(nonce))));
    }

    function readBlockchainProof(bytes memory data)
        internal
        pure
        returns (BlockchainProof memory parsed)
    {
        uint256 offset = 0;
        uint256 accountSize;
        (offset, accountSize) = Bytes.readUInt16(data, offset);
        parsed.accountIDs = new uint32[](accountSize);
        for (uint256 i = 0; i < accountSize; i++) {
            (offset, parsed.accountIDs[i]) = Bytes.readUInt32(data, offset);
        }
        parsed.accounts = new AccountProof[](accountSize);
        for (uint256 i = 0; i < accountSize; i++) {
            (offset, parsed.accounts[i]) = readAccountProof(data, offset);
        }

        uint256 siblingSize;
        (offset, siblingSize) = Bytes.readUInt16(data, offset);
        parsed.siblings = new uint256[](siblingSize);
        for (uint256 i = 0; i < siblingSize; i++) {
            (offset, parsed.siblings[i]) = Bytes.readUInt256(data, offset);
        }
        require(offset == data.length, "not eof");
    }

    function readAccountProof(bytes memory data, uint256 offset)
        internal
        pure
        returns (uint256 new_offset, AccountProof memory parsed)
    {
        uint256 tokenSize;
        (offset, tokenSize) = Bytes.readUInt16(data, offset);
        parsed.tokenIDs = new uint16[](tokenSize);
        for (uint256 i = 0; i < tokenSize; i++) {
            (offset, parsed.tokenIDs[i]) = Bytes.readUInt16(data, offset);
        }

        parsed.tokenAmounts = new uint256[](tokenSize);
        for (uint256 i = 0; i < tokenSize; i++) {
            (offset, parsed.tokenAmounts[i]) = Bytes.readUInt256(data, offset);
        }

        uint256 siblingSize;
        (offset, siblingSize) = Bytes.readUInt16(data, offset);
        parsed.siblings = new uint256[](siblingSize);
        for (uint256 i = 0; i < siblingSize; i++) {
            (offset, parsed.siblings[i]) = Bytes.readUInt256(data, offset);
        }

        (offset, parsed.nonce) = Bytes.readUInt32(data, offset);
        new_offset = offset;
    }

    function readDepositProof(bytes memory data)
        internal
        pure
        returns (DepositProof memory parsed)
    {
        uint256 offset = 0;
        (offset, parsed.tokenIndex) = Bytes.readUInt16(data, offset);
        (offset, parsed.accountIndex) = Bytes.readUInt16(data, offset);
        require(offset == data.length, "not eof");
    }

    function readTransferProof(bytes memory data)
        internal
        pure
        returns (TransferProof memory parsed)
    {
        uint256 offset = 0;
        (offset, parsed.senderTokenIndex) = Bytes.readUInt16(data, offset);
        (offset, parsed.senderAccountIndex) = Bytes.readUInt16(data, offset);
        (offset, parsed.receiverTokenIndex) = Bytes.readUInt16(data, offset);
        (offset, parsed.receiverAccountIndex) = Bytes.readUInt16(data, offset);
        require(offset == data.length, "not eof");
    }

    function readDepositData(bytes memory data, uint256 offset)
        internal
        pure
        returns (Deposit memory parsed)
    {
        (offset, parsed.senderId) = Bytes.readUInt32(data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(data, offset);
        (offset, parsed.amount) = Bytes.readUInt256(data, offset);
    }

    function readTransferData(bytes memory data, uint256 offset)
        internal
        pure
        returns (Transfer memory parsed)
    {
        (offset, parsed.senderId) = Bytes.readUInt32(data, offset);
        (offset, parsed.receiverId) = Bytes.readUInt32(data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(data, offset);
        (offset, parsed.amount) = Bytes.readUInt256(data, offset);
    }
}
