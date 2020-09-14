pragma solidity ^0.6.0;

import "../libraries/Tree.sol";

contract MockTree {
    function merkleTxsRoot(bytes32[] calldata miniBlockHashes) external pure returns (bytes32) {
        return RollUpLib.merkleTxsRoot(miniBlockHashes);
    }
}
