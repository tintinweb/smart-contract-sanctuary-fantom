/**
 *Submitted for verification at FtmScan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDepositor {
    function receiveLP(address from, address _pool, uint256 amount, uint256 currentBalance) external;
    function withdrawLP(address from, address _pool, uint256 amount, uint256 currentBalance) external;

    function claimSolidRewards(address _user, address[] calldata _pools, uint256[] calldata _currentBalances) external;
    function vote(address[] memory pools, int256[] memory weights) external;

    function whitelist(address _token, int256 _votes) external;

    function extendLockTime() external;
}

pragma solidity 0.8.15;

interface IRadialVoting {
    function balanceOfLP(address user) external returns(uint256);
    function receiveLP(address from, uint256 amount) external;
    function withdrawLP(address _from, uint256 _amount) external;
    function receiveRDL(address user, uint256 amount) external;
    function withdrawRDL(address user, uint256 amount) external;
    function getVotingPower(address user) external returns(uint256);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity 0.8.15;

contract WhitelistingBribeManager {
    uint256 constant WEEK = 60*60*24*7;
    IDepositor immutable DEPOSITOR;
    IRadialVoting immutable RADIAL_VOTING;
    uint256 immutable START_TIME;

    mapping(address => bool) public isWhitelisted;
    // briber -> tokenToWhitelist -> week -> bribeAmount
    mapping(address => mapping(address => mapping(uint256 => uint256))) public bribes;
    // user -> tokenToWhitelist -> week -> bribeAmount
    mapping(address => mapping(address => mapping(uint256 => bool))) public bribeClaimed;
    // tokenToWhitelist -> week -> bribeAmount
    mapping(address => mapping(uint256 => uint256)) public tokenBribes;
    // user -> tokenToWhitelist -> week -> votes
    mapping(address => mapping(address => mapping(uint256 => uint256))) votesUsed;
    // user -> tokenToWhitelist -> week -> votes
    mapping(address => mapping(address => mapping(uint256 => int256))) votes;
    // tokenToWhitelist -> week -> votes
    mapping(address => mapping(uint256 => int256)) tokenVotes;
    // tokenToWhitelist -> week -> votes
    mapping(address => mapping(uint256 => uint256)) public totalRewardWeight;

    event BribeDeposited(address indexed user, address indexed tokenToWhitelist, uint256 indexed week, uint256 bribeAmount);
    event BribeWithdrawn(address indexed user, address indexed tokenToWhitelist, uint256 indexed week, uint256 bribeAmount);
    event Voted(address indexed user, address indexed tokenToWhitelist, uint256 indexed week, int256 votes);
    event BribeClaimed(address indexed user, address indexed whitelistedToken, uint256 indexed week, uint256 amount);
    event TokenWhitelistedInSolidly(address indexed token, int256 votes, uint256 currentWeek);

    constructor(address _depositor, address _radialVoting, uint256 _startTime) {
        DEPOSITOR = IDepositor(_depositor);
        RADIAL_VOTING = IRadialVoting(_radialVoting);
        START_TIME = _startTime;
    }

    function deposit(address _tokenToWhitelist, uint256 _bribeAmount) external payable {
        require(!isWhitelisted[_tokenToWhitelist], "already whitelisted");
        uint256 _currentWeek = getWeek();
        require(_bribeAmount != 0, "0 bribe");
        require(msg.value == _bribeAmount, "Insufficient tokens");

        bribes[msg.sender][_tokenToWhitelist][_currentWeek] += _bribeAmount;
        tokenBribes[_tokenToWhitelist][_currentWeek] += _bribeAmount;
        emit BribeDeposited(msg.sender, _tokenToWhitelist, _currentWeek, _bribeAmount);
    }

    function withdraw(address _tokenToWhitelist, uint256 _week) external {
        require(!isWhitelisted[_tokenToWhitelist], "whitelisted");
        uint256 _currentWeek = getWeek();
        require(_week < _currentWeek, "proposal not over");
        uint256 _amount = bribes[msg.sender][_tokenToWhitelist][_week];
        require(_amount != 0, "no bribe");

        delete bribes[msg.sender][_tokenToWhitelist][_week];
        tokenBribes[_tokenToWhitelist][_week] -= _amount;

        payable(msg.sender).transfer(_amount);
        emit BribeWithdrawn(msg.sender, _tokenToWhitelist, _week, _amount);
    }

    function vote(address _tokenWhitelist, int256 _votes) external {
        require(!isWhitelisted[_tokenWhitelist], "whitelisted");
        uint256 _maxVotes = RADIAL_VOTING.getVotingPower(msg.sender);
        uint256 _currentWeek = getWeek();
        uint256 _usedVotes = votesUsed[msg.sender][_tokenWhitelist][_currentWeek];
        uint256 _absVotes = abs(_votes);
        require(_usedVotes + _absVotes <= _maxVotes, "more than voting power");

        tokenVotes[_tokenWhitelist][_currentWeek] += _votes;
        int256 _prevUserVotes = votes[msg.sender][_tokenWhitelist][_currentWeek];
        int256 _newUserVotes = _prevUserVotes + _votes;
        int256 _poolRewardWeight = int256(totalRewardWeight[_tokenWhitelist][_currentWeek]);
        if(_prevUserVotes < 0 && _newUserVotes > 0) {
            _poolRewardWeight += _newUserVotes;
        } else if(_prevUserVotes > 0 && _newUserVotes < 0) {
            _poolRewardWeight -= _prevUserVotes;
        } else if(_prevUserVotes >= 0 && _newUserVotes >= 0) {
            _poolRewardWeight += _votes;
        }
        totalRewardWeight[_tokenWhitelist][_currentWeek] = uint256(_poolRewardWeight);
        votes[msg.sender][_tokenWhitelist][_currentWeek] = _newUserVotes;
        votesUsed[msg.sender][_tokenWhitelist][_currentWeek] = _usedVotes + _absVotes;
        emit Voted(msg.sender, _tokenWhitelist, _currentWeek, _votes);
    }

    function whitelist(address _tokenToWhitelist) external {
        require(!isWhitelisted[_tokenToWhitelist], "whitelisted");
        uint256 _currentWeek = getWeek();
        int256 _votes = tokenVotes[_tokenToWhitelist][_currentWeek];
        DEPOSITOR.whitelist(_tokenToWhitelist, _votes);
        isWhitelisted[_tokenToWhitelist] = true;
        emit TokenWhitelistedInSolidly(_tokenToWhitelist, _votes, _currentWeek);
    }

    function claimBribes(address[] memory _whitelistedTokens, uint256[] memory _weeks) external {
        require(_whitelistedTokens.length == _weeks.length, "invalid inputs");
        for(uint256 i=0; i < _weeks.length; i++) {
            claimBribes(_whitelistedTokens[i], _weeks[i]);
        }
    }

    function claimBribes(address _whitelistedToken, uint256 _week) public {
        require(isWhitelisted[_whitelistedToken], "not whitelisted");
        int256 _userVote = votes[msg.sender][_whitelistedToken][_week];
        uint256 _totalTokenVotes = totalRewardWeight[_whitelistedToken][_week];
        require(_userVote > 0 && _totalTokenVotes > 0, "not voted for token");
        require(!bribeClaimed[msg.sender][_whitelistedToken][_week], "claimed");
        bribeClaimed[msg.sender][_whitelistedToken][_week] = true;
        uint256 _totalTokenBribe = tokenBribes[_whitelistedToken][_week];
        uint256 _userBribe = uint256(_userVote) * _totalTokenBribe / _totalTokenVotes;

        payable(msg.sender).transfer(_userBribe);
        emit BribeClaimed(msg.sender, _whitelistedToken, _week, _userBribe);
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - START_TIME) / WEEK;
    }

    // ////Imported from OZ SignedMath https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/math/SignedMath.sol#L37
    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}