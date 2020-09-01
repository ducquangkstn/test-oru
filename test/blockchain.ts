const Web3 = require("web3");
const web3 = new Web3();
import BN = require('bn.js');

import { MerkleTree } from './treeHelpers';
import * as Helpers from './helpers';

enum TransactionType {
    NOOP_TX_TYPE = 0,
    TRANSFER = 1,
    DEPOSIT = 2,
}

const TOKEN_TREE_DEEP = 13;
const ACCOUNT_TREE_DEEP = 33;

export class Blockchain {
    tree: MerkleTree;
    accounts: Record<number, Account>
    lastBlockHash: BN

    constructor() {
        this.tree = new MerkleTree(ACCOUNT_TREE_DEEP);
        this.accounts = {};
    }

    //// addBlock handle tx and returns proof
    addBlock(block: Block): String[] {
        let proofs: String[] = [];
        block.txs.forEach(tx => {
            let proof;
            switch (tx.txType()) {
                case TransactionType.DEPOSIT:
                    proof = this.handleDeposit(tx as Deposit);
                    proofs.push('0x' + proof.toString('hex'));
                    break;
                case TransactionType.TRANSFER:
                    proof = this.handleTransfer(tx as Transfer);
                    proofs.push('0x' + proof.toString('hex'));
                    break;
                default:
                    throw Error(`unexpected type: ${tx.txType()}`)
            }
        })

        block.root = this.tree.rootHash();
        this.lastBlockHash = block.hash();
        return proofs;
    }

    handleDeposit(deposit: Deposit): Buffer {
        let account;
        if (this.accounts[deposit.senderId]) {
            account = this.accounts[deposit.senderId];
        } else {
            account = new Account();
            this.accounts[deposit.senderId] = account;
        }

        if (account.nonce != deposit.nonce)
            throw Error(`account nonce is miss-match ${account.nonce} != ${deposit.nonce} ${deposit.senderId}`);

        let [beforeBalance, tokenSiblings] = account.accountTree.getProof(new BN(deposit.tokenId));
        let [_, accountSiblings] = this.tree.getProof(new BN(deposit.senderId));

        account.nonce++;
        account.update(deposit.tokenId, beforeBalance.add(deposit.amount));
        let newHash = account.updateHash();
        this.tree.update(new BN(deposit.senderId), newHash);
        return Buffer.concat([
            Helpers.serializeBNArray(accountSiblings),
            Helpers.serializeAmount(beforeBalance),
            Helpers.serializeBNArray(tokenSiblings),
            Helpers.serializeNonce(deposit.nonce)
        ]);
    }

    handleTransfer(transfer: Transfer): Buffer {
        if (!this.accounts[transfer.senderId]) {
            throw Error("empty sender Id");
        }
        let account = this.accounts[transfer.senderId];
        if (account.nonce != transfer.nonce)
            throw Error("account nonce is miss-match");
        let [beforeBalance, tokenSiblings] = account.accountTree.getProof(new BN(transfer.tokenId));
        if (beforeBalance.lt(transfer.amount))
            throw Error("balance is not enough");
        let [, accountSiblings] = this.tree.getProof(new BN(transfer.senderId));

        account.nonce++;
        account.update(transfer.tokenId, beforeBalance.sub(transfer.amount));
        this.tree.update(new BN(transfer.senderId), account.updateHash());


        if (this.accounts[transfer.receiverId]) {
            account = this.accounts[transfer.receiverId];
        } else {
            account = new Account();
            this.accounts[transfer.receiverId] = account;
        }
        let [receiverBeforeBalance, receiverTokenSiblings] = account.accountTree.getProof(new BN(transfer.tokenId));
        let [, receiverAccountSiblings] = this.tree.getProof(new BN(transfer.receiverId));

        let receiverNonce = account.nonce;
        account.update(transfer.tokenId, receiverBeforeBalance.add(transfer.amount));
        this.tree.update(new BN(transfer.receiverId), account.updateHash());

        return Buffer.concat([
            Helpers.serializeBNArray(accountSiblings),
            Helpers.serializeAmount(beforeBalance),
            Helpers.serializeBNArray(tokenSiblings),
            Helpers.serializeNonce(transfer.nonce),
            Helpers.serializeBNArray(receiverAccountSiblings),
            Helpers.serializeAmount(receiverBeforeBalance),
            Helpers.serializeBNArray(receiverTokenSiblings),
            Helpers.serializeNonce(receiverNonce),
        ]);
    }

    head() {
        return this.lastBlockHash;
    }
}

export class Block {
    preHash: BN;
    root: BN;
    txs: Transaction[] = [];

    constructor(preHash: BN) {
        this.preHash = preHash;
    }

    addTransaction(tx: Transaction) {
        this.txs.push(tx);
    }

    hash(): BN {
        let txHash = Helpers.keccackBuffer(this.toBuffer());
        return Helpers.hexToBN(web3.utils.soliditySha3(
            web3.eth.abi.encodeParameters(
                ['uint256', 'uint256', 'uint256'],
                [this.preHash, this.root, txHash]
            )
        ))
    }

    toBuffer(): Buffer {
        let txBuffers: Buffer[] = []
        this.txs.forEach(tx => {
            txBuffers.push(tx.toBuffer())
        })
        return Buffer.concat([
            Buffer.concat(txBuffers),
        ])
    }
}
interface Transaction {
    senderId: number;
    nonce: number;

    hash: () => BN;
    toBuffer: () => Buffer;
    txType: () => TransactionType;
}

export class Transfer implements Transaction {
    senderId: number;
    receiverId: number;
    tokenId: number;
    amount: BN;
    nonce: number;

    constructor(senderId: number, receiverId: number, tokenId: number, amount: BN, nonce: number) {
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.tokenId = tokenId;
        this.amount = amount;
        this.nonce = nonce;
    }

    hash(): BN {
        return Helpers.hexToBN(web3.utils.soliditySha3(
            web3.eth.abi.encodeParameters(
                ['uint8', 'uint32', 'uint32', 'uint16', 'uint256', 'uint32'],
                [TransactionType.TRANSFER, this.senderId, this.receiverId, this.tokenId, this.amount, this.nonce]
            )
        ));
    }

    toBuffer(): Buffer {
        return Buffer.concat([
            Helpers.serializeTxType(TransactionType.TRANSFER),
            Helpers.serializeAccountId(this.senderId),
            Helpers.serializeAccountId(this.receiverId),
            Helpers.serializeNonce(this.nonce),
            Helpers.serializeTokenId(this.tokenId),
            Helpers.serializeAmount(this.amount)
        ])
    }

    txType(): TransactionType {
        return TransactionType.TRANSFER;
    }
}

export class Deposit implements Transaction {
    senderId: number;
    tokenId: number;
    amount: BN;
    nonce: number;

    constructor(senderId: number, tokenId: number, amount: BN, nonce: number) {
        this.senderId = senderId;
        this.tokenId = tokenId;
        this.amount = amount;
        this.nonce = nonce;
    }

    hash(): BN {
        return Helpers.hexToBN(web3.utils.soliditySha3(
            web3.eth.abi.encodeParameters(
                ['uint8', 'uint32', 'uint16', 'uint256', 'uint32'],
                [TransactionType.DEPOSIT, this.senderId, this.tokenId, this.amount, this.nonce]
            )
        ));
    }

    toBuffer(): Buffer {
        return Buffer.concat([
            Helpers.serializeTxType(TransactionType.DEPOSIT),
            Helpers.serializeAccountId(this.senderId),
            Helpers.serializeNonce(this.nonce),
            Helpers.serializeTokenId(this.tokenId),
            Helpers.serializeAmount(this.amount)
        ])
    }

    txType(): TransactionType {
        return TransactionType.DEPOSIT;
    }


}

class Withdraw {

}

class Account {
    accountTree: MerkleTree
    nonce: number
    hash: BN
    constructor() {
        this.accountTree = new MerkleTree(TOKEN_TREE_DEEP);
        this.nonce = 0;
    }

    update(tokenId: number, amount: BN) {
        this.accountTree.update(new BN(tokenId), amount);
    }

    updateHash(): BN {
        this.hash = Helpers.hexToBN(web3.utils.soliditySha3(
            web3.eth.abi.encodeParameters(
                ['uint256', 'uint32'],
                [this.accountTree.rootHash(), this.nonce]
            )
        ));
        return this.hash;
    }
}