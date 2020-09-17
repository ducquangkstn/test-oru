// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Tree.sol";
import "./libraries/Bytes.sol";

import "./Deserializer.sol";
import "./interface/ILayer2.sol";
import "./utils/PermissionGroups.sol";

contract L2 is ILayer2, Deserializer, PermissionGroups {
    using UniERC20 for IERC20;

    struct BlockStore {
        bytes32 blockRoot;
        bool isConfirmed;
    }

    struct StateData {
        bytes32 stateRoot;
        bytes32 looRoot;
        uint32 accountMax;
        uint48 looMax;
    }

    // state when the contract init
    StateData internal genesis;
    // Chain of block, each contains blockRoot
    BlockStore[] internal blocks;
    // List of token, and map from address to ID
    IERC20[] public tokens;
    mapping(address => uint256) public tokenAddressToID;

    uint256 public numDeposits;

    // TODO: add admin pubkey to here
    constructor(address _admin) public PermissionGroups(_admin) {
        blocks.push(BlockStore({blockRoot: bytes32(0), isConfirmed: true}));
    }

    function listToken(IERC20 _token) external onlyAdmin {
        listTokenInternal(_token);
    }

    // function depositNewUser(IERC20 token, uint32 amount, uint8 mantisa, bytes32 publicKey) external payable {
    //     token.uniTransferFromSender(payable(address(this)), amount);
    // }
    // function deposit(IERC20 token, uint32 amount, uint8 mantisa, uint32 userID) external payable{}

    function submitBlock(
        uint32 blockNumber,
        bytes[] calldata miniBlocks,
        uint32 timeStamp
    ) external onlyOperator {
        require(miniBlocks.length <= 32, "miniBlocks.length > 32");
        require(blocks.length == uint256(blockNumber), "miss-match blockNumber");
        bytes32[] memory miniBlockHash = new bytes32[](miniBlocks.length);
        bytes32 finalStateHash = Bytes.bytesToBytes32(miniBlocks[miniBlocks.length - 1], 0);
        for (uint256 i = 0; i < miniBlocks.length; i++) {
            miniBlockHash[i] = handleBlock(miniBlocks[i]);
        }
        bytes32 blockDataHash = Tree.merkleTxsRoot(miniBlockHash);
        bytes32 prevBlockRoot = blocks[blocks.length - 1].blockRoot;
        bytes32 blockRoot = keccak256(
            abi.encodePacked(
                prevBlockRoot,
                blockDataHash,
                timeStamp,
                blockNumber,
                uint8(miniBlocks.length),
                finalStateHash
            )
        );
        blocks.push(BlockStore({blockRoot: blockRoot, isConfirmed: true}));
    }

    function getBlock(uint256 blockNumber) external override view returns (bytes32 blockRoot) {
        return blocks[blockNumber].blockRoot;
    }

    function lastestBlock() external view returns (bytes32 blockRoot, uint256 blockNumber) {
        blockRoot = blocks[blocks.length - 1].blockRoot;
        blockNumber = blocks.length - 1;
    }

    function getGenesisStateData()
        external
        override
        view
        returns (
            bytes32 stateRoot,
            bytes32 looRoot,
            uint32 accountMax,
            uint48 looMax
        )
    {
        return (genesis.stateRoot, genesis.looRoot, genesis.accountMax, genesis.looMax);
    }

    function listTokenInternal(IERC20 _token) internal {
        tokens.push(_token);
        tokenAddressToID[address(_token)] = tokens.length;
    }

    /// @dev marks incoming Depoist and Exit as done, calculates miniBlockHash
    function handleBlock(bytes memory miniBlock) internal returns (bytes32) {
        // this is only for not marked this funciton as view
        admin = admin;
        return getMiniBlockHash(miniBlock);
    }
}
