const MSDoge = artifacts.require("MSDoge");

const owner = "0x80f513B3f78496ade0c63Cde94a7cce3A080C383";

module.exports = function (deployer) {
  deployer.deploy(MSDoge, owner);
};
