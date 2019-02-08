const Escrow = artifacts.require("Escrow");

contract("Escrow", ([owner, nonOwner]) => {
  it("...should deposit the value 100.", async () => {
    const escrow = await Escrow.deployed();

    await escrow.deposit(owner), { from: owner, value: 100 };

    const depositsOf = await escrow.depositsOf(owner);

    assert.equal(depositsOf, 100, "The value 100 was not deposited.");
  });
});
