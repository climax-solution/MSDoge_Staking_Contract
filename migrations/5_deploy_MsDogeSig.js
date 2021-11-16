const MsDogeSig = artifacts("MsDogeSig");
const MSDoge = artifacts("MSDoge");
const tokenAddress = MSDoge.address;

module.exports = function deploy(deployer, account, networks) {
    deployer.deploy(MsDogeSig, account, tokenAddress);
}