/**
 *Submitted for verification at FtmScan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

interface erc20 {
  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);
}

interface ve {
  function token() external view returns (address);

  function balanceOfNFT(uint256) external view returns (uint256);

  function isApprovedOrOwner(address, uint256) external view returns (bool);

  function ownerOf(uint256) external view returns (address);

  function transferFrom(
    address,
    address,
    uint256
  ) external;

  function attach(uint256, address) external;

  function detach(uint256, address) external;
}

contract LPIncentive {
  address public immutable stake; // the LP token that needs to be staked for rewards
  address public immutable _ve; // the ve token used for gauges
  address public rewardToken; // incentive token

  uint256 internal constant DURATION = 14 days;
  uint256 internal constant PRECISION = 10**18;

  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public periodFinish;

  uint256 public rewardRate;

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;

  uint256 public derivedSupply;
  mapping(address => uint256) public derivedBalances;

  mapping(address => uint256) public tokenIds;

  mapping(address => uint256) public lastEarn;
  mapping(address => uint256) public userRewardPerTokenStored;

  /// @notice A checkpoint for marking balance
  struct Checkpoint {
    uint256 timestamp;
    uint256 balanceOf;
  }

  /// @notice A checkpoint for marking reward rate
  struct RewardPerTokenCheckpoint {
    uint256 timestamp;
    uint256 rewardPerToken;
  }

  /// @notice A checkpoint for marking supply
  struct SupplyCheckpoint {
    uint256 timestamp;
    uint256 supply;
  }

  /// @notice The number of checkpoints
  uint256 public supplyNumCheckpoints;
  /// @notice A record of balance checkpoints for each token, by index
  mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;
  /// @notice The number of checkpoints for each token
  uint256 public rewardPerTokenNumCheckpoints;
  mapping(uint256 => RewardPerTokenCheckpoint) public rewardPerTokenCheckpoints;
  /// @notice The number of checkpoints for each account
  mapping(address => uint256) public numCheckpoints;
  /// @notice A record of balance checkpoints for each account, by index
  mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

  event Deposit(address indexed from, uint256 tokenId, uint256 amount);
  event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
  event ClaimRewards(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
  event NotifyReward(
    address indexed from,
    address indexed reward,
    uint256 amount
  );

  // simple re-entrancy check
  uint256 internal _unlocked = 1;
  modifier lock() {
    require(_unlocked == 1);
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

  constructor(
    address _stake,
    address __ve,
    address _token
  ) {
    stake = _stake;
    _ve = __ve;
    rewardToken = _token;
  }

  function _updateRewardPerToken() internal returns (uint256, uint256) {
    uint256 _startTimestamp = lastUpdateTime;
    uint256 reward = rewardPerTokenStored;

    if (supplyNumCheckpoints == 0) {
      return (reward, _startTimestamp);
    }

    if (rewardRate == 0) {
      return (reward, block.timestamp);
    }

    uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
    uint256 _endIndex = supplyNumCheckpoints - 1;

    if (_endIndex - _startIndex > 1) {
      for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
        SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
        if (sp0.supply > 0) {
          SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
          (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
            sp1.timestamp,
            sp0.timestamp,
            sp0.supply,
            _startTimestamp
          );
          reward += _reward;
          _writeRewardPerTokenCheckpoint(reward, _endTime);
          _startTimestamp = _endTime;
        }
      }
    }

    SupplyCheckpoint memory sp = supplyCheckpoints[_endIndex];
    if (sp.supply > 0) {
      (uint256 _reward, ) = _calcRewardPerToken(
        lastTimeRewardApplicable(),
        Math.max(sp.timestamp, _startTimestamp),
        sp.supply,
        _startTimestamp
      );
      reward += _reward;
      _writeRewardPerTokenCheckpoint(reward, block.timestamp);
      _startTimestamp = block.timestamp;
    }

    return (reward, _startTimestamp);
  }

  function _calcRewardPerToken(
    uint256 timestamp1,
    uint256 timestamp0,
    uint256 supply,
    uint256 startTimestamp
  ) internal view returns (uint256, uint256) {
    uint256 endTime = Math.max(timestamp1, startTimestamp);
    return (
      (((Math.min(endTime, periodFinish) -
        Math.min(Math.max(timestamp0, startTimestamp), periodFinish)) *
        rewardRate *
        PRECISION) / supply),
      endTime
    );
  }

  function _writeRewardPerTokenCheckpoint(uint256 reward, uint256 timestamp)
    internal
  {
    uint256 _nCheckPoints = rewardPerTokenNumCheckpoints;

    if (
      _nCheckPoints > 0 &&
      rewardPerTokenCheckpoints[_nCheckPoints - 1].timestamp == timestamp
    ) {
      rewardPerTokenCheckpoints[_nCheckPoints - 1].rewardPerToken = reward;
    } else {
      rewardPerTokenCheckpoints[_nCheckPoints] = RewardPerTokenCheckpoint(
        timestamp,
        reward
      );
      rewardPerTokenNumCheckpoints = _nCheckPoints + 1;
    }
  }

  // returns the last time the reward was modified or periodFinish if the reward has ended
  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function getPriorSupplyIndex(uint256 timestamp)
    public
    view
    returns (uint256)
  {
    uint256 nCheckpoints = supplyNumCheckpoints;
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
      return (nCheckpoints - 1);
    }

    // Next check implicit zero balance
    if (supplyCheckpoints[0].timestamp > timestamp) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      SupplyCheckpoint memory cp = supplyCheckpoints[center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

  function depositAll(uint256 tokenId) external {
    deposit(erc20(stake).balanceOf(msg.sender), tokenId);
  }

  function deposit(uint256 amount, uint256 tokenId) public lock {
    require(amount > 0);

    (rewardPerTokenStored, lastUpdateTime) = _updateRewardPerToken();

    _safeTransferFrom(stake, msg.sender, address(this), amount);
    totalSupply += amount;
    balanceOf[msg.sender] += amount;

    if (tokenId > 0) {
      require(ve(_ve).ownerOf(tokenId) == msg.sender, "Only your ve");
      if (tokenIds[msg.sender] == 0) {
        tokenIds[msg.sender] = tokenId;
        ve(_ve).attach(tokenId, msg.sender);
      }
      require(tokenIds[msg.sender] == tokenId, "Cant change ve");
    } else {
      tokenId = tokenIds[msg.sender];
    }

    uint256 _derivedBalance = derivedBalances[msg.sender];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(msg.sender);
    derivedBalances[msg.sender] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(msg.sender, _derivedBalance);
    _writeSupplyCheckpoint();

    emit Deposit(msg.sender, tokenId, amount);
  }

  function _writeCheckpoint(address account, uint256 balance) internal {
    uint256 _timestamp = block.timestamp;
    uint256 _nCheckPoints = numCheckpoints[account];

    if (
      _nCheckPoints > 0 &&
      checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp
    ) {
      checkpoints[account][_nCheckPoints - 1].balanceOf = balance;
    } else {
      checkpoints[account][_nCheckPoints] = Checkpoint(_timestamp, balance);
      numCheckpoints[account] = _nCheckPoints + 1;
    }
  }

  function _writeSupplyCheckpoint() internal {
    uint256 _nCheckPoints = supplyNumCheckpoints;
    uint256 _timestamp = block.timestamp;

    if (
      _nCheckPoints > 0 &&
      supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp
    ) {
      supplyCheckpoints[_nCheckPoints - 1].supply = derivedSupply;
    } else {
      supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(
        _timestamp,
        derivedSupply
      );
      supplyNumCheckpoints = _nCheckPoints + 1;
    }
  }

  function derivedBalance(address account) public view returns (uint256) {
    uint256 _tokenId = tokenIds[account];
    uint256 _balance = balanceOf[account];
    uint256 _derived = (_balance * 40) / 100;
    uint256 _adjusted = 0;
    uint256 _supply = erc20(_ve).totalSupply();
    if (account == ve(_ve).ownerOf(_tokenId) && _supply > 0) {
      _adjusted = ve(_ve).balanceOfNFT(_tokenId);
      _adjusted = (((totalSupply * _adjusted) / _supply) * 60) / 100;
    }
    return Math.min((_derived + _adjusted), _balance);
  }

  function _safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    require(token.code.length > 0);
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function withdrawAll() external {
    withdraw(balanceOf[msg.sender]);
  }

  function withdraw(uint256 amount) public {
    uint256 tokenId = 0;
    if (amount == balanceOf[msg.sender]) {
      tokenId = tokenIds[msg.sender];
    }
    withdrawToken(amount, tokenId);
  }

  function withdrawToken(uint256 amount, uint256 tokenId) public lock {
    totalSupply -= amount;
    balanceOf[msg.sender] -= amount;
    _safeTransfer(stake, msg.sender, amount);

    if (tokenId > 0) {
      require(tokenId == tokenIds[msg.sender]);
      tokenIds[msg.sender] = 0;
      ve(_ve).detach(tokenId, msg.sender);
    } else {
      tokenId = tokenIds[msg.sender];
    }

    uint256 _derivedBalance = derivedBalances[msg.sender];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(msg.sender);
    derivedBalances[msg.sender] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(msg.sender, derivedBalances[msg.sender]);
    _writeSupplyCheckpoint();

    emit Withdraw(msg.sender, tokenId, amount);
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    require(token.code.length > 0);
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(erc20.transfer.selector, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function getReward(address account) external lock {
    require(msg.sender == account);

    (rewardPerTokenStored, lastUpdateTime) = _updateRewardPerToken();

    uint256 _reward = earned(account);
    lastEarn[account] = block.timestamp;
    userRewardPerTokenStored[account] = rewardPerTokenStored;
    if (_reward > 0) _safeTransfer(rewardToken, account, _reward);

    emit ClaimRewards(msg.sender, rewardToken, _reward);

    uint256 _derivedBalance = derivedBalances[account];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(account);
    derivedBalances[account] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(account, derivedBalances[account]);
    _writeSupplyCheckpoint();
  }

  // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
  function earned(address account) public view returns (uint256) {
    uint256 _startTimestamp = Math.max(
      lastEarn[account],
      rewardPerTokenCheckpoints[0].timestamp
    );
    if (numCheckpoints[account] == 0) {
      return 0;
    }

    uint256 _startIndex = getPriorBalanceIndex(account, _startTimestamp);
    uint256 _endIndex = numCheckpoints[account] - 1;

    uint256 reward = 0;

    if (_endIndex - _startIndex > 1) {
      for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
        Checkpoint memory cp0 = checkpoints[account][i];
        Checkpoint memory cp1 = checkpoints[account][i + 1];
        (uint256 _rewardPerTokenStored0, ) = getPriorRewardPerToken(
          cp0.timestamp
        );
        (uint256 _rewardPerTokenStored1, ) = getPriorRewardPerToken(
          cp1.timestamp
        );
        reward +=
          (cp0.balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0)) /
          PRECISION;
      }
    }

    Checkpoint memory cp = checkpoints[account][_endIndex];
    (uint256 _rewardPerTokenStored, ) = getPriorRewardPerToken(cp.timestamp);
    reward +=
      (cp.balanceOf *
        (rewardPerToken() -
          Math.max(_rewardPerTokenStored, userRewardPerTokenStored[account]))) /
      PRECISION;

    return reward;
  }

  function getPriorRewardPerToken(uint256 timestamp)
    public
    view
    returns (uint256, uint256)
  {
    uint256 nCheckpoints = rewardPerTokenNumCheckpoints;
    if (nCheckpoints == 0) {
      return (0, 0);
    }

    // First check most recent balance
    if (rewardPerTokenCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
      return (
        rewardPerTokenCheckpoints[nCheckpoints - 1].rewardPerToken,
        rewardPerTokenCheckpoints[nCheckpoints - 1].timestamp
      );
    }

    // Next check implicit zero balance
    if (rewardPerTokenCheckpoints[0].timestamp > timestamp) {
      return (0, 0);
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      RewardPerTokenCheckpoint memory cp = rewardPerTokenCheckpoints[center];
      if (cp.timestamp == timestamp) {
        return (cp.rewardPerToken, cp.timestamp);
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return (
      rewardPerTokenCheckpoints[lower].rewardPerToken,
      rewardPerTokenCheckpoints[lower].timestamp
    );
  }

  function rewardPerToken() public view returns (uint256) {
    if (derivedSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored +
      (((lastTimeRewardApplicable() - Math.min(lastUpdateTime, periodFinish)) *
        rewardRate *
        PRECISION) / derivedSupply);
  }

  /**
   * @notice Determine the prior balance for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param timestamp The timestamp to get the balance at
   * @return The balance the account had as of the given block
   */
  function getPriorBalanceIndex(address account, uint256 timestamp)
    public
    view
    returns (uint256)
  {
    uint256 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp) {
      return (nCheckpoints - 1);
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].timestamp > timestamp) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

  function left() external view returns (uint256) {
    if (block.timestamp >= periodFinish) return 0;
    uint256 _remaining = periodFinish - block.timestamp;
    return _remaining * rewardRate;
  }

  function batchRewardPerToken(uint256 maxRuns) external {
    (rewardPerTokenStored, lastUpdateTime) = _batchRewardPerToken(maxRuns);
  }

  function _batchRewardPerToken(uint256 maxRuns)
    internal
    returns (uint256, uint256)
  {
    uint256 _startTimestamp = lastUpdateTime;
    uint256 reward = rewardPerTokenStored;

    if (supplyNumCheckpoints == 0) {
      return (reward, _startTimestamp);
    }

    if (rewardRate == 0) {
      return (reward, block.timestamp);
    }

    uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
    uint256 _endIndex = Math.min(supplyNumCheckpoints - 1, maxRuns);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
      if (sp0.supply > 0) {
        SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
        (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
          sp1.timestamp,
          sp0.timestamp,
          sp0.supply,
          _startTimestamp
        );
        reward += _reward;
        _writeRewardPerTokenCheckpoint(reward, _endTime);
        _startTimestamp = _endTime;
      }
    }

    return (reward, _startTimestamp);
  }

  function notifyRewardAmount(uint256 amount) external lock {
    require(amount > 0);
    if (rewardRate == 0) _writeRewardPerTokenCheckpoint(0, block.timestamp);

    (rewardPerTokenStored, lastUpdateTime) = _updateRewardPerToken();

    if (block.timestamp >= periodFinish) {
      _safeTransferFrom(rewardToken, msg.sender, address(this), amount);
      rewardRate = amount / DURATION;
    } else {
      uint256 _remaining = periodFinish - block.timestamp;
      uint256 _left = _remaining * rewardRate;
      require(amount > _left);
      _safeTransferFrom(rewardToken, msg.sender, address(this), amount);
      rewardRate = (amount + _left) / DURATION;
    }

    require(rewardRate > 0);

    uint256 balance = erc20(rewardToken).balanceOf(address(this));
    require(rewardRate <= balance / DURATION, "Provided reward too high");

    periodFinish = block.timestamp + DURATION;

    emit NotifyReward(msg.sender, rewardToken, amount);
  }
}