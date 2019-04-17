const ResearchHunt = artifacts.require("research_hunt");

const _ = require('lodash');

const truffleAssert = require('truffle-assertions');

const { expectThrow } = require('./helpers/expectThrow');

const { increaseTime } = require('./helpers/increaseTime');

const { convertToUnixtime } = require('./helpers/convertToUnixtime');

contract("ResearchHunt", ([account, payee]) => {
  const amount = 10000;

  const referenceTime = new Date();

  it ("should be created a research request with ", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const applicationEndAt = _.cloneDeep(referenceTime);
    applicationEndAt.setDate(applicationEndAt.getDate() + 1);
    const applicationEndAtUnixtime = convertToUnixtime(applicationEndAt);

    const submissionEndAt = _.cloneDeep(referenceTime);
    submissionEndAt.setDate(submissionEndAt.getDate() + 2);
    const submissionEndAtUnixtime = convertToUnixtime(submissionEndAt);

    const result = await researchHunt.createResearchRequest(1, applicationEndAtUnixtime, submissionEndAtUnixtime, {from: account, value: 1000});

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.weiAmount == 1000
    }, 'RequestCreated event should be emitted.');
  });

  it ("should not be created a research request with value 0 wei", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const applicationEndAt = _.cloneDeep(referenceTime);
    applicationEndAt.setDate(applicationEndAt.getDate() + 1);
    const applicationEndAtUnixtime = convertToUnixtime(applicationEndAt);

    const submissionEndAt = _.cloneDeep(referenceTime);
    submissionEndAt.setDate(submissionEndAt.getDate() + 2);
    const submissionEndAtUnixtime = convertToUnixtime(submissionEndAt);

    await expectThrow(researchHunt.createResearchRequest(1, applicationEndAtUnixtime, submissionEndAtUnixtime, {from: account, value: 0}));
  });

  it ("should not be created a research request with ", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const applicationEndAt = _.cloneDeep(referenceTime);
    applicationEndAt.setDate(applicationEndAt.getDate() + 2);
    const applicationEndAtUnixtime = convertToUnixtime(applicationEndAt);

    const submissionEndAt = _.cloneDeep(referenceTime);
    submissionEndAt.setDate(submissionEndAt.getDate() + 1);
    const submissionEndAtUnixtime = convertToUnixtime(submissionEndAt);

    await expectThrow(researchHunt.createResearchRequest(1, applicationEndAtUnixtime, submissionEndAtUnixtime, {from: account, value: 1000}));
  });

  it ("should not be created a research request with ", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const applicationEndAt = _.cloneDeep(referenceTime);
    applicationEndAt.setDate(applicationEndAt.getDate() - 1);
    const applicationEndAtUnixtime = convertToUnixtime(applicationEndAt);

    const submissionEndAt = _.cloneDeep(referenceTime);
    submissionEndAt.setDate(submissionEndAt.getDate() - 2);
    const submissionEndAtUnixtime = convertToUnixtime(submissionEndAt);

    await expectThrow(researchHunt.createResearchRequest(1, applicationEndAtUnixtime, submissionEndAtUnixtime, {from: account, value: 1000}));
  });

    /*
  it("should not be depositable the value 0 wei.", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.deposit(payee, {from: account, value: 0}), 'revert');
  });

  it("should not be withdrawable when researchHunt have not been deposited.", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.withdraw(payee, {from: account}), 'revert');
  });

  it("should be depositable the value 10000 wei.", async () => {

    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.deposit(payee, {from: account, value: amount});

    const depositsOf = await researchHunt.depositsOf(payee);

    assert.equal(depositsOf, amount, "The value " + amount + " was not deposited.");
  });

  it("should be withdrawable the all wei value.", async () => {

    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.withdraw(payee, {from: account});

    const depositsOf = await researchHunt.depositsOf(payee);

    assert.equal(depositsOf, 0, "The value " + amount + " was not withdrawn.");
  });

  it("should be withdrawable the value 10000 wei (10000 deposited).", async () => {
    const withdrawAmount = 10000;

    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.deposit(payee, {from: account, value: amount});

    await researchHunt.withdrawAmount(payee, withdrawAmount, {from: account});

    const depositsOf = await researchHunt.depositsOf(payee);

    assert.equal(depositsOf, amount - withdrawAmount, "The value " + withdrawAmount + " was not withdrawn.");
  });

  it("should be not withdrawable the value 10001 wei (10000 deposited).", async () => {
    const withdrawAmount = 10001;

    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.deposit(payee, {from: account, value: amount});

    await expectThrow(researchHunt.withdrawAmount(payee, withdrawAmount, {from: account}), 'revert');
  });
  */
});
