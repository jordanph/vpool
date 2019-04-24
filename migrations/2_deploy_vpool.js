const VPool = artifacts.require("VPool");

module.exports = function(deployer) {
  deployer.deploy(VPool, "0x0000000000000000000000000000456e65726779", "0xB74C4EBd95F70Dd9794d8c49053a297689950b63", "0xB74C4EBd95F70Dd9794d8c49053a297689950b63");
};
