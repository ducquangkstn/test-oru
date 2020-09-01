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
        bytes32[] siblings;
        AccountProof[] accounts;
    }

    struct AccountProof {
        uint16[] tokenIDs;
        uint48[] tokenAmounts;
        bytes32[] siblings;
        uint32 nonce;
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
        parsed.siblings = new bytes32[](siblingSize);
        for (uint256 i = 0; i < siblingSize; i++) {
            (offset, parsed.siblings[i]) = Bytes.readBytes32(data, offset);
        }
        require(offset == data.length, "not eof");
    }

    // function readBlockchainProofFromCalldata(uint paramIndex) internal pure returns (BlockchainProof memory parsed){
    //     // 4 means the length of the function signature in the calldata
    //     uint cp = 4 + abi.decode(msg.data[4 + 32*paramIndex:4 + 32*(paramIndex+1)], (uint));
    //     uint dataLen;
    //     uint numAccount;
    //     // get calldata length
    //     assembly {
    //         let p := mload(0x40)
    //         calldatacopy(p, cp, 0x20)
    //         dataLen := mload(p)
    //         cp := add(cp, 0x20)
    //     }
 
    //     assembly {            
    //         // load free memory
    //         let p := mload(0x40)
    //         calldatacopy(add(p, 0x1e), cp, 0x02)
    //         numAccount := mload(p)
    //         cp := add(cp, 0x02)
    //     }

    //     uint32[] memory accountIDs = new uint32[](numAccount);
    //     for(uint256 i= 0;i< numAccount;i ++) {
    //         assembly {
    //             calldatacopy(add(add(accountIDs, 0x3c), mul(0x20, i)), cp, 0x04)
    //             cp := add(cp, 0x04)
    //         }
    //     }
    //     parsed.accounts = new AccountProof[](numAccount);
    //     for(uint256 i= 0;i< numAccount;i ++) {
    //         (cp, parsed.accounts[i]) = readAccountProofFromCalldata(cp);
    //     }

    //     uint256 numSiblings;
    //     assembly {            
    //         // load free memory
    //         let p := mload(0x40)
    //         calldatacopy(add(p, 0x1e), cp, 0x02)
    //         numSiblings := mload(p)
    //         cp := add(cp, 0x02)
    //     }
    //     bytes32[] memory siblings = new bytes32[](numSiblings);
    //      for(uint256 i= 0;i< numSiblings;i ++) {
    //         assembly {
    //             calldatacopy(add(add(siblings, 0x20), mul(0x20, i)), cp, 0x20)
    //             cp := add(cp, 0x20)
    //         }
    //     }
    //     parsed.siblings = siblings;
    // }


    
    // function readAccountProofFromCalldata(uint _calldataPos) internal pure returns(uint cp, AccountProof memory parsed) {
    //     uint256 numToken;
    //     cp = _calldataPos;
    //     assembly {            
    //         // load free memory
    //         let p := mload(0x40)
    //         calldatacopy(add(p, 0x1e), cp, 0x02)
    //         numToken := mload(p)
    //         cp := add(cp, 0x02)
    //     }

    //     uint16[] memory tokenIDs = new uint16[](numToken);
    //     for(uint256 i= 0;i< numToken;i ++) {
    //         assembly {
    //             calldatacopy(add(add(tokenIDs, 0x3e), mul(0x20, i)), cp, 0x02)
    //             cp := add(cp, 0x02)
    //         }
    //     }
    //     uint48[] memory tokenAmounts = new uint48[](numToken);
    //     for(uint256 i= 0;i< numToken;i ++) {
    //         assembly {
    //             calldatacopy(add(add(tokenAmounts, 0x3a), mul(0x20, i)), cp, 0x06)
    //             cp := add(cp, 0x06)
    //         }
    //     }

    //     uint256 numSiblings;
    //     assembly {            
    //         // load free memory
    //         let p := mload(0x40)
    //         calldatacopy(add(p, 0x1e), cp, 0x02)
    //         numSiblings := mload(p)
    //         cp := add(cp, 0x02)
    //     }
    //     bytes32[] memory siblings = new bytes32[](numSiblings);
    //      for(uint256 i= 0;i< numSiblings;i ++) {
    //         assembly {
    //             calldatacopy(add(add(siblings, 0x20), mul(0x20, i)), cp, 0x20)
    //             cp := add(cp, 0x20)
    //         }
    //     }

    //     uint32 nonce;
    //     assembly {            
    //         // load free memory
    //         let p := mload(0x40)
    //         calldatacopy(add(p, 0x1c), cp, 0x04)
    //         nonce := mload(p)
    //         cp := add(cp, 0x04)
    //     }
    //     parsed.tokenIDs = tokenIDs;
    //     parsed.tokenAmounts = tokenAmounts;
    //     parsed.siblings = siblings;
    //     parsed.nonce = nonce;
    // }


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

        parsed.tokenAmounts = new uint48[](tokenSize);
        for (uint256 i = 0; i < tokenSize; i++) {
            (offset, parsed.tokenAmounts[i]) = Bytes.readUInt48(data, offset);
        }

        uint256 siblingSize;
        (offset, siblingSize) = Bytes.readUInt16(data, offset);
        parsed.siblings = new bytes32[](siblingSize);
        for (uint256 i = 0; i < siblingSize; i++) {
            (offset, parsed.siblings[i]) = Bytes.readBytes32(data, offset);
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
