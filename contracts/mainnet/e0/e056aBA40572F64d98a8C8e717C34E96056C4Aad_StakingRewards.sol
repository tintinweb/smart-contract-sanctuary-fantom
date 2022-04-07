// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";
import "./StakingRewardsFactory.sol";

contract StakingRewards is
  IStakingRewards,
  RewardsDistributionRecipient,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardsToken;
  IERC20 public stakingToken;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public rewardsAssigned;
  bool public isInitialized;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _lockingTimeStamp;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken,
    uint256 _rewardsDuration
  ) public {
    require (address(_rewardsDistribution) != address(0), "Address cannot be zero");
    require (address(_rewardsToken) != address(0), "Address cannot be zero");
    require (address(_stakingToken) != address(0), "Address cannot be zero");
    require (address(_stakingToken) != address(_rewardsToken), "Staking token cannot be the same as rewards token");
    require (uint256(_rewardsDuration) <= 31556926, "Rewards duration is too long"); // Sets a limit so that _rewardsDuration cannot be arbitrarily high (1 year limit example)
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IERC20(_stakingToken);
    rewardsDistribution = _rewardsDistribution;
    rewardsDuration = _rewardsDuration;
  }

  function initializeDefault() external 
    onlyRewardsDistribution
    nonReentrant
  {
    require(isInitialized != true);
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);

    rewardRate = rewardsToken.balanceOf(address(this)).div(rewardsDuration);

    isInitialized = true;
    emit DefaultInitialization();
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view override returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view override returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(_totalSupply)
      );
  }

  function earned(address account) public view override returns (uint256) {
    return
      _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view override returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function viewLockingTimeStamp() external view override returns (uint256) {
    return _lockingTimeStamp[msg.sender];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(isInitialized == true, "Vault has not been initialized"); // ADDED POST-AUDIT
    require(amount > 0, "Cannot stake 0");
    require(_lockingTimeStamp[msg.sender] <= 0);
    require(block.timestamp < periodFinish, "Vault is not active"); // ADDED POST-AUDIT
    uint256 balanceBefore = stakingToken.balanceOf(address(this));
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    uint256 balanceAfter = stakingToken.balanceOf(address(this));
    amount = (balanceAfter.sub(balanceBefore));
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    emit Staked(msg.sender, amount);
  }

  function stakeTransferWithBalance(
    uint256 amount,
    uint256 lockingPeriod
  ) 
    external 
    nonReentrant 
    updateReward(msg.sender) 
  {
    require(isInitialized == true, "Vault has not been initialized"); // ADDED POST-AUDIT
    require(amount > 0, "Cannot stake 0");
    require(_balances[msg.sender] <= 0, "Already staked by user");
    require(lockingPeriod <= rewardsDuration, "Invalid locking period"); // lockingPeriod must be less than the _rewardsDuration so that tokens aren't lost
    require(block.timestamp < periodFinish, "Vault is not active"); // ADDED POST-AUDIT
    uint256 balanceBefore = stakingToken.balanceOf(address(this));
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    uint256 balanceAfter = stakingToken.balanceOf(address(this));
    amount = (balanceAfter.sub(balanceBefore));
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    _lockingTimeStamp[msg.sender] = lockingPeriod; // setting user locking ts
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot withdraw 0");

    if (_lockingTimeStamp[msg.sender] > 0) {
      require(
        block.timestamp >= _lockingTimeStamp[msg.sender],
        "Unable to withdraw in locking period"
      );
      _totalSupply = _totalSupply.sub(amount);
      _balances[msg.sender] = _balances[msg.sender].sub(amount);
      stakingToken.safeTransfer(msg.sender, amount);
      emit Withdrawn(msg.sender, amount);
    } else if (_lockingTimeStamp[msg.sender] <= 0) {
      _totalSupply = _totalSupply.sub(amount);
      _balances[msg.sender] = _balances[msg.sender].sub(amount);
      stakingToken.safeTransfer(msg.sender, amount);
      emit Withdrawn(msg.sender, amount);
    }
  }

  function getReward() public override nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsAssigned = rewardsAssigned.sub(reward);
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function quit() external override {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function claimRewardAmount(uint256 reward, uint256 _rewardsDuration)
    external
    override
    onlyRewardsDistribution
    updateReward(address(0))
  {
    require(
      block.timestamp.add(_rewardsDuration) >= periodFinish,
      "Cannot reduce existing period"
    );

    require (
      _rewardsDuration <= 31556926, 
      "Rewards duration is too high"
      ); // Sets a limit so that rewardsDuration cannot be arbitrarily high (1 year limit example)

    require (
      reward > _rewardsDuration,
      "Reward must be greater than rewards duration"
    );

    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(_rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(_rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(
      rewardRate <= balance.sub(rewardsAssigned).div(_rewardsDuration),
      "Provided reward too high"
    );

    rewardsDuration = _rewardsDuration;
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(_rewardsDuration);
    emit RewardAdded(reward, periodFinish);
  }

  function recoverERC20(
      address tokenAddress,
      address to,
      uint256 tokenAmount
  ) external onlyRewardsDistribution {
      require(
          tokenAddress != address(stakingToken),
          'Cannot withdraw the staking token'
      );
      require(
          tokenAddress != address(rewardsToken),
          'Cannot withdraw the rewards token'
      );

      IERC20(tokenAddress).safeTransfer(to, tokenAmount);
      emit Recovered(tokenAddress, to, tokenAmount);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    rewardsAssigned = rewardsAssigned.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate));
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }
}