pragma solidity 0.6.6;

import {Bytes} from "./libraries/Bytes.sol";


contract Operations {
    // 4 bytes senderId, 4 bytes nonce, 2 bytes tokenId, 6 bytes amount
    uint256 constant DEPOSIT_MSG_SIZE = 16;
    // 4 bytes senderId, 4 bytes receiverId, 4 bytes nonce, 2 bytes tokenId, 6 bytes amount
    uint256 constant TRANSFER_MSG_SIZE = 20;

    struct Deposit {
        uint32 senderId;
        uint32 nonce;
        uint16 tokenId;
        uint48 amount;
    }

    struct Transfer {
        uint32 senderId;
        uint32 receiverId;
        uint32 nonce;
        uint16 tokenId;
        uint48 amount;
    }

    struct DepositProof {
        uint48 tokenAmount;
        bytes32[12] tokenProof;
        bytes32[32] accountSiblings;
        uint32 nonce;
    }

    struct TransferProof {
        uint48 senderTokenAmount;
        bytes32[12] senderTokenProof;
        bytes32[32] senderAccountSiblings;
        uint32 senderNonce;
        uint48 receiverTokenAmount;
        bytes32[12] receiverTokenProof;
        bytes32[32] receiverAccountSiblings;
        uint32 receiverNonce;
    }

    function getAccountHash(bytes32 accountRootHash, uint32 nonce)
        internal
        pure
        returns (bytes32)
    {
        if (accountRootHash == 0 && nonce == 0) {
            return 0;
        }
        // TODO: fix this to uint32
        return keccak256(abi.encodePacked(accountRootHash, uint256(nonce)));
    }

    function readDepositProof(bytes memory data)
        internal
        pure
        returns (DepositProof memory depositProof)
    {
        uint256 offset = 0;
        for (uint256 i = 0; i < 32; i++) {
            (offset, depositProof.accountSiblings[i]) = Bytes.readBytes32(data, offset);
        }

        (offset, depositProof.tokenAmount) = Bytes.readUInt48(data, offset);
        for (uint256 i = 0; i < 12; i++) {
            (offset, depositProof.tokenProof[i]) = Bytes.readBytes32(data, offset);
        }
        (offset, depositProof.nonce) = Bytes.readUInt32(data, offset);
        require(offset == data.length, "not eof");
    }

    function readTransferProof(bytes memory data)
        internal
        pure
        returns (TransferProof memory transferProof)
    {
        uint256 offset = 0;
        for (uint256 i = 0; i < 32; i++) {
            (offset, transferProof.senderAccountSiblings[i]) = Bytes.readBytes32(data, offset);
        }

        (offset, transferProof.senderTokenAmount) = Bytes.readUInt48(data, offset);
        for (uint256 i = 0; i < 12; i++) {
            (offset, transferProof.senderTokenProof[i]) = Bytes.readBytes32(data, offset);
        }
        (offset, transferProof.senderNonce) = Bytes.readUInt32(data, offset);
        for (uint256 i = 0; i < 32; i++) {
            (offset, transferProof.receiverAccountSiblings[i]) = Bytes.readBytes32(data, offset);
        }

        (offset, transferProof.receiverTokenAmount) = Bytes.readUInt48(data, offset);
        for (uint256 i = 0; i < 12; i++) {
            (offset, transferProof.receiverTokenProof[i]) = Bytes.readBytes32(data, offset);
        }
        (offset, transferProof.receiverNonce) = Bytes.readUInt32(data, offset);
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
        (offset, parsed.amount) = Bytes.readUInt48(data, offset);
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
        (offset, parsed.amount) = Bytes.readUInt48(data, offset);
    }
}
