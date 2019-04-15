const VPool = artifacts.require("VPool");
const truffleAssert = require("truffle-assertions");

contract("VPool", async accounts => {
  let instance;

  beforeEach(async () => {
    instance = await VPool.new("0x0000000000000000000000000000456e65726779", "0xB74C4EBd95F70Dd9794d8c49053a297689950b63");
  });

  it("should set the initial total minted supply to 0", async () => {
    const initalMintedSupply = await instance.totalMintedSupply();

    assert.equal(initalMintedSupply.toNumber(), 0);
  });

  describe("deposit", () => {
    const VETAmount = web3.utils.toWei("10", "ether");

    it("should fail if no VET is sent", async () => {
      const noVETSentRequest = instance.deposit({
        from: accounts[0],
        value: 0
      });

      await truffleAssert.fails(noVETSentRequest);
    });

    describe("when the total minted supply is 0", async () => {
      it("should set the total minted amount to the initial deposit", async () => {
        await instance.deposit({ from: accounts[0], value: VETAmount });

        const totalMintedSupply = await instance.totalMintedSupply();

        assert.equal(totalMintedSupply, VETAmount);
      });

      it("should set the minted balance of the sender to their initial deposit", async () => {
        await instance.deposit({ from: accounts[0], value: VETAmount });

        const senderBalance = await instance.balanceOf(accounts[0]);

        assert.equal(senderBalance, VETAmount);
      });
    });

    describe("when the total minted supply is > 0", async () => {
      const newVETAmount = web3.utils.toWei("50", "ether");

      beforeEach(async () => {
        await instance.deposit({ from: accounts[0], value: VETAmount }); // initial deposit
      });

      it("should add new mint to the total minted amount", async () => {
        const initialMintedSupply = await instance.totalMintedSupply();
        const contractBalance = await web3.eth.getBalance(instance.address);

        await instance.deposit({ from: accounts[0], value: newVETAmount });

        const totalMintedSupply = await instance.totalMintedSupply();

        const expectedAddedAmount = new web3.utils.BN(
          ((initialMintedSupply / contractBalance) * newVETAmount).toString()
        );

        const expected = initialMintedSupply.add(expectedAddedAmount);

        assert.equal(totalMintedSupply.eq(expected), true);
      });

      it("should add the minted amount to the sender's balance", async () => {
        const initialMintedSupply = await instance.totalMintedSupply();
        const contractBalance = await web3.eth.getBalance(instance.address);

        await instance.deposit({ from: accounts[1], value: newVETAmount });

        const expectedBalance1 =
          (initialMintedSupply / contractBalance) * newVETAmount;

        const senderBalance1 = await instance.balanceOf(accounts[1]);

        assert.equal(senderBalance1, expectedBalance1);

        const newContractBalance = await web3.eth.getBalance(instance.address);
        const newMintedSupply = await instance.totalMintedSupply();

        await instance.deposit({ from: accounts[2], value: newVETAmount });

        const expectedBalance2 =
          (newMintedSupply / newContractBalance) * newVETAmount;

        const senderBalance2 = await instance.balanceOf(accounts[2]);

        assert.equal(senderBalance2.toString(), expectedBalance2);
      });
    });
  });

  describe("withdraw", () => {
    it("should fail if the total minted supply is 0", async () => {
      const initalMintedSupply = await instance.totalMintedSupply();

      assert.equal(initalMintedSupply.toString(), 0);

      const withdrawWhenNoMintedSupplyRequest = instance.withdraw(10);

      await truffleAssert.fails(withdrawWhenNoMintedSupplyRequest);
    });

    describe("when user withdraws their entire amount", async () => {
      it("should update the total minted amount", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        const initalMintedSupply = await instance.totalMintedSupply();
        const senderBalance = await instance.balanceOf(accounts[4]);

        assert.equal(initalMintedSupply, VETAmount);
        assert.equal(senderBalance, VETAmount);

        await instance.withdraw.sendTransaction(VETAmount + 1, {
          from: accounts[4]
        });

        const newMintedSupply = await instance.totalMintedSupply();

        assert.equal(newMintedSupply.toString(), 0);
      });

      it("should update the user's balance to 0", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        const initalMintedSupply = await instance.totalMintedSupply();
        const senderBalance = await instance.balanceOf(accounts[4]);

        assert.equal(initalMintedSupply, VETAmount);
        assert.equal(senderBalance, VETAmount);

        await instance.withdraw.sendTransaction(VETAmount, {
          from: accounts[4]
        });

        const newSenderBalance = await instance.balanceOf(accounts[4]);

        assert.equal(newSenderBalance.toString(), 0);
      });

      it("should send the amount to the account", async () => {
        const initialBalance = await web3.eth.getBalance(accounts[4]);
        const VETAmount = web3.utils.toWei("10", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        const balanceAfterDeposit = await web3.eth.getBalance(accounts[4]);

        assert.equal(balanceAfterDeposit, initialBalance - VETAmount);

        await instance.withdraw(VETAmount, {
          from: accounts[4]
        });

        const balanceAfterWithdraw = await web3.eth.getBalance(accounts[4]);

        assert.equal(balanceAfterWithdraw, balanceAfterDeposit + VETAmount);
      });
    });
    describe("when user withdraws a partial amount", () => {
      it("should update the total minted amount", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");
        const VETWithdrawAmount = web3.utils.toWei("9", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        await instance.withdraw.sendTransaction(VETWithdrawAmount, {
          from: accounts[4]
        });

        const newMintedSupply = await instance.totalMintedSupply();

        assert.equal(
          newMintedSupply.toString(),
          web3.utils.toWei("1", "ether")
        );
      });

      it("should update the user's balance", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");
        const VETWithdrawAmount = web3.utils.toWei("9", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        await instance.withdraw.sendTransaction(VETWithdrawAmount, {
          from: accounts[4]
        });

        const newSenderBalance = await instance.balanceOf(accounts[4]);

        assert.equal(
          newSenderBalance.toString(),
          web3.utils.toWei("1", "ether")
        );
      });
    });

    describe("when user has no balance", () => {
      it("should fail", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        const withdrawWhenNoBalance = instance.withdraw.call(10, {
          from: accounts[5]
        });

        await truffleAssert.fails(withdrawWhenNoBalance);
      });
    });

    describe("when user has an inadequate balance", async () => {
      it("should fail", async () => {
        const VETAmount = web3.utils.toWei("10", "ether");

        await instance.deposit({ from: accounts[4], value: VETAmount });

        const withdrawWhenInadequateBalance = instance.withdraw.call(
          web3.utils.toWei("10.01", "ether"),
          {
            from: accounts[4]
          }
        );

        await truffleAssert.fails(withdrawWhenInadequateBalance);
      });
    });
  });
});
