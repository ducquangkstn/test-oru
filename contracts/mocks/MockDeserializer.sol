pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../Deserializer.sol";

// SPDX-License-Identifier: UNLICENSED
contract MockDeserializer is Deserializer {
    function testGetMiniBlockHash(bytes calldata _miniBlock) external view returns (bytes32) {
        return getMiniBlockHash(_miniBlock);
    }

    function testReadSettlementOp1(bytes calldata _data)
        external
        pure
        returns (SettlementOp1 memory parsed)
    {
        OpType opType = OpType(uint8(_data[0]) >> 4);
        parsed = readSettlementOp1(_data, 0, opType);
    }
}
