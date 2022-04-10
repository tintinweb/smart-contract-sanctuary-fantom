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
}

interface IGaugeProxy {
    function isWhitelisted(address token) external view returns (bool);
    function poke(address _owner) external;
}

contract Bribe {

    address public immutable factory; // only factory can modify balances (since it only happens on vote())

    uint public constant PRECISION = 10 ** 18;

    address[] public rewards;
    mapping(address => bool) public isReward;

    /// @notice Address -> Round Id -> Balance
    mapping (address => mapping (uint256 => uint256)) public checkpoints;
    /// @notice Token Address -> Round Id -> Reward Amount
    mapping(address => mapping (uint256 => uint256)) public rewardAmount;
    /// @notice Address -> Last Collected Round
    mapping(address => uint256) public lastRound;
    /// @notice Address -> Last Deposit Round
    mapping(address => uint256) public lastDeposit;
    /// @notice Address -> Last Withdraw Round
    mapping(address => uint256) public lastWithdraw;
    /// @notice Round -> Total Supply
    mapping (uint256 => uint256) public totalSupplyRound;
    /// @notice Round -> Snapshot block
    mapping (uint256 => uint256) public roundSnapshotBlock;
    /// @notice Current Round Id
    uint256 public round = 0;

    event Deposit(address indexed from, address user, uint amount);
    event Withdraw(address indexed from, address user);
    event NotifyReward(address indexed from, address indexed reward, uint amount);
    event ClaimRewards(address indexed from, address indexed reward, uint amount);

    constructor(address _factory) {
        factory = _factory;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }

    // allows a user to claim all rewards
    function getRewards() external lock  {
        if (lastWithdraw[msg.sender] < lastDeposit[msg.sender] && lastDeposit[msg.sender] < round) {
            _fillCheckpoints(msg.sender, lastDeposit[msg.sender]);
        }
        if(lastRound[msg.sender] < round){
            for (uint i = 0; i < rewards.length; i++) {
                uint _reward = earned(rewards[i], msg.sender);
                if (_reward > 0) _safeTransfer(rewards[i], msg.sender, _reward);
                emit ClaimRewards(msg.sender, rewards[i], _reward);
            }
            lastRound[msg.sender] = round;
        }
        IGaugeProxy(factory).poke(msg.sender);
    }

    // used by GaugeProxy to allow batched reward claims
    function getRewardForOwner(address user) external lock  {
        require(msg.sender == factory);
        if (lastWithdraw[user] < lastDeposit[user] && lastDeposit[user] < round) {
            _fillCheckpoints(user, lastDeposit[user]);
        }
        if(lastRound[user] < round){
            for (uint i = 0; i < rewards.length; i++) {
                uint _reward = earned(rewards[i], user);
                if (_reward > 0) _safeTransfer(rewards[i], user, _reward);
                emit ClaimRewards(user, rewards[i], _reward);
            }
            lastRound[user] = round;
        }
    }

    // Returns how many panding rewards a user has for a given token
    function earned(address token, address user) public view returns (uint256) {
        uint256 _earned = 0;
        uint256 _userCkpSupply = 0;
        uint256 _lastClaimed = lastRound[user]; // Last round claimed rewards
        if(_lastClaimed == round){
            // Address already claimed for this round, no rewards left for it
            return 0;
        }
        // For each round from the last the user claimed
        for(uint256 _lastRound = lastRound[user]; _lastRound < round; _lastRound++){
            // Get votes and reward amounts
            uint256 _roundTotalSupply = totalSupplyRound[_lastRound];
            uint256 _roundRewardAmount = rewardAmount[token][_lastRound];
            uint256 _checkpointUser = checkpoints[user][_lastRound];

            if(_lastRound < lastDeposit[user]) {
                _userCkpSupply = _checkpointUser;
            } else {
                if (lastWithdraw[user] > lastDeposit[user] && 
                    _lastRound >= lastWithdraw[user]){
                    _userCkpSupply = 0;
                } else {
                    _userCkpSupply = checkpoints[user][lastDeposit[user]];
                }
            }

            if(_roundTotalSupply == 0){
                // No Votes in this round
                _earned += 0;
            } else if(_userCkpSupply > _roundTotalSupply){
                // Something really weird happened, hopefully we will never 
                // get here.
                _earned += 0;
            } else {
                uint256 userShare = (_userCkpSupply * PRECISION / _roundTotalSupply);
                _earned += (_roundRewardAmount * userShare) / PRECISION;
            }
        }
        return _earned;
    }

    function getLastUserDepositCheckpoint(address user) external view returns (uint256) {
        uint256 _lastDeposit = lastDeposit[user];
        return checkpoints[user][_lastDeposit];
    }

    function getLastUserWithdrawCheckpoint(address user) external view returns (uint256) {
        uint256 _lastWithdraw = lastWithdraw[user];
        return checkpoints[user][_lastWithdraw];
    }

    // Fills current vote from a given point to the current round
    // Needed to keep track of users that do not take any action
    // for n rounds
    function _fillCheckpoints(address user, uint256 start) internal {
        uint256 _round = start + 1;
        uint256 _startCkp = checkpoints[user][start];
        for(; _round <= round; _round++){
            checkpoints[user][_round] = _startCkp;
        }
    }

    // Deposits voting power of a user
    function _deposit(uint amount, address user) external {
        require(msg.sender == factory);
        lastDeposit[user] = round;
        checkpoints[user][round] += amount;
        totalSupplyRound[round] += amount;
        emit Deposit(msg.sender, user, amount);
    }

    // Withdraws all the voting power of a user
    function _withdraw(address user) external {
        require(msg.sender == factory);
        if (lastDeposit[user] < round) {
            _fillCheckpoints(user, Math.max(lastDeposit[user],lastWithdraw[user]));
        }
        lastWithdraw[user] = round;
        totalSupplyRound[round] -= checkpoints[user][round];
        checkpoints[user][round] = 0;
        emit Withdraw(msg.sender, user);
    }

    // Previous round freezed, 
    // rewards get allocated after calling this function!
    function _snapshot() external {
        require(msg.sender == factory);
        roundSnapshotBlock[round] = block.number;
        round += 1;
        totalSupplyRound[round] = totalSupplyRound[round-1];
    }

    function getLastSnapshotBlock() external view returns (uint){
        require(round!=0, "No snapshots yet!");
        return roundSnapshotBlock[round-1];
    }

    function getRoundSnapshotBlock(uint _round) external view returns (uint){
        require(_round<round, "Invalid round selected");
        return roundSnapshotBlock[_round];
    }

    function getLastBribeAmount(address token) external view returns (uint) {
        return rewardAmount[token][round];
    }

    function getBribeAmountAtRound(address token, uint256 _round) external view returns (uint) {
        return rewardAmount[token][_round];
    }

    // Add a token to bribes!
    function notifyRewardAmount(address token, uint amount) external lock {
        require(IGaugeProxy(factory).isWhitelisted(token), "Token is not whitelisted!");
        require(amount > 0);

        _safeTransferFrom(token, msg.sender, address(this), amount);
        rewardAmount[token][round] += amount;

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

contract BaseV1BribeFactory {
    address public last_gauge;

    function createBribe() external returns (address) {
        last_gauge = address(new Bribe(msg.sender));
        return last_gauge;
    }
}