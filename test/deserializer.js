
const MockDeserializer = artifacts.require('MockDeserializer');

contract("Deserializer", (accounts) => {
    it("getMiniBlockHash", async() => {
        let deserializer = await MockDeserializer.new();
        let miniBlockData = web3.utils.randomHex(70);
        console.log(await deserializer.testGetMiniBlockHash(miniBlockData));
    })
});