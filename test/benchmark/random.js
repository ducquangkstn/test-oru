const {rand} = require('./randomGenerator');
const os = require('os');
const fs = require('fs');

const numAccount = 500;
const numDeposit = 100;

let userIDs;
let balances;
let tokenIDs;

function randomInit () {
  let fd;
  try {
    fd = fs.openSync('testSample/init.tx', 'a');
    for (let i = 0; i < numAccount; i++) {
      fs.appendFileSync(fd, rand(2 ** 32 - 1) + ',' + rand(2 ** 10 - 1) + ',' + rand(2 ** 32 - 1) + '\n', 'utf8');
    }
  } catch (err) {
    /* Handle the error */
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

function readInfo() {
  let data = fs.readFileSync('testSample/init.tx', {encoding:'utf8', flag:'r'}).split('\n');
  userIDs =[];
  tokenIDs = [];
  balances = [];
  data.forEach(line => {
    let split = line.split(',');
    userIDs.push(Number(split[0]));
    tokenIDs.push(Number(split[1]));
    balances.push(Number(split[2]));
  })
  return {
    userIDs,
    tokenIDs,
    balances
  }
}

function generateDeposit() {
  let fd;
  try {
    fd = fs.openSync('testSample/deposit.tx', 'a');
    for (let i = 0; i < numDeposit; i++) {
      index = rand(numAccount);
      fs.appendFileSync(fd, userIDs[index] + ',' + tokenIDs[index] + ',' + rand(10000) + '\n', 'utf8');
    }
  } catch (err) {
    /* Handle the error */
    console.log(err)
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

function generateTransfer() {
  let fd;
  try {
    fd = fs.openSync('testSample/transfer.tx', 'a');
    for (let i = 0; i < numDeposit; i++) {
      index = rand(numAccount);
      receiverIndex = rand(numAccount);
      fs.appendFileSync(fd, userIDs[index]+',' + userIDs[receiverIndex] + ',' + tokenIDs[index] + ',' + rand(10000) + '\n', 'utf8');
    }
  } catch (err) {
    /* Handle the error */
    console.log(err)
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

function readInfoDeposit() {
  let data = fs.readFileSync('testSample/deposit.tx', {encoding:'utf8', flag:'r'}).split('\n');
  let senderIDs =[];
  let tokenIDs = [];
  let amounts = [];
  data.forEach(line => {
    let split = line.split(',');
    senderIDs.push(Number(split[0]));
    tokenIDs.push(Number(split[1]));
    amounts.push(Number(split[2]));
  })
  return {
    senderIDs,
    tokenIDs,
    amounts
  }
}

function readInfoTransfer() {
  let data = fs.readFileSync('testSample/transfer.tx', {encoding:'utf8', flag:'r'}).split('\n');
  let senderIDs =[];
  let receiverIDs = [];
  let tokenIDs = [];
  let amounts = [];
  data.forEach(line => {
    let split = line.split(',');
    senderIDs.push(Number(split[0]));
    receiverIDs.push(Number(split[1]));
    tokenIDs.push(Number(split[2]));
    amounts.push(Number(split[3]));
  })
  return {
    senderIDs,
    receiverIDs,
    tokenIDs,
    amounts
  }
}

module.exports = { readInfo, readInfoDeposit, readInfoTransfer, generateDeposit}