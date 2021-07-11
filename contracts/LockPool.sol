// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LockPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public govToken;
    uint256 public withdrawPeriod = 60 * 60 * 168;
    address public daoPool;

    struct WithDrawEntity {
        uint256 amount;
        uint256 time;
    }

    mapping (address => WithDrawEntity) private withdrawEntities;

    modifier onlyDaoPool() {
        require(msg.sender == daoPool, "Not dao pool");
        _;
    }

    function setDaoPool(address _pool, address _govToken) external onlyOwner {
        require(_pool != address(0) && _govToken != address(0), "dao pool and token address shouldn't be empty");
        daoPool = _pool;
        govToken = IERC20(_govToken);
    }

    function setWithdrawPeriod(uint256 _withdrawPeriod) external onlyOwner {
        withdrawPeriod = _withdrawPeriod;
    }

    function lock(address account, uint256 amount) external onlyDaoPool {
        withdrawEntities[account].amount = withdrawEntities[account].amount.add(amount);
        withdrawEntities[account].time = block.timestamp;
        govToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address account, uint256 amount) external onlyDaoPool {
        _withdraw(account, amount);
    }

    function withdrawBySender(uint256 amount) public {
        _withdraw(msg.sender, amount);
    }

    function _withdraw(address account, uint256 amount) private {
        require(withdrawEntities[account].amount > 0 && withdrawEntities[account].time > 0, "not applied!");
        require(block.timestamp >= withdrawTime(account), "It's not time to withdraw");
        if (amount > withdrawEntities[account].amount) {
            amount = withdrawEntities[account].amount;
        }
        withdrawEntities[account].amount = withdrawEntities[account].amount.sub(amount);
        if (withdrawEntities[account].amount == 0) {
            withdrawEntities[account].time = 0;
        }

        govToken.safeTransfer(account, amount);
    }

    function lockedBalance(address account) external view returns (uint256) {
        return withdrawEntities[account].amount;
    }

    function withdrawTime(address account) public view returns (uint256) {
        return withdrawEntities[account].time.add(withdrawPeriod);
    }

}
