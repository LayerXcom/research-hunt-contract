const Escrow = artifacts.require("Escrow");

contract("Escrow", ([account, payee]) => {
  it("...should deposit the value 1000.", async () => {
    const amount = 1000;

    const escrow = await Escrow.deployed();

    await escrow.deposit(payee, {from: account, value: amount});

    const depositsOf = await escrow.depositsOf(payee);

    assert.equal(depositsOf, amount, "The value " + amount + " was not deposited.");
  });
});
