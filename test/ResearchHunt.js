const ResearchHunt = artifacts.require("research_hunt");
const truffleAssert = require('truffle-assertions');

const { expectThrow } = require('./helpers/expectThrow');


contract("ResearchHunt", ([account, payee]) => {
  it("should be able to create ResearchRequest.", async () => {
    const researchHunt = await ResearchHunt.deployed();

    await researchHunt.createResearchRequest({from: account});
    await researchHunt.createResearchRequest({from: account});
    var result = await researchHunt.createResearchRequest({from: account});

    truffleAssert.eventEmitted(result, 'RequestCreated', (ev) => {
      return ev.owner == account && ev.count == 2
    }, 'RequestCreated event should be emitted.');
  });
});
