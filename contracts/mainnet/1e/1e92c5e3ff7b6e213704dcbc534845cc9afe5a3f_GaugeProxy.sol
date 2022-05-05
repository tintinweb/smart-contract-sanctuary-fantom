/**
 *Submitted for verification at FtmScan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7; //^0.7.5;
pragma experimental ABIEncoderV2;

interface MasterChef {
    function deposit(uint, uint) external;
    function withdraw(uint, uint) external;
    function userInfo(uint, address) external view returns (uint, uint);
}

interface IBribe {
    function _deposit(uint _amount, address _user) external;
    function _withdraw(uint _amount, address _user) external;
    function getRewardForOwner(address _user, address[] memory _rewardTokens) external;
}

interface IBaseV1BribeFactory {
    function createBribe() external returns (address);
}

contract ProtocolGovernance {
    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Gauge is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public SPIRIT;
    IERC20 public inSPIRIT;

    IERC20 public immutable TOKEN;
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    modifier onlyDistribution() {
        require(msg.sender == DISTRIBUTION, "Caller is not RewardsDistribution contract");
        _;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    uint public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;
    mapping(address => uint) private _base;

    constructor(address _spirit, address _inSpirit, address _token) public {
        SPIRIT = IERC20(_spirit);
        inSPIRIT = IERC20(_inSpirit);
        TOKEN = IERC20(_token);
        DISTRIBUTION = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (derivedSupply == 0) {
            return 0;
        }

        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(derivedSupply)
            );
    }

    function derivedBalance(address account) public view returns (uint) {
        if(inSPIRIT.totalSupply() == 0) return 0;
        uint _balance = _balances[account];
        uint _derived = _balance.mul(40).div(100);
        uint _adjusted = (_totalSupply.mul(inSPIRIT.balanceOf(account)).div(inSPIRIT.totalSupply())).mul(60).div(100);
        return Math.min(_derived.add(_adjusted), _balance);
    }

    function kick(address account) public {
        uint _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply.sub(_derivedBalance);
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply.add(_derivedBalance);
    }

    function earned(address account) public view returns (uint256) {
        return derivedBalances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(DURATION);
    }

    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender);
    }

    function depositFor(uint256 amount, address account) external {
        _deposit(amount, account);
    }

    function _deposit(uint amount, address account) internal nonReentrant updateReward(account) {
        require(amount > 0, "deposit(Gauge): cannot stake 0");

        uint256 userAmount = amount;

        _balances[account] = _balances[account].add(userAmount);
        _totalSupply = _totalSupply.add(userAmount);

        TOKEN.safeTransferFrom(account, address(this), amount);

        emit Staked(account, userAmount);
    }

    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        TOKEN.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            SPIRIT.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(uint256 reward) external onlyDistribution updateReward(address(0)) {
        SPIRIT.safeTransferFrom(DISTRIBUTION, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = SPIRIT.balanceOf(address(this));
        require(rewardRate <= balance.div(DURATION), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
        }
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

contract MasterDill {
    using SafeMath for uint;

    /// @notice EIP-20 token name for this token
    string public constant name = "Master inSPIRIT";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "minSPIRIT";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 1e18;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor() public {
        balances[msg.sender] = 1e18;
        emit Transfer(address(0x0), msg.sender, 1e18);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "transferFrom: exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");

        balances[src] = balances[src].sub(amount, "_transferTokens: exceeds balance");
        balances[dst] = balances[dst].add(amount, "_transferTokens: overflows");
        emit Transfer(src, dst, amount);
    }
}

contract GaugeProxy is ProtocolGovernance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    MasterChef public MASTER;
    IERC20 public inSPIRIT;
    IERC20 public SPIRIT;
    IERC20 public immutable TOKEN; // mInSpirit

    // Address for bribeFactory
    address public immutable bribeFactory;
    uint public immutable MIN_INSPIRIT_FOR_VERIFY = 1e23;   // 100k inSPIRIT

    uint public pid = uint(-1); // -1 means 0xFFF....F and hasn't been set yet
    uint public totalWeight;

    // Time delays
    uint256 public voteDelay = 10 days;
    uint256 public distributeDelay = 7 days;
    uint256 public lastDistribute;
    mapping(address => uint256) public lastVote;  // msg.sender => time of users last vote

    // V2 added variables for pre-distribute
    uint private lockedTotalWeight;
    uint private lockedBalance;
    uint private locktime;
    mapping(address => uint) private lockedWeights; // token => weight
    mapping(address => bool) private hasDistributed; // LPtoken => bool

    // VE bool
    bool public ve = false; 

    address[] internal _tokens;
    address internal feeDistAddr; // fee distributor address 
    mapping(address => address) public gauges; // token => gauge
    mapping(address => address) public deprecated; // token => gauge
    // Add Guage to Bribe Mapping
    mapping(address => address) public bribes; // gauge => bribes
    mapping(address => bool) public verifiedRewardTokens;   // Maintain rewardTokens verified bool
    mapping(address => uint) public weights; // token => weight
    mapping(address => mapping(address => uint)) public votes; // msg.sender => votes
    mapping(address => address[]) public tokenVote;// msg.sender => token
    mapping(address => uint) public usedWeights;  // msg.sender => total voting weight of user

    // Modifiers
    modifier hasVoted(address voter){
        uint256 time = block.timestamp - lastVote[voter];
        require(time > voteDelay, "You voted in the last 10 days");
        _;
    }

    modifier hasDistribute(){
        uint256 time = block.timestamp - lastDistribute;
        require(time > distributeDelay, "this has been distributed in the last 7 days");
        _;
    }

    constructor(
        address _masterChef,
        address _spirit,
        address _inSpirit,
        address _feeDist,
	    address _bribeFactory
    ) public {
        MASTER = MasterChef(_masterChef);
        SPIRIT = IERC20(_spirit);
        inSPIRIT = IERC20(_inSpirit);
        TOKEN = IERC20(address(new MasterDill()));
        governance = msg.sender;
        feeDistAddr = _feeDist;
	    bribeFactory = _bribeFactory;
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    // Reset votes to 0
    function reset() external {
        _reset(msg.sender);
    }

    // Reset votes to 0
    function _reset(address _owner) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;

        for (uint i = 0; i < _tokenVoteCnt; i ++) {
            address _token = _tokenVote[i];
            uint _votes = votes[_owner][_token];

            if (_votes > 0) {
                totalWeight = totalWeight.sub(_votes);
                weights[_token] = weights[_token].sub(_votes);
                // Bribe vote withdrawal
                IBribe(bribes[gauges[_token]])._withdraw(uint256(_votes), _owner);
                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
    }

    // Adjusts _owner's votes according to latest _owner's inSPIRIT balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        uint256[] memory _weights = new uint[](_tokenCnt);
        uint256 _prevUsedWeight = usedWeights[_owner];
        uint256 _weight = inSPIRIT.balanceOf(_owner);

        for (uint256 i = 0; i < _tokenCnt; i ++) {
            // Need to make this reflect the value deposited into bribes, anyone should be able to call this on
            // other addresses to stop them from gaming the system with outdated votes that dont lose voting power
            uint256 _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = _prevWeight.mul(_weight).div(_prevUsedWeight);
        }

        _vote(_owner, _tokenVote, _weights);
    }

    function _vote(address _owner, address[] memory _tokenVote, uint256[] memory _weights) internal {
        // _weights[i] = percentage * 100
        _reset(_owner);
        uint256 _tokenCnt = _tokenVote.length;
        uint256 _weight = inSPIRIT.balanceOf(_owner);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i ++) {
            _totalVoteWeight = _totalVoteWeight.add(_weights[i]);
        }

        for (uint256 i = 0; i < _tokenCnt; i ++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            uint256 _tokenWeight = _weights[i].mul(_weight).div(_totalVoteWeight);

            if (_gauge != address(0x0)) {
                _usedWeight = _usedWeight.add(_tokenWeight);
                totalWeight = totalWeight.add(_tokenWeight);
                weights[_token] = weights[_token].add(_tokenWeight);
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
                // Bribe vote deposit
                IBribe(bribes[_gauge])._deposit(uint256(_tokenWeight), msg.sender);
            }
        }

        usedWeights[_owner] = _usedWeight;
    }

    // Vote with inSPIRIT on a gauge
    function vote(address[] calldata _tokenVote, uint256[] calldata _weights) external hasVoted(msg.sender){
        require(_tokenVote.length == _weights.length);
        lastVote[msg.sender] = block.timestamp;
        _vote(msg.sender, _tokenVote, _weights);
    }

    // Add new token gauge
    function addGauge(address _token) external returns(address){
        require(msg.sender == governance, "!gov");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(new Gauge(address(SPIRIT), address(inSPIRIT), _token));
        _tokens.push(_token);

        // deplopy bribe contract for gauge
        address _bribe = IBaseV1BribeFactory(bribeFactory).createBribe();
        bribes[gauges[_token]] = _bribe;
        return gauges[_token];
    }

    // Deprecate existing gauge
    function deprecateGauge(address _token) external  {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] != address(0x0), "does not exist");
        deprecated[_token] = gauges[_token];
        delete gauges[_token];
        totalWeight = totalWeight.sub(weights[_token]);
        delete weights[_token];
    }

    // Bring Deprecated gauge back into use
    function resurrectGauge(address _token) external {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = deprecated[_token];
        delete deprecated[_token];
    }

    // Add existing gauge
    function migrateGauge(address _gauge, address _token) external {
        require(msg.sender == governance, "!gov");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = _gauge;
        _tokens.push(_token);
    }

    // Sets MasterChef PID
    function setPID(uint _pid) external {
        require(msg.sender == governance, "!gov");
        pid = _pid;
    }

    // Deposits minSPIRIT into MasterChef
    function deposit() public {
        require(pid != uint(-1), "pid not initialized");
        IERC20 _token = TOKEN;
        uint _balance = _token.balanceOf(address(this));
        _token.safeApprove(address(MASTER), 0);
        _token.safeApprove(address(MASTER), _balance);
        MASTER.deposit(pid, _balance);
    }

    // Fetches Spirit
    function collect() public {
        (uint _locked,) = MASTER.userInfo(pid, address(this));
        MASTER.withdraw(pid, _locked);
        deposit();
    }

    function length() external view returns (uint) {
        return _tokens.length;
    }

    function preDistribute() external hasDistribute() {
        require(msg.sender == governance, "!gov");
        lockedTotalWeight = totalWeight;
        for (uint i = 0; i < _tokens.length; i++) {
          lockedWeights[_tokens[i]] = weights[_tokens[i]];
          hasDistributed[_tokens[i]] = false;
        }
        collect();
        lastDistribute = block.timestamp;
        uint _balance = SPIRIT.balanceOf(address(this));
        if(ve){
            uint _lockedSpirit = SPIRIT.balanceOf(address(inSPIRIT));
            uint _spiritBalance = SPIRIT.totalSupply();
            uint _lockedWeight = _lockedSpirit.div(_spiritBalance);
            uint _inSPiritRewards = _lockedWeight.mul(_balance);

            if (_inSPiritRewards > 0 ){
                SPIRIT.safeTransfer(feeDistAddr,_inSPiritRewards);
                _balance = _balance - _inSPiritRewards;
            }
        }

        lockedBalance = _balance;
        locktime = block.timestamp;
    }


    function distribute(uint _start, uint _end) external {
        require(_start < _end, "bad _start");
        require(_end <= _tokens.length, "bad _end");
        collect();
        uint _balance = SPIRIT.balanceOf(address(this));

        if (_balance > 0 && totalWeight > 0) {

            for (uint i = _start; i < _end; i++) {
                address _token = _tokens[i];
                if (hasDistributed[_token] == false) {
                    address _gauge = gauges[_token];
                    uint _reward = _balance.mul(weights[_token]).div(totalWeight);
                
                    if (_reward > 0) {
                        SPIRIT.safeApprove(_gauge, 0);
                        SPIRIT.safeApprove(_gauge, _reward);
                        Gauge(_gauge).notifyRewardAmount(_reward);
                    }
                    hasDistributed[_token] = true;
                }
            }
        }
    }

    // function distribute() external hasDistribute() {
    //     lastDistribute = block.timestamp;
    //     collect();
    //     uint _balance = SPIRIT.balanceOf(address(this));

    //     if(ve){
    //         uint _lockedSpirit = SPIRIT.balanceOf(address(inSPIRIT));
    //         uint _spiritBalance = SPIRIT.totalSupply();
    //         uint _lockedWeight = _lockedSpirit.div(_spiritBalance);
    //         uint _inSPiritRewards = _lockedWeight.mul(_balance);

    //         if (_inSPiritRewards > 0 ){
    //             SPIRIT.safeTransfer(feeDistAddr,_inSPiritRewards);
    //             _balance = _balance - _inSPiritRewards;
    //         }
    //     }

    //     if (_balance > 0 && totalWeight > 0) {

    //         for (uint i = 0; i < _tokens.length; i++) {
    //             address _token = _tokens[i];
    //             address _gauge = gauges[_token];
    //             uint _reward = _balance.mul(weights[_token]).div(totalWeight);

    //             if (_reward > 0) {
    //                 SPIRIT.safeApprove(_gauge, 0);
    //                 SPIRIT.safeApprove(_gauge, _reward);
    //                 Gauge(_gauge).notifyRewardAmount(_reward);
    //             }
    //         }

    //     }
    // }

    // Add claim function for bribes
    function claimBribes(address[] memory _bribes, address[][] memory _rewardTokens, address _user) external {
        require(_user == msg.sender);

        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_user, _rewardTokens[i]);
        }
    }

    // Update fee distributor address
    function updateFeeDistributor(address _feeDistAddr) external {
        require(msg.sender == governance, "updateFeeDestributor: permission is denied!");
        feeDistAddr = _feeDistAddr;
    }

    function toggleVE() external{
        require(msg.sender == governance, "turnVeOn: permission is denied!");
        ve = !ve;
    }

    function verifyRewardToken(address _rewardToken) public {
        require(inSPIRIT.balanceOf(msg.sender) >= MIN_INSPIRIT_FOR_VERIFY, "Need 100k inSPIRIT to verify a reward token");
        verifiedRewardTokens[_rewardToken] = true;
    }

}