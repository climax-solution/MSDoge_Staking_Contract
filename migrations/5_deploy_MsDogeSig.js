const MsDogeSig = artifacts.require("MsDogeSig");
const MSDoge = artifacts.require("MSDoge");
const tokenAddress = MSDoge.address;
const owner = "0x80f513B3f78496ade0c63Cde94a7cce3A080C383";
module.exports = function deploy(deployer, account, networks) {
    deployer.deploy(MsDogeSig, owner, tokenAddress);
}