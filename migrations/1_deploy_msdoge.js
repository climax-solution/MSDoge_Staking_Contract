const MSDoge = artifacts.require("MSDoge");

const owner = "0x0438a66454c8f41eBE20a7691f5437A6985782d2";

module.exports = function (deployer) {
  deployer.deploy(MSDoge, owner);
};
