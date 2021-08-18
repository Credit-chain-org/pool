// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

import "./Governable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract AirDropPool is Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    IERC20 public rewardToken;
    IERC20 public stakePowerToken;
    uint256 public duration;

    uint256 public totalSupply;
    uint256 public periodFinish = 0;
    bool public checkStake;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public airDropAmount;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event NeedToCheckStake(bool checkRequired);

    constructor(string memory _name,
                address _rewardToken,
                address _stakePowerToken,
                uint256 _duration) public
    Governable(msg.sender) {
        name = _name;
        rewardToken = IERC20(_rewardToken);
        stakePowerToken = IERC20(_stakePowerToken);
        duration = _duration;
    }

    function earned(address account) public view returns (uint256) {
        if (msg.sender != tx.origin) return 0;
        if (rewards[account] != 0) return 0;
        return airDropAmount[account];
    }

    function withdraw() public {
        require(msg.sender == tx.origin, "Only human allow to get reward");
        require(block.timestamp <= periodFinish, "Only allow to get reward in open time");
        require(!checkState || stakePowerToken.balanceOf(msg.sender) > 0, "Only staking user can withdraw airdrop token");

        uint256 reward = earned(msg.sender);
        require(reward > 0, "No enough reward to get");

        rewards[msg.sender] = reward;
        rewardToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function setAirDropAmount(address[] memory userList, uint256[] memory amount) external onlyGovernance {
        require(userList.length == amount.length, "Inconsistent length");

        for (uint256 i = 0; i < userList.length; i++) {
            airDropAmount[userList[i]] = amount[i];
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyGovernance {
        if (reward == 0) {
            totalSupply = rewardToken.balanceOf(address(this));
        } else {
            totalSupply = totalSupply.add(reward);
            rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        }
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    function withdrawAdmin(uint256 amount) external onlyGovernance {
        require(block.timestamp > periodFinish, "Only allow admin to withdraw after reward expired.");

        uint256 transferAmount = amount;
        if (amount == 0) {
            transferAmount = rewardToken.balanceOf(address(this));
        }
        rewardToken.safeTransfer(msg.sender, transferAmount);
        emit Withdrawn(msg.sender, amount);
    }

    function flipCheckState() external onlyGovernance {
        checkStake = !checkStake;
        emit NeedToCheckStake(checkStake);
    }
}