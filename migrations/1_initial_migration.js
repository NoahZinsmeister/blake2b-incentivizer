const Incentivizer = artifacts.require("./Incentivizer.sol");

module.exports = function(deployer) {
  deployer.deploy(Incentivizer);
};
