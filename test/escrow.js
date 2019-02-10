const Escrow = artifacts.require("Escrow");

const { expectThrow } = require('./helpers/expectThrow');

contract("Escrow", ([account, payee]) => {
  const amount = 12345;

  it("should not be depositable the value 0 wei.", async () => {
    const escrow = await Escrow.deployed();

    await expectThrow(escrow.deposit(payee, {from: account, value: 0}), 'revert');
  });

  it("should not be withdrawable when escrow have not been deposited.", async () => {
    const escrow = await Escrow.deployed();

    await expectThrow(escrow.withdraw(payee, {from: account}), 'revert');
  });

  it("should be depositable the value 12345 wei.", async () => {

    const escrow = await Escrow.deployed();

    await escrow.deposit(payee, {from: account, value: amount});

    const depositsOf = await escrow.depositsOf(payee);

    assert.equal(depositsOf, amount, "The value " + amount + " was not deposited.");
  });

  it("should be withdrawable the all wei value.", async () => {

    const escrow = await Escrow.deployed();

    await escrow.withdraw(payee, {from: account});

    const depositsOf = await escrow.depositsOf(payee);

    assert.equal(depositsOf, 0, "The value " + amount + " was not withdrawn.");
  });

  it("should be withdrawable the value 10000 wei (12345 deposited).", async () => {
    const withdrawAmount = 10000;

    const escrow = await Escrow.deployed();

    await escrow.deposit(payee, {from: account, value: amount});

    await escrow.withdrawAmount(payee, withdrawAmount, {from: account});

    const depositsOf = await escrow.depositsOf(payee);

    assert.equal(depositsOf, amount - withdrawAmount, "The value " + amount + " was not withdrawn.");
  });
});
