const Escrow = artifacts.require("escrow");
const ResearchHunt = artifacts.require("research_hunt");

module.exports = async function(deployer) {
  await deployer.deploy(Escrow);
  await deployer.deploy(ResearchHunt, Escrow.address);
};
