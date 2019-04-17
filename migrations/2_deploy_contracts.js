const ResearchHunt = artifacts.require("research_hunt");

module.exports = async function(deployer) {
  await deployer.deploy(ResearchHunt);
};
