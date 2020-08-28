const Web3 = require('web3');
const web3 = new Web3();
import BN = require('bn.js');

const MAX_NUMBER_OF_TOKENS = 4096;
const MAX_NUMBER_OF_ACCOUNTS = 2 ** 32;

export function hexToBN (hexString: string): BN {
  return new BN(web3.utils.hexToNumberString(hexString));
}

export function keccackBuffer (buffer: Buffer): BN {
  return hexToBN(web3.utils.soliditySha3('0x' + buffer.toString('hex')));
}

export function serializeNonce (nonce: number): Buffer {
  if (nonce < 0) {
    throw new Error('Negative nonce');
  }
  const buff = Buffer.alloc(4);
  buff.writeUInt32BE(nonce, 0);
  return buff;
}

export function serializeTokenID (tokenID: number): Buffer {
  if (tokenID < 0) {
    throw new Error('Negative tokenId');
  }
  if (tokenID >= MAX_NUMBER_OF_TOKENS) {
    throw new Error('TokenId is too big');
  }
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16BE(tokenID, 0);
  return buffer;
}

export function serializeTokenIDs (tokenIDs: number[]): Buffer {
  let buffers: Buffer[] = [];
  tokenIDs.forEach(token => {
    buffers.push(serializeTokenID(token));
  });
  return Buffer.concat(buffers);
}

export function serializeAccountID (accountID: number): Buffer {
  if (accountID < 0) {
    throw new Error('Negative accountId');
  }

  if (accountID >= MAX_NUMBER_OF_ACCOUNTS) {
    throw new Error('accountId is too big');
  }
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32BE(accountID, 0);
  return buffer;
}

export function serializeAccountIDs (accountIDs: number[]): Buffer {
  let buffers: Buffer[] = [];
  accountIDs.forEach(accountID => {
    buffers.push(serializeAccountID(accountID));
  });
  return Buffer.concat(buffers);
}

export function serializeAmount (amount: BN): Buffer {
  return amount.toArrayLike(Buffer, 'be', 6);
}

export function serializeAmountArray (amounts: BN[]): Buffer {
  let buffers: Buffer[] = [];
  amounts.forEach(amount => {
    buffers.push(serializeAmount(amount));
  });
  return Buffer.concat(buffers);
}

export function serializeBN (amount: BN): Buffer {
  return amount.toArrayLike(Buffer, 'be', 32);
}

export function serializeBNArray (amounts: BN[]): Buffer {
  let buffers: Buffer[] = [];
  amounts.forEach(amount => {
    buffers.push(serializeBN(amount));
  });
  return Buffer.concat(buffers);
}

export function serializeTxType (type: number): Buffer {
  const buffer = Buffer.alloc(1);
  buffer.writeUInt8(type, 0);
  return buffer;
}

export function serializeArrayLength (length: number): Buffer {
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16BE(length, 0);
  return buffer;
}

export function serializeIndex (length: number): Buffer {
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16BE(length, 0);
  return buffer;
}

export function convertNumberArray2BN (arr: number[]): BN[] {
  let out: BN[] = [];
  for (let i = 0; i < arr.length; i++) {
    out.push(new BN(arr[i]));
  }
  return out;
}

export function revertIndex (arr: number[]): Record<number, number> {
  let out: Record<number, number> = {};
  for (let i = 0; i < arr.length; i++) {
    out[arr[i]] = i;
  }
  return out;
}
