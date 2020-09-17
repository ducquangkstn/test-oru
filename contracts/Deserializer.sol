pragma solidity ^0.6.0;

import "./libraries/Types.sol";
import "./libraries/Bytes.sol";

// SPDX-License-Identifier: MIT
contract Deserializer is Types {
    uint256 internal constant SETTLEMENT1_BYTES_SIZE = 50;
    uint256 internal constant SETTLEMENT2_BYTES_SIZE = 30;
    uint256 internal constant SETTLEMENT3_BYTES_SIZE = 12;
    uint256 internal constant DEPOSIT_BYTES_SIZE = 6;
    uint256 internal constant WITHDRAW_BYTES_SIZE = 36;
    uint256 internal constant EXIT_BYTES_SIZE = 38;

    uint16 private constant TOKENID_MASK = 0x03ff; // 2^10-1
    uint16 private constant FEE_EXP_MASK = 0x003f; // 2^6-1
    uint32 private constant VALID_PERIOD_MASK = 0x0fffffff; // 2^28 -1

    function getMiniBlockHash(bytes memory miniBlock) internal view returns (bytes32) {
        uint256 txsLength = miniBlock.length - 64;
        bytes32 hashResult;
        // This is replacement for keccak(miniBlock[64:]) to save gas
        assembly {
            let success := staticcall(
                gas(),
                0x2, // precompile keccack256
                add(miniBlock, 0x40), // argsOffset
                txsLength, // argsLength
                hashResult,
                0x20
            )
            switch success
                case 0 {
                    invalid()
                }
        }
        bytes32 finalStateHash = Bytes.bytesToBytes32(miniBlock, 0);
        bytes32 commitmennt = Bytes.bytesToBytes32(miniBlock, 32);
        return keccak256(abi.encodePacked(finalStateHash, commitmennt, hashResult));
    }

    function readSettlementOp1(
        bytes memory data,
        uint256 _offset,
        OpType opType
    ) internal pure returns (SettlementOp1 memory parsed) {
        parsed.opType = opType;

        //1st 3bytes layout: 4 bit OpCode, 10 bit tokenID1, 10 bit tokenID2
        uint16 tmp = Bytes.bytesToUInt16(data, _offset);
        parsed.tokenID1 = (tmp >> 2) & TOKENID_MASK;
        tmp = Bytes.bytesToUInt16(data, _offset + 1);
        parsed.tokenID2 = tmp & TOKENID_MASK;

        uint256 offset = _offset + 3;
        (offset, parsed.accountID1) = Bytes.readUInt32(data, offset);
        (offset, parsed.accountID2) = Bytes.readUInt32(data, offset);
        (offset, parsed.amount1) = readAmount(data, offset);
        (offset, parsed.amount2) = readAmount(data, offset);
        (offset, parsed.rate1) = readAmount(data, offset);
        (offset, parsed.rate2) = readAmount(data, offset);
        (offset, parsed.fee1) = readFee(data, offset);
        (offset, parsed.fee2) = readFee(data, offset);
        (offset, parsed.validSince1) = Bytes.readUInt32(data, offset);
        (offset, parsed.validSince2) = Bytes.readUInt32(data, offset);
        (offset, parsed.validPeriod1) = readValidPeriod(data, offset, false);
        (offset, parsed.validPeriod2) = readValidPeriod(data, offset, true);
    }

    // TODO: convert this into SafeMath
    /// @dev 32 bits for mantisa, 8 bits for exp
    function readAmount(bytes memory _data, uint256 _offset)
        internal
        pure
        returns (uint256 newOffset, uint256 amount)
    {
        newOffset = _offset + 5;
        uint32 mantisa = Bytes.bytesToUInt32(_data, _offset);
        uint8 exp = uint8(_data[_offset + 4]);
        amount = uint256(mantisa)**uint256(exp);
    }

    /// @dev 10 bit for mantisa, 6 bit for 
    function readFee(bytes memory _data, uint256 _offset)
        internal
        pure
        returns (uint256 newOffset, uint256 amount)
    {
        newOffset = _offset + 16;
        uint16 tmp = Bytes.bytesToUInt16(_data, _offset);
        uint256 mantisa = tmp >> 6;
        uint256 exp = uint256(tmp & FEE_EXP_MASK);
        amount = mantisa**exp;
    }

    function readValidPeriod(
        bytes memory _data,
        uint256 _offset,
        bool isOdd
    ) internal pure returns (uint256 newOffset, uint32 validPeriod) {
        if (!isOdd) {
            newOffset += 3;
        } else {
            newOffset += 4;
        }

        (newOffset, validPeriod) = Bytes.readUInt32(_data, _offset);
        if (isOdd) {
            validPeriod = validPeriod & VALID_PERIOD_MASK;
        } else {
            validPeriod = validPeriod >> 4;
        }
    }
}
