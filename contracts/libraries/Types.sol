// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// @dev all types should have correct order
contract Types {
    enum OpType {
        Noop,
        SettlementOp11, // matching 2 orders
        SettlementOp12,
        SettlementOp13,
        SettlementOp21, // matching 1 order and 1 loo
        SettlementOp22,
        SettlementOp31, // matching 2 loos
        DepositToNew,
        Deposit,
        Withdraw,
        Exit
    }

    struct DepositOp {
        uint48 depositID;
    }

    /// @dev if opType == SettlementOp11, both order accept partial filling
    /// @dev if opType == SettlementOp12, order1 does not accept partial filling while order2 does
    /// @dev if opType == SettlementOp13, both orders do not accept partial filling
    struct SettlementOp1 {
        OpType opType;
        uint16 tokenID1;
        uint16 tokenID2;
        uint32 accountID1;
        uint32 accountID2;
        uint256 amount1;
        uint256 amount2;
        uint256 rate1;
        uint256 rate2;
        uint256 fee1;
        uint256 fee2;
        uint32 validSince1;
        uint32 validSince2;
        uint32 validPeriod1;
        uint32 validPeriod2;
    }

    struct SettlementOp2 {
        bool isAllOrNonceOrder;
        uint32 accountID1;
        uint48 looID;
        uint256 amount1;
        uint256 rate1;
        uint8 fee1;
        uint32 validSince1;
        uint32 validPeriod1;
    }

    struct SettlementOp3 {
        uint48 looID1;
        uint48 looID2;
    }

    struct WithdrawOp {
        uint32 accountID;
        uint16 tokenID;
        uint256 amount;
        uint32 validSince;
        address to;
        uint8 fee;
    }

    struct ExitOp {
        uint48 pendingListID;
        bytes32 accountHash;
    }
}
