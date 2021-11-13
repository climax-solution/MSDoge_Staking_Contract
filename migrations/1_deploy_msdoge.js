const MSDoge = artifacts.require("MS Doge");

module.exports = function (deployer) {
  deployer.deploy(MSDoge,{value: 0, });
};
