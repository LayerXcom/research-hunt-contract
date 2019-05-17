const ResearchHunt = artifacts.require("research_hunt");

const moment = require('moment');

const testrpc = require('./helpers/testrpc');

const truffleAssert = require('truffle-assertions');

const { expectThrow } = require('./helpers/expectThrow');

contract("ResearchHunt", ([account, payee]) => {
  // eth amount for test
  const amount = 10000;

  const uuid = "0x1111111111111111111111111111111111111111111111111111111111111111"

  // snapshot
  let snapshotId;

  // before action
  beforeEach(async function () {
    snapshot = await testrpc.takeSnapshot();
    snapshotId = snapshot['result']
  });

  // after action
  afterEach(async function () {
    await testrpc.revertToSnapshot(snapshotId);
  });

  it("should be created a research request with ", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.weiAmount == amount
    }, 'RequestCreated event should be emitted.');
  });

  it("should not be created a research request with same research request ID", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.weiAmount == amount
    }, 'RequestCreated event should be emitted.');

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount }));
  });

  it("should not be created a research request with value 0 wei", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: 0 }));
  });

  it("should not be created a research request with applicationEndAt > submissionEndAt", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(4, 'days').unix(),
      moment().add(2, 'days').unix(),
      { from: account, value: amount }));
  });

  it("should not be created a research request with referenceTime > applicationEndAt, submissionEndAt", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().subtract(2, 'days').unix(),
      moment().subtract(4, 'days').unix(),
      { from: account, value: amount }));
  });

  it("should be set application minimum timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.setApplicationMinimumTimespan(2 * 24 * 60 * 60, { from: account });

    truffleAssert.eventEmitted(result, 'ApplicationMinimumTimespanChanged', (ev) => {
      return ev.applicationMinimumTimespan == (2 * 24 * 60 * 60)
    }, 'ApplicationMinimumTimespanChanged event should be emitted.');
  });

  it("should be set submission minimum timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.setSubmissionMinimumTimespan(2 * 24 * 60 * 60, { from: account });

    truffleAssert.eventEmitted(result, 'SubmissionMinimumTimespanChanged', (ev) => {
      return ev.submissionMinimumTimespan == (2 * 24 * 60 * 60)
    }, 'SubmissionMinimumTimespanChanged event should be emitted.');
  });

  it("should be set distribution end timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const result = await researchHunt.setDistributionEndTimespan(4 * 24 * 60 * 60, { from: account });

    truffleAssert.eventEmitted(result, 'DistributionEndTimespanChanged', (ev) => {
      return ev.distributionEndTimespan == (4 * 24 * 60 * 60)
    }, 'DistributionEndTimespanChanged event should be emitted.');
  });

  it("should be set refundable timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.setRefundableTimespan(18 * 24 * 60 * 60, { from: account });

    truffleAssert.eventEmitted(result, 'RefundableTimespanChanged', (ev) => {
      return ev.refundableTimespan == (18 * 24 * 60 * 60)
    }, 'RefundableTimespanChanged event should be emitted.');
  });

  it("should be refunded with correct refundable timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    await testrpc.advanceTime(18 * 24 * 60 * 60);

    const resultRefund = await researchHunt.refund(uuid, { from: account });

    truffleAssert.eventEmitted(resultRefund, 'Withdrawn', (ev) => {
      return ev.weiAmount == amount
    }, 'Withdrawn event should be emitted.');
  });

  it("should not be refunded with incorrect refund timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    await testrpc.advanceTime(18 * 24 * 60 * 60 - 1);

    await expectThrow(researchHunt.refund(uuid, { from: account }));
  });

  it("should be distributed with correct distribution timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    await testrpc.advanceTime(4 * 24 * 60 * 60 + 1);

    const resultDistribute = await researchHunt.distribute(uuid, payee, amount, { from: account });

    truffleAssert.eventEmitted(resultDistribute, 'Withdrawn', (ev) => {
      return ev.weiAmount == amount
    }, 'Withdrawn event should be emitted.');
  });

  it("should not be distributed with incorrect distribution timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    await testrpc.advanceTime(4 * 24 * 60 * 60 );

    await expectThrow(researchHunt.distribute(uuid, payee, amount, { from: account }));
  });

  it("should not be distributed with incorrect amount", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      { from: account, value: amount });

    await testrpc.advanceTime(4 * 24 * 60 * 60 + 1);

    await expectThrow(researchHunt.distribute(uuid, payee, amount + 1, { from: account }));
  });
});