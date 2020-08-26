const Web3 = require('web3');
const web3 = new Web3();
import BN = require('bn.js');

import {MerkleTree} from './treeHelpers';
import * as Helpers from './helpers';

enum TransactionType {
  NOOP_TX_TYPE = 0,
  TRANSFER = 1,
  DEPOSIT = 2
}

const TOKEN_TREE_DEEP = 13;
const ACCOUNT_TREE_DEEP = 33;

export class Blockchain {
  tree: MerkleTree;
  accounts: Record<number, Account>;
  lastBlockHash: BN;

  constructor () {
    this.tree = new MerkleTree(ACCOUNT_TREE_DEEP);
    this.accounts = {};
  }

  //// addBlock handle tx and returns proof
  addBlock (block: Block): [BlockchainProof, String[]] {
    let txProofs: String[] = [];

    let accountIDSet: Set<number> = new Set();
    let accountTokenIDSet: Record<number, Set<number>> = {};

    block.txs.forEach(tx => {
      switch (tx.txType()) {
        case TransactionType.DEPOSIT:
          let deposit = tx as Deposit;

          if (accountTokenIDSet[deposit.senderId] == undefined) {
            accountTokenIDSet[deposit.senderId] = new Set();
          }
          accountTokenIDSet[deposit.senderId].add(deposit.tokenId);
          accountIDSet.add(deposit.senderId);
          break;
        case TransactionType.TRANSFER:
          let transfer = tx as Transfer;
          if (accountTokenIDSet[transfer.senderId] == undefined) {
            accountTokenIDSet[transfer.senderId] = new Set();
          }
          accountTokenIDSet[transfer.senderId].add(transfer.tokenId);
          if (accountTokenIDSet[transfer.receiverId] == undefined) {
            accountTokenIDSet[transfer.receiverId] = new Set();
          }
          accountTokenIDSet[transfer.receiverId].add(transfer.tokenId);
          accountIDSet.add(transfer.senderId);
          accountIDSet.add(transfer.receiverId);
          break;
        default:
          throw Error(`unexpected type: ${tx.txType()}`);
      }
    });
    /// accountIDsRevert and tokenIDsRevert to point back to from IDs to the index in blockchainProof
    let accountIDs = Array.from(accountIDSet).sort((x, y) => x - y);
    let accountIDsRevert = Helpers.revertIndex(accountIDs);
    let tokenIDsRevert: Record<number, Record<number, number>> = {};

    let accountProofs = [];
    for (let i = 0; i < accountIDs.length; i++) {
      let tokenIDs = Array.from(accountTokenIDSet[accountIDs[i]]).sort((x, y) => x - y);
      tokenIDsRevert[accountIDs[i]] = Helpers.revertIndex(tokenIDs);

      if (this.accounts[accountIDs[i]] == undefined) {
        this.accounts[accountIDs[i]] = new Account();
      }
      accountProofs.push(this.accounts[accountIDs[i]].getProof(tokenIDs));
    }

    let [, accountSiblings] = this.tree.getProofBatch(Helpers.convertNumberArray2BN(accountIDs));
    let bcProof = new BlockchainProof(accountIDs, accountProofs, accountSiblings);

    block.txs.forEach(tx => {
      switch (tx.txType()) {
        case TransactionType.DEPOSIT:
          let deposit = tx as Deposit;
          this.handleDeposit(deposit);
          txProofs.push(
            '0x' +
              Buffer.concat([
                Helpers.serializeIndex(tokenIDsRevert[deposit.senderId][deposit.tokenId]),
                Helpers.serializeIndex(accountIDsRevert[deposit.senderId])
              ]).toString('hex')
          );
          break;
        case TransactionType.TRANSFER:
          let transfer = tx as Transfer;
          this.handleTransfer(transfer);
          txProofs.push(
            '0x' +
              Buffer.concat([
                Helpers.serializeIndex(tokenIDsRevert[transfer.senderId][transfer.tokenId]),
                Helpers.serializeIndex(accountIDsRevert[transfer.senderId]),
                Helpers.serializeIndex(tokenIDsRevert[transfer.receiverId][transfer.tokenId]),
                Helpers.serializeIndex(accountIDsRevert[transfer.receiverId])
              ]).toString('hex')
          );
          break;
        default:
          throw Error(`unexpected type: ${tx.txType()}`);
      }
    });

    block.root = this.tree.rootHash();
    this.lastBlockHash = block.hash();
    return [bcProof, txProofs];
  }

  handleDeposit (deposit: Deposit): Buffer {
    let account;
    if (this.accounts[deposit.senderId]) {
      account = this.accounts[deposit.senderId];
    } else {
      account = new Account();
      this.accounts[deposit.senderId] = account;
    }

    if (account.nonce != deposit.nonce) throw Error('account nonce is miss-match');

    let [beforeBalance, tokenSiblings] = account.accountTree.getProof(new BN(deposit.tokenId));
    let [_, accountSiblings] = this.tree.getProof(new BN(deposit.senderId));

    account.nonce++;
    account.update(deposit.tokenId, beforeBalance.add(deposit.amount));
    let newHash = account.updateHash();
    this.tree.update(new BN(deposit.senderId), newHash);
    return Buffer.concat([
      Helpers.serializeBNArray(accountSiblings),
      Helpers.serializeBN(beforeBalance),
      Helpers.serializeBNArray(tokenSiblings),
      Helpers.serializeNonce(deposit.nonce)
    ]);
  }

  handleTransfer (transfer: Transfer) {
    if (!this.accounts[transfer.senderId]) {
      throw Error('empty sender Id');
    }
    let account = this.accounts[transfer.senderId];
    if (account.nonce != transfer.nonce) {
      throw Error('account nonce is miss-match');
    }
    let beforeBalance = account.accountTree.get(new BN(transfer.tokenId));
    if (beforeBalance.lt(transfer.amount)) {
      throw Error('balance is not enough');
    }
    account.nonce++;
    account.update(transfer.tokenId, beforeBalance.sub(transfer.amount));
    this.tree.update(new BN(transfer.senderId), account.updateHash());

    if (this.accounts[transfer.receiverId]) {
      account = this.accounts[transfer.receiverId];
    } else {
      account = new Account();
      this.accounts[transfer.receiverId] = account;
    }

    let receiverBeforeBalance = account.accountTree.get(new BN(transfer.tokenId));
    account.update(transfer.tokenId, receiverBeforeBalance.add(transfer.amount));
    this.tree.update(new BN(transfer.receiverId), account.updateHash());
  }

  head () {
    return this.lastBlockHash;
  }
}

export class Block {
  preHash: BN;
  root: BN;
  txs: Transaction[] = [];

  constructor (preHash: BN) {
    this.preHash = preHash;
  }

  addTransaction (tx: Transaction) {
    this.txs.push(tx);
  }

  hash (): BN {
    let txHash = Helpers.keccackBuffer(this.toBuffer());
    return Helpers.hexToBN(
      web3.utils.soliditySha3(
        web3.eth.abi.encodeParameters(['uint256', 'uint256', 'uint256'], [this.preHash, this.root, txHash])
      )
    );
  }

  toBuffer (): Buffer {
    let txBuffers: Buffer[] = [];
    this.txs.forEach(tx => {
      txBuffers.push(tx.toBuffer());
    });
    return Buffer.concat([Buffer.concat(txBuffers)]);
  }
}
interface Transaction {
  senderId: number;
  nonce: number;

  toBuffer: () => Buffer;
  txType: () => TransactionType;
}

export class Transfer implements Transaction {
  constructor (
    public senderId: number,
    public receiverId: number,
    public tokenId: number,
    public amount: BN,
    public nonce: number
  ) {}

  toBuffer (): Buffer {
    return Buffer.concat([
      Helpers.serializeTxType(TransactionType.TRANSFER),
      Helpers.serializeAccountID(this.senderId),
      Helpers.serializeAccountID(this.receiverId),
      Helpers.serializeNonce(this.nonce),
      Helpers.serializeTokenID(this.tokenId),
      Helpers.serializeBN(this.amount)
    ]);
  }

  txType (): TransactionType {
    return TransactionType.TRANSFER;
  }
}

export class Deposit implements Transaction {
  constructor (public senderId: number, public tokenId: number, public amount: BN, public nonce: number) {}

  toBuffer (): Buffer {
    return Buffer.concat([
      Helpers.serializeTxType(TransactionType.DEPOSIT),
      Helpers.serializeAccountID(this.senderId),
      Helpers.serializeNonce(this.nonce),
      Helpers.serializeTokenID(this.tokenId),
      Helpers.serializeBN(this.amount)
    ]);
  }

  txType (): TransactionType {
    return TransactionType.DEPOSIT;
  }
}

export class BlockchainProof {
  constructor (public accountIDs: number[], public accounts: AccountProof[], public siblings: BN[]) {}

  toBuffer (): Buffer {
    let accountBuffers: Buffer[] = [];
    this.accounts.forEach(a => {
      accountBuffers.push(a.toBuffer());
    });
    return Buffer.concat([
      Helpers.serializeArrayLength(this.accountIDs.length),
      Helpers.serializeAccountIDs(this.accountIDs),
      Buffer.concat(accountBuffers),
      Helpers.serializeArrayLength(this.siblings.length),
      Helpers.serializeBNArray(this.siblings)
    ]);
  }
}

export class AccountProof {
  constructor (public tokenIDs: number[], public tokenAmounts: BN[], public siblings: BN[], public nonce: number) {}

  toBuffer (): Buffer {
    return Buffer.concat([
      Helpers.serializeArrayLength(this.tokenIDs.length),
      Helpers.serializeTokenIDs(this.tokenIDs),
      Helpers.serializeBNArray(this.tokenAmounts),
      Helpers.serializeArrayLength(this.siblings.length),
      Helpers.serializeBNArray(this.siblings),
      Helpers.serializeNonce(this.nonce)
    ]);
  }
}

class Account {
  accountTree: MerkleTree;
  nonce: number;
  hash: BN;
  constructor () {
    this.accountTree = new MerkleTree(TOKEN_TREE_DEEP);
    this.nonce = 0;
  }

  update (tokenId: number, amount: BN) {
    this.accountTree.update(new BN(tokenId), amount);
  }

  updateHash (): BN {
    this.hash = Helpers.hexToBN(
      web3.utils.soliditySha3(
        web3.eth.abi.encodeParameters(['uint256', 'uint32'], [this.accountTree.rootHash(), this.nonce])
      )
    );
    return this.hash;
  }

  getProof (tokenIDs: number[]): AccountProof {
    let tokenIDsBN = Helpers.convertNumberArray2BN(tokenIDs);
    let [amounts, siblings] = this.accountTree.getProofBatch(tokenIDsBN);
    return new AccountProof(tokenIDs, amounts, siblings, this.nonce);
  }
}
