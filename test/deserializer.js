const MockDeserializer = artifacts.require('MockDeserializer');

const {assert} = require('chai');
const fs = require('fs');

contract('Deserializer', accounts => {
  let deserializer;
  before('', async () => {
    deserializer = await MockDeserializer.new();
  });

  it('#getMiniBlockHash', async () => {
    assert.equal(
      await deserializer.testGetMiniBlockHash(
        '0xe6f53fb46a751236ebbb669da697888bc5230a12e858a8a26ada4229e0f71405a6d5aae3927c2ea22e9e9c057a1559cf4608225362ad9caf0beb57ce1edc3d1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
      ),
      '0x5c9d7b2453c5744b6a702010d6da89f2a9181d381978c1316e420ccfed7e985f',
      'missmach hash'
    );
  });

  it('#readSettlementOp1', async () => {
    let testSuit = JSON.parse(fs.readFileSync('./testdata/deserializeSettlement1.json'))[0];
    let result = await deserializer.testReadSettlementOp1(testSuit.Data);
    console.log(result);
  });
});
