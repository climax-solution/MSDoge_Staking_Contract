const MsDogeSig = artifacts.require("MsDogeSig");
const MSDoge = artifacts.require("MSDoge");
const tokenAddress = MSDoge.address;

module.exports = function deploy(deployer, account, networks) {
    deployer.deploy(MsDogeSig, account, tokenAddress);
}