const Staking = artifacts.require("Staking");
const MSDOGE = artifacts.require("MSDoge");
const XMSDOGE = artifacts.require("XMSDoge");

const _stakingToken = MSDOGE.address;
const _rewardsToken = XMSDOGE.address;
const _rewardRate = 8;

module.exports = function (deployer) {
  deployer.deploy(Staking, _stakingToken, _rewardsToken, _rewardRate);
};
