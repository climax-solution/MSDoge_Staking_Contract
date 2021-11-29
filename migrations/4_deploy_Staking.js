const Staking = artifacts.require("Staking");
const MSDOGE = artifacts.require("MSDoge");
const LORIA = artifacts.require("CRYPTOLORIA");
const XMSDOGE = artifacts.require("XMSDoge");

const _stakingToken = MSDOGE.address;
const _rewardsToken = XMSDOGE.address;
const _loriaToken = LORIA.address;
const _rewardRate = 8;

module.exports = function (deployer) {
  deployer.deploy(Staking, _stakingToken, _loriaToken, _rewardsToken);
};
