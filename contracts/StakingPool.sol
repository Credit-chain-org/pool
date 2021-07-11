// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./LockPool.sol";

contract StakingPool is ERC20Snapshot {
    uint256 internal initialExchangeRateMantissa;
    uint256 public accrualBlockNumber;
    uint256 public totalBalance;
    uint256 public rewardRate;
    address public govToken;
    address public governance;
    LockPool public lockPool;

    uint256 public currentSnapshotId;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event RewardRateChanged(address byWho, uint from, uint to);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount);

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    constructor(address _governance, address _govToken, address _lockPool, uint256 _accrualBlockNumberInterval, uint256 initialExchangeRateMantissa_, uint256 rewardRate_, string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
        governance = _governance;
        govToken = _govToken;
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        rewardRate = rewardRate_;
        _setAccrualBlockNumber(_accrualBlockNumberInterval);
        lockPool = LockPool(_lockPool);
    }

    function _setAccrualBlockNumber(uint _accrualBlockNumberInterval) public onlyGovernance {
        accrualBlockNumber = block.number + _accrualBlockNumberInterval;
    }

    function _setRewardRate(uint _rewardRate) public onlyGovernance {
        uint previousRewardRate = rewardRate;
        uint newRewardRate = _rewardRate;

        rewardRate = newRewardRate;

        emit RewardRateChanged(msg.sender, previousRewardRate, newRewardRate);
    }

    function getExchangeRate() public view returns(uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return initialExchangeRateMantissa;
        } else {
            uint256 exchangeRate = totalBalance.mul(1e18).div(_totalSupply);
            return exchangeRate;
        }
    }

    function exchangeRateCurrent() public returns (uint256) {
        updateRewards();
        return getExchangeRate();
    }

    function balanceOfUnderlying(address owner) external returns (uint256) {
        uint256 exchangeRate = exchangeRateCurrent();
        uint256 balance = exchangeRate.mul(balanceOf(owner)).div(1e18);
        return balance;
    }

    function updateRewards() public {
        uint256 currentBlockNumber = block.number;
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return;
        }

        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);
        uint256 rewardsAccumulated = rewardRate.mul(blockDelta);
        totalBalance = totalBalance.add(rewardsAccumulated);
        accrualBlockNumber = currentBlockNumber;
    }

    function stake(uint256 amount) public {
        updateRewards();

        uint256 currentExchangeRate = getExchangeRate();

        IERC20 token = IERC20(govToken);
        token.safeTransferFrom(msg.sender, address(this), amount);

        totalBalance = totalBalance.add(amount);

        uint256 daoTokens = amount.mul(1e18).div(currentExchangeRate);

        super._mint(msg.sender, daoTokens);

        emit Staked(msg.sender, amount);
    }

    function requestUnstake(uint256 tokensAmount) external {
        updateRewards();
        uint256 currentExchangeRate = getExchangeRate();
        uint256 unstakeAmount = tokensAmount.mul(currentExchangeRate).div(1e18);
        totalBalance = totalBalance.sub(unstakeAmount);
        super._burn(msg.sender, tokensAmount);

        IERC20 token = IERC20(govToken);
        token.approve(address(lockPool), unstakeAmount);
        lockPool.lock(msg.sender, unstakeAmount);

        emit UnstakeRequested(msg.sender, unstakeAmount);
    }

    function withdraw() public {
        uint256 amount = lockPool.lockedBalance(msg.sender);
        lockPool.withdraw(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function withdrawTime() view public returns(uint256) {
        return lockPool.withdrawTime(msg.sender);
    }

    function snapshot() external onlyGovernance returns (uint256) {
        currentSnapshotId = _snapshot();
        return currentSnapshotId;
    }

    function setGovernance(address newAdmin) public onlyGovernance {
        governance = newAdmin;
    }
}