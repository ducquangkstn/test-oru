pragma solidity 0.6.6;

struct DepositOp {
    uint48 depositID;
}

struct SettlementOp1 {
    uint settlementType;

    uint16 tokenID1;
    uint16 tokenID2;

    uint32 accountID1;
    uint32 accountID2;
    uint amount1;
    uint amount2;
    uint rate1;
    uint rate2;
    uint8 fee1;
    uint8 fee2;
    uint32 validSince1;
    uint32 validPeriod1;
    uint32 validSince2;
    uint32 validPeriod2;
}

struct SettlementOp2 {
    bool isAllOrNonceOrder;
    uint32 accountID1;
    uint48 looID;
    uint amount1;
    uint rate1;
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
    uint amount;
    uint32 validSince;
    address to;
    uint8 fee;
}

struct ExitOp {
    uint48 pendingListID;
    bytes32 accountHash;
}
