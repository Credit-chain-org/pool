const StakingPool = artifacts.require("StakingPool");
const LockPool = artifacts.require("LockPool");
const AirDropPool = artifacts.require("AirDropPool");

module.exports = async function (deployer, network) {
    if (network == "bsctest") {
        await deployer.deploy(LockPool);

        const governance = "0x076979a0B3C87334E5d72E3afCaFaa80F7888Cac";
        const govToken = "0x86747b02687AbF8398273F83217aC3AbdefF0076";
        const lockPool = LockPool.address;
        const accrualBlockNumberInterval = 0;
        const initialExchangeRateMantissa = 0.02e18.toString();
        const rewardRate = 1e18.toString();
        const name = "DTCT Power"
        const symbol = "DTCTP";
        await deployer.deploy(StakingPool, governance, govToken, lockPool, accrualBlockNumberInterval, initialExchangeRateMantissa, 
            rewardRate, name, symbol);
        
        const LockPoolInstance = await LockPool.deployed();
        await LockPoolInstance.setDaoPool(StakingPool.address, govToken);
        await deployer.deploy(AirDropPool, "DTCT Airdrop", govToken, StakingPool.address, 604800);
    }
};
