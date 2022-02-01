/**
 *Submitted for verification at FtmScan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface ve {
    function token() external view returns (address);
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
}

interface IBaseV1Factory {
    function isPair(address) external view returns (bool);
}

interface IBaseV1Core {
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
}

interface IBaseV1GaugeFactory {
    function createGauge(address, address, address) external returns (address);
}

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
}

// Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with BaseV1Gauges.vote())
contract Bribe {

    address public immutable factory; // only factory can modify balances (since it only happens on vote())
    address public immutable _ve;

    uint public constant DURATION = 7 days; // rewards are released over 7 days
    uint public constant PRECISION = 10 ** 18;

    // default snx staking contract implementation
    mapping(address => uint) public rewardRate;
    mapping(address => uint) public periodFinish;
    mapping(address => uint) public lastUpdateTime;
    mapping(address => uint) public rewardPerTokenStored;

    mapping(address => mapping(uint => uint)) public lastEarn;
    mapping(address => mapping(uint => uint)) public userRewardPerTokenStored;
    mapping(address => mapping(uint => uint)) public userRewards;

    address[] public rewards;
    mapping(address => bool) public isReward;

    event Deposit(address indexed from, uint tokenId, uint amount);
    event Withdraw(address indexed from, uint tokenId, uint amount);
    event NotifyReward(address indexed from, address indexed reward, uint amount);
    event ClaimRewards(address indexed from, address indexed reward, uint amount);

    uint public totalSupply;
    mapping(uint => uint) public balanceOf;

    /// @notice A checkpoint for marking balance
   struct Checkpoint {
       uint timestamp;
       uint balanceOf;
   }

  /// @notice A checkpoint for marking reward rate
 struct RewardPerTokenCheckpoint {
     uint timestamp;
     uint rewardPerToken;
 }

  /// @notice A checkpoint for marking supply
 struct SupplyCheckpoint {
     uint timestamp;
     uint supply;
 }

   /// @notice A record of balance checkpoints for each account, by index
   mapping (uint => mapping (uint => Checkpoint)) public checkpoints;

   /// @notice The number of checkpoints for each account
   mapping (uint => uint) public numCheckpoints;

   /// @notice A record of balance checkpoints for each token, by index
   mapping (uint => SupplyCheckpoint) public supplyCheckpoints;

   /// @notice The number of checkpoints
   uint public supplyNumCheckpoints;

   /// @notice A record of balance checkpoints for each token, by index
   mapping (address => mapping (uint => RewardPerTokenCheckpoint)) public rewardPerTokenCheckpoints;

   /// @notice The number of checkpoints for each token
   mapping (address => uint) public rewardPerTokenNumCheckpoints;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
        _ve = BaseV1Voter(msg.sender)._ve();
    }

    /**
     * @notice Determine the prior balance for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param tokenId The token of the NFT to check
     * @param timestamp The timestamp to get the balance at
     * @return The balance the account had as of the given block
     */
    function getPriorBalanceIndex(uint tokenId, uint timestamp) public view returns (uint) {
        uint nCheckpoints = numCheckpoints[tokenId];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[tokenId][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (checkpoints[tokenId][0].timestamp > timestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenId][center];
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

    function getPriorSupplyIndex(uint timestamp) public view returns (uint) {
        uint nCheckpoints = supplyNumCheckpoints;
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

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function getPriorRewardPerToken(address token, uint timestamp) public view returns (uint, uint) {
        uint nCheckpoints = rewardPerTokenNumCheckpoints[token];
        if (nCheckpoints == 0) {
            return (0,0);
        }

        // First check most recent balance
        if (rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp <= timestamp) {
            return (rewardPerTokenCheckpoints[token][nCheckpoints - 1].rewardPerToken, rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp);
        }

        // Next check implicit zero balance
        if (rewardPerTokenCheckpoints[token][0].timestamp > timestamp) {
            return (0,0);
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            RewardPerTokenCheckpoint memory cp = rewardPerTokenCheckpoints[token][center];
            if (cp.timestamp == timestamp) {
                return (cp.rewardPerToken, cp.timestamp);
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return (rewardPerTokenCheckpoints[token][lower].rewardPerToken, rewardPerTokenCheckpoints[token][lower].timestamp);
    }

    function _writeCheckpoint(uint tokenId, uint balance) internal {
      uint _timestamp = block.timestamp;
      uint _nCheckPoints = numCheckpoints[tokenId];

      if (_nCheckPoints > 0 && checkpoints[tokenId][_nCheckPoints - 1].timestamp == _timestamp) {
          checkpoints[tokenId][_nCheckPoints - 1].balanceOf = balance;
      } else {
          checkpoints[tokenId][_nCheckPoints] = Checkpoint(_timestamp, balance);
          numCheckpoints[tokenId] = _nCheckPoints + 1;
      }
    }

    function _writeRewardPerTokenCheckpoint(address token, uint reward, uint timestamp) internal {
      uint _nCheckPoints = rewardPerTokenNumCheckpoints[token];

      if (_nCheckPoints > 0 && rewardPerTokenCheckpoints[token][_nCheckPoints - 1].timestamp == timestamp) {
        rewardPerTokenCheckpoints[token][_nCheckPoints - 1].rewardPerToken = reward;
      } else {
          rewardPerTokenCheckpoints[token][_nCheckPoints] = RewardPerTokenCheckpoint(timestamp, reward);
          rewardPerTokenNumCheckpoints[token] = _nCheckPoints + 1;
      }
    }

    function _writeSupplyCheckpoint() internal {
      uint _nCheckPoints = supplyNumCheckpoints;
      uint _timestamp = block.timestamp;

      if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
        supplyCheckpoints[_nCheckPoints - 1].supply = totalSupply;
      } else {
          supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, totalSupply);
          supplyNumCheckpoints = _nCheckPoints + 1;
      }
    }

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token) public view returns (uint) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    function batchUserRewards(address token, uint tokenId, uint maxRuns) external {
        (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token);
        (userRewards[token][tokenId], lastEarn[token][tokenId]) = _batchUserRewards(token, tokenId, maxRuns);
    }

    // allows a user to claim rewards for a given token
    function getReward(uint tokenId, address[] memory tokens) external lock  {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
        for (uint i = 0; i < tokens.length; i++) {
            (rewardPerTokenStored[tokens[i]], lastUpdateTime[tokens[i]]) = _updateRewardPerToken(tokens[i]);

            uint _reward = earned(tokens[i], tokenId);
            userRewards[tokens[i]][tokenId] = 0;
            lastEarn[tokens[i]][tokenId] = block.timestamp;
            userRewardPerTokenStored[tokens[i]][tokenId] = rewardPerTokenStored[tokens[i]];
            if (_reward > 0) _safeTransfer(tokens[i], msg.sender, _reward);

            emit ClaimRewards(msg.sender, tokens[i], _reward);
        }
    }

    // used by BaseV1Voter to allow batched reward claims
    function getRewardForOwner(uint tokenId, address[] memory tokens) external lock  {
        require(msg.sender == factory);
        address _owner = ve(_ve).ownerOf(tokenId);
        for (uint i = 0; i < tokens.length; i++) {
            (rewardPerTokenStored[tokens[i]], lastUpdateTime[tokens[i]]) = _updateRewardPerToken(tokens[i]);

            uint _reward = earned(tokens[i], tokenId);
            userRewards[tokens[i]][tokenId] = 0;
            lastEarn[tokens[i]][tokenId] = block.timestamp;
            userRewardPerTokenStored[tokens[i]][tokenId] = rewardPerTokenStored[tokens[i]];
            if (_reward > 0) _safeTransfer(tokens[i], _owner, _reward);

            emit ClaimRewards(_owner, tokens[i], _reward);
        }
    }

    function rewardPerToken(address token) public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored[token];
        }
        return rewardPerTokenStored[token] + ((lastTimeRewardApplicable(token) - Math.min(lastUpdateTime[token], periodFinish[token])) * rewardRate[token] * PRECISION / totalSupply);
    }

    function _batchUserRewards(address token, uint tokenId, uint maxRuns) internal view returns (uint, uint) {
        uint _startTimestamp = lastEarn[token][tokenId];
        if (numCheckpoints[tokenId] == 0) {
            return (userRewards[token][tokenId], _startTimestamp);
        }

        uint _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
        uint _endIndex = Math.min(numCheckpoints[tokenId]-1, maxRuns);

        uint reward = userRewards[token][tokenId];
        for (uint i = _startIndex; i < _endIndex; i++) {
            Checkpoint memory cp0 = checkpoints[tokenId][i];
            Checkpoint memory cp1 = checkpoints[tokenId][i+1];
            (uint _rewardPerTokenStored0,) = getPriorRewardPerToken(token, cp0.timestamp);
            (uint _rewardPerTokenStored1,) = getPriorRewardPerToken(token, cp1.timestamp);
            reward += cp0.balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0) / PRECISION;
            _startTimestamp = cp1.timestamp;
        }

        return (reward, _startTimestamp);
    }

    function batchRewardPerToken(address token, uint maxRuns) external {
        (rewardPerTokenStored[token], lastUpdateTime[token])  = _batchRewardPerToken(token, maxRuns);
    }

    function _batchRewardPerToken(address token, uint maxRuns) internal returns (uint, uint) {
        uint _startTimestamp = lastUpdateTime[token];
        uint reward = rewardPerTokenStored[token];

        if (supplyNumCheckpoints == 0) {
            return (reward, _startTimestamp);
        }

        uint _startIndex = getPriorSupplyIndex(_startTimestamp);
        uint _endIndex = Math.min(supplyNumCheckpoints-1, maxRuns);

        for (uint i = _startIndex; i < _endIndex; i++) {
            SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
            if (sp0.supply > 0) {
                SupplyCheckpoint memory sp1 = supplyCheckpoints[i+1];
                (uint _reward, uint endTime) = _calcRewardPerToken(token, sp1.timestamp, sp0.timestamp, sp0.supply, _startTimestamp);
                reward += _reward;
                _writeRewardPerTokenCheckpoint(token, reward, endTime);
                _startTimestamp = endTime;
            }
        }

        return (reward, _startTimestamp);
    }

    function _calcRewardPerToken(address token, uint timestamp1, uint timestamp0, uint supply, uint startTimestamp) internal view returns (uint, uint) {
        uint endTime = Math.max(timestamp1, startTimestamp);
        return (((Math.min(endTime, periodFinish[token]) - Math.min(Math.max(timestamp0, startTimestamp), periodFinish[token])) * rewardRate[token] * PRECISION / supply), endTime);
    }

    function _updateRewardPerToken(address token) internal returns (uint, uint) {
        uint _startTimestamp = lastUpdateTime[token];
        uint reward = rewardPerTokenStored[token];

        if (supplyNumCheckpoints == 0) {
            return (reward, _startTimestamp);
        }

        uint _startIndex = getPriorSupplyIndex(_startTimestamp);
        uint _endIndex = supplyNumCheckpoints-1;

        if (_endIndex - _startIndex > 1) {
            for (uint i = _startIndex; i < _endIndex-1; i++) {
                SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
                if (sp0.supply > 0) {
                  SupplyCheckpoint memory sp1 = supplyCheckpoints[i+1];
                  (uint _reward, uint _endTime) = _calcRewardPerToken(token, sp1.timestamp, sp0.timestamp, sp0.supply, _startTimestamp);
                  reward += _reward;
                  _writeRewardPerTokenCheckpoint(token, reward, _endTime);
                  _startTimestamp = _endTime;
                }
            }
        }

        SupplyCheckpoint memory sp = supplyCheckpoints[_endIndex];
        if (sp.supply > 0) {
            (uint _reward,) = _calcRewardPerToken(token, lastTimeRewardApplicable(token), Math.max(sp.timestamp, _startTimestamp), sp.supply, _startTimestamp);
            reward += _reward;
            _writeRewardPerTokenCheckpoint(token, reward, block.timestamp);
            _startTimestamp = block.timestamp;
        }

        return (reward, _startTimestamp);
    }

    function earned(address token, uint tokenId) public view returns (uint) {
        uint _startTimestamp = lastEarn[token][tokenId];
        if (numCheckpoints[tokenId] == 0) {
            return userRewards[token][tokenId];
        }

        uint _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
        uint _endIndex = numCheckpoints[tokenId]-1;

        uint reward = userRewards[token][tokenId];

        if (_endIndex - _startIndex > 1) {
            for (uint i = _startIndex; i < _endIndex-1; i++) {
                Checkpoint memory cp0 = checkpoints[tokenId][i];
                Checkpoint memory cp1 = checkpoints[tokenId][i+1];
                (uint _rewardPerTokenStored0,) = getPriorRewardPerToken(token, cp0.timestamp);
                (uint _rewardPerTokenStored1,) = getPriorRewardPerToken(token, cp1.timestamp);
                reward += cp0.balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0) / PRECISION;
            }
        }

        Checkpoint memory cp = checkpoints[tokenId][_endIndex];
        (uint _rewardPerTokenStored,) = getPriorRewardPerToken(token, cp.timestamp);
        reward += cp.balanceOf * (rewardPerToken(token) - Math.max(_rewardPerTokenStored, userRewardPerTokenStored[token][tokenId])) / PRECISION;

        return reward;
    }

    // This is an external function, but internal notation is used since it can only be called "internally" from BaseV1Gauges
    function _deposit(uint amount, uint tokenId) external {
        require(msg.sender == factory);
        totalSupply += amount;
        balanceOf[tokenId] += amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Deposit(msg.sender, tokenId, amount);
    }

    function _withdraw(uint amount, uint tokenId) external {
        require(msg.sender == factory);
        totalSupply -= amount;
        balanceOf[tokenId] -= amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Withdraw(msg.sender, tokenId, amount);
    }

    // used to notify a gauge/bribe of a given reward, this can create griefing attacks by extending rewards
    function notifyRewardAmount(address token, uint amount) external lock {
        (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token);

        if (block.timestamp >= periodFinish[token]) {
            _safeTransferFrom(token, msg.sender, address(this), amount);
            rewardRate[token] = amount / DURATION;
        } else {
            uint _remaining = periodFinish[token] - block.timestamp;
            uint _left = _remaining * rewardRate[token];
            require(amount > _left);
            _safeTransferFrom(token, msg.sender, address(this), amount);
            rewardRate[token] = (amount + _left) / DURATION;
        }
        require(rewardRate[token] > 0);
        uint balance = erc20(token).balanceOf(address(this));
        require(rewardRate[token] <= balance / DURATION, "Provided reward too high");
        periodFinish[token] = block.timestamp + DURATION;
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }

        emit NotifyReward(msg.sender, token, amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract BaseV1Voter {
    address public immutable _ve; // the ve token that governs these contracts
    address public immutable factory; // the BaseV1Factory
    address internal immutable base;
    address public immutable gaugefactory;

    uint public totalWeight; // total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => uint) public weights; // pool => weight
    mapping(uint => mapping(address => uint)) public votes; // nft => pool => votes
    mapping(uint => address[]) public poolVote; // nft => pools
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(address => bool) public isGauge;

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event Voted(address indexed voter, uint tokenId, uint weight);
    event Abstained(uint tokenId, uint weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);

    constructor(address __ve, address _factory, address  _gauges) {
        _ve = __ve;
        factory = _factory;
        base = ve(__ve).token();
        gaugefactory = _gauges;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function reset(uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        _reset(_tokenId);
        ve(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        uint _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint _votes = votes[_tokenId][_pool];

            if (_votes > 0) {
                _updateFor(gauges[_pool]);
                _totalWeight += _votes;
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                Bribe(bribes[gauges[_pool]])._withdraw(_votes, _tokenId);
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= _totalWeight;
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        address[] memory _poolVote = poolVote[_tokenId];
        uint _poolCnt = _poolVote.length;
        uint[] memory _weights = new uint[](_poolCnt);

        for (uint i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _poolVote, uint[] memory _weights) internal {
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        uint _weight = ve(_ve).balanceOfNFT(_tokenId);
        uint _totalVoteWeight = 0;
        uint _totalWeight = 0;
        uint _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i ++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _poolCnt; i ++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];
            uint _poolWeight = _weights[i] * _weight / _totalVoteWeight;

            if (isGauge[_gauge]) {
                _updateFor(_gauge);
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                weights[_pool] += _poolWeight;
                poolVote[_tokenId].push(_pool);
                votes[_tokenId][_pool] += _poolWeight;
                Bribe(bribes[_gauge])._deposit(_poolWeight, _tokenId);
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) ve(_ve).voting(_tokenId);
        totalWeight += _totalWeight;
        usedWeights[_tokenId] = _usedWeight;
    }

    function vote(uint tokenId, address[] calldata _poolVote, uint[] calldata _weights) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
        require(_poolVote.length == _weights.length);
        _vote(tokenId, _poolVote, _weights);
    }

    function createGauge(address _pool) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(IBaseV1Factory(factory).isPair(_pool), "!_pool");
        address _bribe = address(new Bribe());
        address _gauge = IBaseV1GaugeFactory(gaugefactory).createGauge(_pool, _bribe, _ve);
        erc20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
        return _gauge;
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) ve(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) ve(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint) {
        return pools.length;
    }

    uint internal index;
    mapping(address => uint) internal supplyIndex;
    mapping(address => uint) public claimable;

    function notifyRewardAmount(uint amount) external lock {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
          index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateFor(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateFor(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
              uint _share = _supplied * _delta / 1e18; // add accrued difference for each supplied token
              claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i ++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _bribes.length; i ++) {
            Bribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _fees.length; i ++) {
            Bribe(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i ++) {
            IGauge(_gauges[i]).claimFees();
        }
    }

    function distribute(address _gauge) public lock {
        _updateFor(_gauge);
        uint _claimable = claimable[_gauge];
        uint _left = IGauge(_gauge).left(base);
        if (_claimable > _left) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, pools.length);
    }

    function distribute() external {
        distribute(0, pools.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}