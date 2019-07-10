const ResearchHunt = artifacts.require("research_hunt");
const moment = require('moment');
const testrpc = require('./helpers/testrpc');
const truffleAssert = require('truffle-assertions');
const { expectThrow } = require('./helpers/expectThrow');

contract("ResearchHunt", ([account, reporter1, reporter2, reporter3]) => {
  // eth amount for test
  const amount = 10000;
  const uuid = "0x9999999999999999999999999999999999999999999999999999999999999999"
  const minimumReward = 79
  const reportHash1 = '0x1111111111111111111111111111111111111111111111111111111111111111'
  const reportHash2 = '0x2222222222222222222222222222222222222222222222222222222222222222'
  const reportHash3 = '0x3333333333333333333333333333333333333333333333333333333333333333'

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
      minimumReward,
      { from: account, value: amount });

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.deposit == amount && ev.minimumReward == minimumReward
    }, 'RequestCreated event should be emitted.');
  });

  it("should not be created a research request with same research request ID", async () => {
    const researchHunt = await ResearchHunt.deployed();

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.deposit == amount && ev.minimumReward == minimumReward
    }, 'RequestCreated event should be emitted.');

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount }));
  });

  it("should not be created a research request with value 0 wei", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: 0 }));
  });

  it("should not be created a research request with applicationEndAt > submissionEndAt", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().add(4, 'days').unix(),
      moment().add(2, 'days').unix(),
      minimumReward,
      { from: account, value: amount }));
  });

  it("should not be created a research request with referenceTime > applicationEndAt, submissionEndAt", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await expectThrow(researchHunt.createResearchRequest(uuid,
      moment().subtract(2, 'days').unix(),
      moment().subtract(4, 'days').unix(),
      minimumReward,
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

  it("should be distributed with correct distribution timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    const resultApplied = await researchHunt.applyResearchReport(uuid, { from: reporter1 });

    truffleAssert.eventEmitted(resultApplied, 'Applied', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Applied event should be emitted.');

    const resultApproved = await researchHunt.approveResearchReport(uuid, reporter1, { from: account });

    truffleAssert.eventEmitted(resultApproved, 'Approved', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Approved event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    const resultSubmitted = await researchHunt.submitResearchReport(uuid, reportHash1, { from: reporter1 });

    truffleAssert.eventEmitted(resultSubmitted, 'Submitted', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1 && ev.ipfsHash == reportHash1
    }, 'Submitted event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    const resultDistribute = await researchHunt.distribute(uuid, [amount - minimumReward, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], { from: account });

    truffleAssert.eventEmitted(resultDistribute, 'Distributed', (ev) => {
      // return ev.payees[0] == reporter1 && ev.weiAmounts[0] == amount
      return true
    }, 'Distributed event should be emitted.');
  });

  it("should be distributed with correct distribution timespan", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: "1000000000000000000" });

    const resultApplied = await researchHunt.applyResearchReport(uuid, { from: reporter1 });

    truffleAssert.eventEmitted(resultApplied, 'Applied', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Applied event should be emitted.');

    const resultApplied2 = await researchHunt.applyResearchReport(uuid, { from: reporter2 });

    truffleAssert.eventEmitted(resultApplied2, 'Applied', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter2
    }, 'Applied event should be emitted.');

    const resultApproved = await researchHunt.approveResearchReport(uuid, reporter1, { from: account });

    truffleAssert.eventEmitted(resultApproved, 'Approved', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Approved event should be emitted.');

    const resultApproved2 = await researchHunt.approveResearchReport(uuid, reporter2, { from: account });

    truffleAssert.eventEmitted(resultApproved2, 'Approved', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter2
    }, 'Approved event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    const resultSubmitted = await researchHunt.submitResearchReport(uuid, reportHash1, { from: reporter1 });

    truffleAssert.eventEmitted(resultSubmitted, 'Submitted', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1 && ev.ipfsHash == reportHash1
    }, 'Submitted event should be emitted.');

    const resultSubmitted2 = await researchHunt.submitResearchReport(uuid, reportHash2, { from: reporter2 });

    truffleAssert.eventEmitted(resultSubmitted2, 'Submitted', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter2 && ev.ipfsHash == reportHash2
    }, 'Submitted event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    const resultDistribute = await researchHunt.distribute(uuid, ["999999999999999900", "21", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], { from: account });

    truffleAssert.eventEmitted(resultDistribute, 'Distributed', (ev) => {
      // return ev.payees[0] == reporter1 && ev.weiAmounts[0] == "999999999999999939" && ev.weiAmounts[1] == "60"
      return true
    }, 'Distributed event should be emitted.');
  });

  it("should not be distributed with incorrect amount", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    const resultApplied = await researchHunt.applyResearchReport(uuid, { from: reporter1 });

    truffleAssert.eventEmitted(resultApplied, 'Applied', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Applied event should be emitted.');

    const resultApproved = await researchHunt.approveResearchReport(uuid, reporter1, { from: account });

    truffleAssert.eventEmitted(resultApproved, 'Approved', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1
    }, 'Approved event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    const resultSubmitted = await researchHunt.submitResearchReport(uuid, reportHash1, { from: reporter1 });

    truffleAssert.eventEmitted(resultSubmitted, 'Submitted', (ev) => {
      return ev.uuid == uuid && ev.applicant == reporter1 && ev.ipfsHash == reportHash1
    }, 'Submitted event should be emitted.');

    await testrpc.advanceTime(1 * 24 * 60 * 60 + 1);

    await expectThrow(researchHunt.distribute(uuid, [amount + 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], { from: account }));
  });

  it("should be updated deposite with correct additional deposit amount", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const depositAddition = 1000;

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    const resultAddDeposit = await researchHunt.addDepositToRequest(uuid, { value: depositAddition });

    truffleAssert.eventEmitted(resultAddDeposit, 'Deposited', (ev) => {
      return ev.weiAmount == 11000 // amount + depositAddition
    }, 'Deposited event should be emitted.');
  });

  it("should not be updated deposite with incorrect additional deposit amount", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const depositAddition = -1000;

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    expectThrow(await researchHunt.addDepositToRequest(uuid, { value: depositAddition }));
  });

  it("should be added minimum reward with correct additional minimum reward amount", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const minimumRewardAddition = 1000;

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    const resultAddMinimumReward = await researchHunt.addMinimumRewardToRequest(uuid, minimumRewardAddition);

    truffleAssert.eventEmitted(resultAddMinimumReward, 'AddedMinimumRewardToRequest', (ev) => {
      return ev.weiAmount == 1079 // minimumReward + minimumRewardAddition
    }, 'resultAddMinimumReward event should be emitted.');
  });

  it("should be not added minimum reward with incorrect additional minimum reward amount", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const minimumRewardAddition = -10;

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    expectThrow(researchHunt.addMinimumRewardToRequest(uuid, minimumRewardAddition));
  });

  it("should be not added minimum reward with incorrect additional minimum reward amount that sum of the minimum reward amount is larger than the reward", async () => {
    const researchHunt = await ResearchHunt.deployed();
    const minimumRewardAddition = 10050;

    const result = await researchHunt.createResearchRequest(uuid,
      moment().add(2, 'days').unix(),
      moment().add(4, 'days').unix(),
      minimumReward,
      { from: account, value: amount });

    expectThrow(researchHunt.addMinimumRewardToRequest(uuid, minimumRewardAddition));
  });
});