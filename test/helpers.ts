const Web3 = require("web3");
const web3 = new Web3();
import BN = require('bn.js');

const MAX_NUMBER_OF_TOKENS = 4096;
const MAX_NUMBER_OF_ACCOUNTS = 2 ** 32;

export function hexToBN(hexString: string): BN {
    return new BN(web3.utils.hexToNumberString(hexString));
}

export function keccackBuffer(buffer: Buffer): BN {
    return hexToBN(web3.utils.soliditySha3("0x" + buffer.toString('hex')));
}

export function serializeNonce(nonce: number): Buffer {
    if (nonce < 0) {
        throw new Error("Negative nonce");
    }
    const buff = Buffer.alloc(4);
    buff.writeUInt32BE(nonce, 0);
    return buff;
}

export function serializeTokenId(tokenId: number): Buffer {
    if (tokenId < 0) {
        throw new Error("Negative tokenId");
    }
    if (tokenId >= MAX_NUMBER_OF_TOKENS) {
        throw new Error("TokenId is too big");
    }
    const buffer = Buffer.alloc(2);
    buffer.writeUInt16BE(tokenId, 0);
    return buffer;
}

export function serializeAccountId(accountId: number): Buffer {
    if (accountId < 0) {
        throw new Error("Negative accountId");
    }

    if (accountId >= MAX_NUMBER_OF_ACCOUNTS) {
        throw new Error("accountId is too big");
    }
    const buffer = Buffer.alloc(4);
    buffer.writeUInt32BE(accountId, 0);
    return buffer;
}

export function serializeBN(amount: BN): Buffer {
    return amount.toArrayLike(Buffer, "be", 32);
}

export function serializeBNArray(amounts: BN[]): Buffer {
    let buffers: Buffer[] = [];
    amounts.forEach(amount => {
        buffers.push(serializeBN(amount));
    })
    return Buffer.concat(buffers);
}

export function serializeTxType(type: number): Buffer {
    const buffer = Buffer.alloc(1);
    buffer.writeUInt8(type, 0);
    return buffer;
}
