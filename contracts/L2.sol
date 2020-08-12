pragma solidity 0.6.6;

import { RollUpLib } from "./libraries/Tree.sol";
import { Hash } from "./libraries/Hash.sol";
import { Utils } from "./libraries/Utils.sol";
import "@nomiclabs/buidler/console.sol";
pragma experimental ABIEncoderV2;

contract L2 {
    uint256 constant STATE_TREE_DEEP = 161; // 40 * 4 + 1

    uint256[] public roots;

    event SubmitDeposit(uint blkNumber, uint root, bool isValid);
    event SubmitTransfer(uint blkNumber, uint root, bool isValid);

    constructor() public {
        // uint[] memory preHash = Hash.keccak().preHashedZero;
        // console.log(bytes32(preHash[1]));
        roots.push(Hash.keccak().preHashedZero[STATE_TREE_DEEP - 1]);
    }


    /// @dev sender in calldata to watchtower to prove that operator signed a message with blockdata
    function updateRoot(uint256 newRoot) external payable {
        roots.push(newRoot);
    }

    /// @dev  Currently, this only checks if the new block root is match with given new block root
    function submitProofDeposit(uint blkNumber, address sender, uint beforeAmount, uint amount, uint[] calldata siblings) external {
        require(siblings.length == STATE_TREE_DEEP - 1, "unexpected siblings length");
        uint256 preRoot = roots[blkNumber - 1];

        require(RollUpLib.merkleProof(Hash.keccak(),
            preRoot,
            beforeAmount,
            uint256(sender),
            siblings
        ), "prev Root is not match with given proof");

        uint256 newRoot = roots[blkNumber];
        uint256 newBalance = beforeAmount + amount;

        bool isValid = RollUpLib.merkleProof(Hash.keccak(),
            newRoot,
            newBalance,
            uint256(sender),
            siblings
        );

        emit SubmitDeposit(blkNumber, newRoot, isValid);

        if (!isValid) {
            uint revertBlock = roots.length - blkNumber;
            for (uint i = 0; i < revertBlock; i++) {
                roots.pop();
            }
        }
    }

    // full block on call-data
    // simulate more than 1 tx
    // root tree to 2^32 node
    // node to ERC20

    function submitProofTransfer(uint blkNumber, address sender, address receiver, uint beforeAmountSender, uint beforeAmountReceiver,
        uint amount, uint[][2] calldata siblings) external {
            require(siblings[0].length == STATE_TREE_DEEP - 1, "unexpected siblings length");
            uint256 preRoot = roots[blkNumber - 1];
            require(RollUpLib.merkleProof(Hash.keccak(),
                preRoot,
                beforeAmountSender,
                uint256(sender),
                siblings[0]
            ), "prev Root is not match with given proof for sender");

            uint256 newValue = beforeAmountSender - amount;

            preRoot = RollUpLib.merkleRoot(Hash.keccak(),
                newValue,
                uint256(sender),
                siblings[0]
            );

            require(RollUpLib.merkleProof(Hash.keccak(),
                preRoot,
                beforeAmountReceiver,
                uint256(receiver),
                siblings[1]
            ), "prev Root is not match with given proof for receiver");

            newValue = beforeAmountReceiver + amount;
            uint256 newRoot = roots[blkNumber];
            bool isValid = RollUpLib.merkleProof(Hash.keccak(),
                newRoot,
                newValue,
                uint256(receiver),
                siblings[1]
            );
            emit SubmitTransfer(blkNumber, newRoot, isValid);

            if (!isValid) {
                uint revertBlock = roots.length - blkNumber;
                for (uint i = 0; i < revertBlock; i++) {
                    roots.pop();
                }
            }

        }

    function getRoot(uint256 balance, address sender, uint[] calldata siblings) external pure returns (uint256){
        return RollUpLib.merkleRoot(Hash.keccak(),
                balance,
                uint256(sender),
                siblings
            );
    }
}