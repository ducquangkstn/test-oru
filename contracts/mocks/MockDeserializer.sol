pragma solidity ^0.6.0;

import "../Deserializer.sol";

// SPDX-License-Identifier: UNLICENSED
contract MockDeserializer is Deserializer {
    function testGetMiniBlockHash(bytes calldata miniBlock) external view returns (bytes32) {
        return getMiniBlockHash(miniBlock);
    }
}
