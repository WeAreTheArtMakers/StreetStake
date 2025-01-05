// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StreetMoney is ERC20, Ownable {
    struct Stake {
        uint256 amount;      // Stake edilen miktar
        uint256 timestamp;   // Stake edilen zaman
    }

    mapping(address => Stake) public stakes;
    uint256 public rewardRate = 500; // %5 ödül
    uint256 public rewardInterval = 30 days;

    event StakeEvent(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawEvent(address indexed user, uint256 stakedAmount, uint256 reward, uint256 timestamp);
    event MintEvent(address indexed to, uint256 amount);
    event BurnEvent(address indexed from, uint256 amount);

    constructor(address initialOwner) ERC20("Street Money", "STREET") Ownable(initialOwner) {
        _mint(initialOwner, 99_910_010_001_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit MintEvent(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit BurnEvent(msg.sender, amount);
    }

    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Stake amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");

        Stake storage userStake = stakes[msg.sender];
        userStake.amount += amount;
        userStake.timestamp = block.timestamp;

        _transfer(msg.sender, address(this), amount);
        emit StakeEvent(msg.sender, amount, block.timestamp);
    }

    function withdrawStake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tokens staked");
        require(block.timestamp >= userStake.timestamp + rewardInterval, "Tokens cannot be withdrawn before staking period");

        uint256 stakedAmount = userStake.amount;
        uint256 reward = calculateReward(msg.sender);

        _mint(msg.sender, reward);
        _transfer(address(this), msg.sender, stakedAmount);

        userStake.amount = 0;
        userStake.timestamp = 0;

        emit WithdrawEvent(msg.sender, stakedAmount, reward, block.timestamp);
    }

    function calculateReward(address staker) public view returns (uint256) {
        Stake memory userStake = stakes[staker];
        uint256 stakingDuration = block.timestamp - userStake.timestamp;

        if (stakingDuration < rewardInterval) {
            return 0;
        }

        uint256 reward = (userStake.amount * rewardRate) / 10000;
        return reward;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
    }

    function setRewardInterval(uint256 newInterval) external onlyOwner {
        rewardInterval = newInterval;
    }
}