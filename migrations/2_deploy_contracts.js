const StakingPool = artifacts.require("StakingPool");
const LockPool = artifacts.require("LockPool");
const AirDropPool = artifacts.require("AirDropPool");
const StakingPoolProxy = artifacts.require("StakingPoolProxy");
const ProxyAdmin = "0x5F0d8B2A98fB6eC4Bf324a58821ef1937108fcc0";

module.exports = async function (deployer, network, accounts) {
    let governance = accounts[0];
    let govToken = "0x0fAf802036E30B4b58a20C359012821152872397"; // CDTC Token
    let accrualBlockNumberInterval = 0;
    let rewardRate = 0;
    let withdrawPeriod = 259200; // 3 days
    const name = "CDTC Power"
    const symbol = "CDTCP";
    const initialExchangeRateMantissa = 0.02e18.toString();
    if (network == "bsctest") {
        governance = "0x076979a0B3C87334E5d72E3afCaFaa80F7888Cac";
        govToken = "0x86747b02687AbF8398273F83217aC3AbdefF0076";
        rewardRate = 1e18.toString();
        withdrawPeriod = 180;
    }
    await deployer.deploy(LockPool);
    const lockPool = LockPool.address;
    await deployer.deploy(StakingPool);
    await deployer.deploy(StakingPoolProxy, StakingPool.address, ProxyAdmin , []);
    const stakingPoolInstance = await StakingPool.at(StakingPoolProxy.address);
    stakingPoolInstance.initialize(governance, govToken, lockPool, accrualBlockNumberInterval, initialExchangeRateMantissa, 
    rewardRate, name, symbol);
        
    const LockPoolInstance = await LockPool.deployed();
    await LockPoolInstance.setStakingPool(StakingPoolProxy.address, govToken);
    await LockPoolInstance.setWithdrawPeriod(withdrawPeriod);
    await deployer.deploy(AirDropPool, "CDTC Airdrop", govToken, StakingPoolProxy.address, 604800);
};
