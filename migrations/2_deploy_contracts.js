const StakingPool = artifacts.require("StakingPool");
const LockPool = artifacts.require("LockPool");
const AirDropPool = artifacts.require("AirDropPool");
const StakingPoolProxy = artifacts.require("StakingPoolProxy");
const ProxyAdmin = "0xCD9f286BA6A3d2DF7885F4A2Be267Fc524D32bD3";

module.exports = async function (deployer, network) {
    if (network == "bsctest") {
        await deployer.deploy(LockPool);

        const governance = "0x076979a0B3C87334E5d72E3afCaFaa80F7888Cac";
        const govToken = "0x86747b02687AbF8398273F83217aC3AbdefF0076";
        const lockPool = LockPool.address;
        const accrualBlockNumberInterval = 0;
        const initialExchangeRateMantissa = 0.02e18.toString();
        const rewardRate = 1e18.toString();
        const name = "CDTC Power"
        const symbol = "CDTCP";
        await deployer.deploy(StakingPool);
        await deployer.deploy(StakingPoolProxy, StakingPool.address, ProxyAdmin , []);
        const stakingPoolInstance = await StakingPool.at(StakingPoolProxy.address);
        stakingPoolInstance.initialize(governance, govToken, lockPool, accrualBlockNumberInterval, initialExchangeRateMantissa, 
        rewardRate, name, symbol);
        
        const LockPoolInstance = await LockPool.deployed();
        await LockPoolInstance.setStakingPool(StakingPoolProxy.address, govToken);
        await LockPoolInstance.setWithdrawPeriod(180);

        await deployer.deploy(AirDropPool, "CDTC Airdrop", govToken, StakingPool.address, 604800);
    }
};
