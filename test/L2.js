const L2 = artifacts.require('L2')

const BN = web3.utils.BN

const treeHelper = require('./treeHelpers')

const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers')

contract('L2', accounts => {
  describe('test deposit', async () => {
    it('test', async () => {
        tree = new treeHelper.BalanceTree(161)
        let key = new BN(
          web3.utils.hexToNumberString(
            '0x85E456C9AA9e8d6f1DF6E1aae6496b25b157634F'
          )
        )

        let key2 = new BN(
            web3.utils.hexToNumberString(
              '0xdC70a72AbF352A0E3f75d737430EB896BA9Bf9Ea'
            )
          )
        // add 13 to key
        let [preValue, prevSiblings] = tree.getProof(key)
        assert(preValue.eq(new BN(0)), 'value missmatch')
        tree.update(key, new BN(13))
        let [value, siblings] = tree.getProof(key)
        assert(value.eq(new BN(13)), 'value missmatch')

        newRoot = treeHelper.merkleRoot(key, value, prevSiblings)


        let l2 = await L2.new()

        await l2.updateRoot(newRoot)

        let result = await l2.submitProofDeposit(
          new BN(1),
          '0x85E456C9AA9e8d6f1DF6E1aae6496b25b157634F',
          new BN(0),
          new BN(value),
          prevSiblings
        )

        expectEvent(result, 'SubmitDeposit', {
          isValid: true,
          blkNumber: new BN(1)
        })

        // add 14 to key
        preValue = value
        prevSiblings = siblings
        assert(preValue.eq(new BN(13)), 'value missmatch')
        tree.update(key, new BN(27))
        assert(tree.getProof(key)[0].eq(new BN(27)), 'value missmatch')

        // newRoot = treeHelper.merkleRoot(key, new BN(27), prevSiblings)
        await l2.updateRoot(tree.root.root)

        result = await l2.submitProofDeposit(
          new BN(2),
          '0x85E456C9AA9e8d6f1DF6E1aae6496b25b157634F',
          new BN(13),
          new BN(14),
          prevSiblings
        )

        expectEvent(result, 'SubmitDeposit', {
          isValid: true,
          blkNumber: new BN(2)
        })

        // transfer 5 from key to key 2
        proof = tree.getProof(key)
        beforeSender = proof[0]
        senderSibings = proof[1]

        tree.update(key, new BN(22))
        proof = tree.getProof(key2)
        beforeReceiver = proof[0]
        receiverSibings = proof[1]

        tree.update(key2, new BN(5))

        await l2.updateRoot(tree.root.root)

        result = await l2.submitProofTransfer(
            new BN(3),
            '0x85E456C9AA9e8d6f1DF6E1aae6496b25b157634F',
            '0xdC70a72AbF352A0E3f75d737430EB896BA9Bf9Ea',
            beforeSender,
            beforeReceiver,
            new BN(5),
            [senderSibings, receiverSibings]
        );

        // expectEvent(result, 'SubmitTransfer', {
        //     isValid: true,
        //     blkNumber: new BN(3)
        //   })
        console.log(result.receipt.gasUsed)
    })
  })
})
