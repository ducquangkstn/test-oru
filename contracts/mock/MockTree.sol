pragma solidity 0.6.6;

import {RollUpLib} from "../libraries/Tree.sol";
import "@nomiclabs/buidler/console.sol";


contract MockTree {
    // function getRoot(
    //     uint32[] calldata accountIDs,
    //     bytes32[] calldata accountHashes,
    //     uint256[] calldata siblings,
    //     uint256 maxDepth
    // ) external pure returns (uint256) {
    //     return uint256(RollUpLib.merkleAccountRoot(accountIDs, accountHashes, siblings, maxDepth));
    // }

    // function test(
    //     uint32[] calldata accountIDs,
    //     uint256[] calldata accountHashes,
    //     uint256[] calldata siblings,
    //     uint256 maxDepth
    // ) external view returns (uint256) {
    //     uint32[] memory tmpAccountIDs = accountIDs;
    //     uint256[] memory tmpAccountHashes = accountHashes;

    //     console.log(tmpAccountHashes[0]);

    //     uint256 result = RollUpLib.merkleAccountRoot(
    //         tmpAccountIDs,
    //         tmpAccountHashes,
    //         siblings,
    //         maxDepth
    //     );
    //     console.log(tmpAccountHashes[0]);
    //     return result;
    // }
}
