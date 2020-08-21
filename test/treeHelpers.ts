const Web3 = require("web3");
const web3 = new Web3();
import BN = require('bn.js');

import { hexToBN } from './helpers';

export function keccakParentOf(left: BN, right: BN): BN {
  if (left.eq(new BN(0)) && right.eq(new BN(0))) return new BN(0);
  return hexToBN(web3.utils.soliditySha3(
    web3.eth.abi.encodeParameters(['uint256', 'uint256'], [left, right])
  ));
}

export class MerkleTree {
  deep: number;
  root: Node;

  constructor(deep: number) {
    this.deep = deep;
    this.root = new Node(new BN(0), deep - 1, deep);
  }

  /// get key return a tuple of value and sibling to proof
  getProof(key: BN) {
    return this.root.getProof(key);
  }

  get(key: BN){
    return this.root.get(key);
  }

  update(key: BN, value: BN) {
    return this.root.update(key, value);
  }

  rootHash(): BN {
    return this.root.root
  }
}

/// this.left this.right child node of this node
///
class Node {
  root: BN;
  deep: number;
  treeDeep: number;
  left: Node;
  right: Node;

  constructor(root: BN, deep: number, treeDeep: number) {
    this.root = root;
    this.deep = deep;
    this.treeDeep = treeDeep;

  }
  leftHash(): BN {
    if (this.left == undefined) {
      return new BN(0);
    }
    return new BN(this.left.root);
  }

  rightHash(): BN {
    if (this.right == undefined) {
      return new BN(0);
    }
    return new BN(this.right.root);
  }

  get(key: BN): BN {
    let proof = this.getProof(key);
    return proof[0];
  }

  getProof(key: BN): [BN, BN[]] {
    // no child
    if (this.deep == 0) {
      return [this.root, []];
    }

    // let isLeft = ((key >> (this.deep - 1)) & 1) == 0
    let isLeft = key
      .ushrn(this.deep - 1)
      .uand(new BN(1))
      .eq(new BN(0));

    let value, siblings;
    if (isLeft) {
      if (this.left == undefined) {
        // return an array of preHash zero nodes
        siblings = [];
        if (this.deep > 1) {
          // create deep - 1 sibling to proof this child
          for (let i = 0; i < this.deep - 1; i++) {
            siblings.push(new BN(0));
          }
        }
        value = new BN(0);
      } else[value, siblings] = this.left.getProof(key);
      siblings.push(this.rightHash());
    } else {
      if (this.right == undefined) {
        // return an array of preHash zero nodes
        siblings = [];
        if (this.deep > 1) {
          // create deep - 1 sibling to proof this child
          for (let i = 0; i < this.deep - 1; i++) {
            siblings.push(new BN(0));
          }
        }
        value = new BN(0);
      } else[value, siblings] = this.right.getProof(key);

      siblings.push(this.leftHash());
    }

    // console.log('siblings', siblings.length, siblings[siblings.length - 1])
    return [value, siblings];
  }

  update(key: BN, value: BN) {
    if (this.deep == 0) {
      this.root = value;
      return;
    }

    // let isLeft = ((key >> (this.deep - 1)) & 1) == 0
    let isLeft = key
      .ushrn(this.deep - 1)
      .uand(new BN(1))
      .eq(new BN(0));
    if (isLeft) {
      if (this.left == undefined) {
        let childDeep = this.deep - 1;
        this.left = new Node(new BN(0), childDeep, this.treeDeep);
      }

      this.left.update(key, value);
      this.root = keccakParentOf(this.leftHash(), this.rightHash());
    } else {
      if (this.right == undefined) {
        let childDeep = this.deep - 1;
        this.right = new Node(new BN(0), childDeep, this.treeDeep);
      }

      this.right.update(key, value);
      this.root = keccakParentOf(this.leftHash(), this.rightHash());
    }
  }
}

/// key value is BN
export function merkleRoot(key: BN, value: BN, siblings: BN[]): BN {
  let root = value;
  for (let i = 0; i < siblings.length; i++) {
    // console.log(key);
    // key & 1 ==0
    if (key.uand(new BN(1)).eq(new BN(0))) {
      // right sibling
      root = keccakParentOf(root, siblings[i]);
    } else {
      // left sibling
      root = keccakParentOf(siblings[i], root);
    }
    // key >>= 1
    key = key.ushrn(1);
  }
  return root;
}

//module.exports = { keccakParentOf, merkleRoot, MerkleTree };
