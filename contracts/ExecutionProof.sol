// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./libraries/Bytes.sol";

contract ExecutionProof {
    struct AddFeeProof {
        TokenProof tokenProof;
        bytes32 pubAccountHash;
        bytes32[32] accountSiblings;
    }

    struct SettlementProof {
        SettlementAccountProof accountProof1;
        SettlementAccountProof accountProof2;
    }
    struct SettlementAccountProof {
        TokenProof tokenProof1;
        TokenProof tokenProof2;
        bytes32 pubAccountHash;
        bytes32[32] accountSiblings;
    }

    struct TokenProof {
        bytes32[10] tokenSiblings;
        uint256 amount;
    }

    function readAddFeeProof(bytes memory data) internal pure returns (AddFeeProof memory parsed) {
        uint256 offset = 0;
        (offset, parsed.tokenProof) = readTokenProof(data, offset);
        (offset, parsed.pubAccountHash) = Bytes.readBytes32(data, offset);
        for (uint256 i = 0; i < 32; i++) {
            (offset, parsed.accountSiblings[i]) = Bytes.readBytes32(data, offset);
        }
        require(offset == data.length, "not eof");
    }

    function readSettlementProof(bytes memory data)
        internal
        pure
        returns (uint256 offset, SettlementProof memory parsed)
    {
        offset = 0;
        (offset, parsed.accountProof1) = readSettlementAccountProof(data, offset);
        (offset, parsed.accountProof2) = readSettlementAccountProof(data, offset);
    }

    function readSettlementAccountProof(bytes memory data, uint256 _offset)
        internal
        pure
        returns (uint256 offset, SettlementAccountProof memory parsed)
    {
        (offset, parsed.tokenProof1) = readTokenProof(data, _offset);
        (offset, parsed.tokenProof2) = readTokenProof(data, offset);
        (offset, parsed.pubAccountHash) = Bytes.readBytes32(data, offset);
        for (uint256 i = 0; i < 32; i++) {
            (offset, parsed.accountSiblings[i]) = Bytes.readBytes32(data, offset);
        }
    }

    function readTokenProof(bytes memory data, uint256 _offset)
        internal
        pure
        returns (uint256 offset, TokenProof memory parsed)
    {
        (offset, parsed.amount) = Bytes.readUInt256(data, _offset);
        for (uint256 i = 0; i < 10; i++) {
            (offset, parsed.tokenSiblings[i]) = Bytes.readBytes32(data, offset);
        }
    }
}
