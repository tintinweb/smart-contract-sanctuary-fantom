/**
 *Submitted for verification at FtmScan.com on 2023-03-21
*/

/**
 *  EQUALIZER EXCHANGE
 *  The New Liquidity Hub of Fantom chain!
 *  https://equalizer.exchange  (Dapp)
 *  https://discord.gg/MaMhbgHMby   (Community)
 *
 *
 *  Version: 1.5.1
 *  - Backwards-compatibility with version < v1.4.0
 *    - periodFinish(<token>)
 *    - rewardRate(<token>)
 *    - lastUpdateTime(<token>)
 *    - _ve()
 *  - "Enhanced" Taxable Fee-Claims (This is NOT deposit/withdraw fee!)
 *    - Ability to introduce Protocol Fees
 *
 *
 *  Version: 1.5.0
 *  - Remove the "checkpoint" system
 *  - Remove "Proxy pattern" construction
 *  - Remove Pausable contract (Removes inheritance from Owned contract)
 *  - MultiRewards Gauge with per-token variable epoch-lengths (default: 7 days)
 *  - Supports Rewarding with Transfer-fee tokens
 *  - Supports Deposits/Withdraws of tokens with Transfer-fee
 *  - Support for LP Bribes
 *    - Voter.team() can enable a new Reward token, which can be added by anyone as a reward thereafter
 *    - Base Equal token default with a single-token reward config over 7 days
 *  - Taxable Fee-Claims (This is NOT deposit/withdraw fee!)
 *    - Ability to fund multiple Bribes at once
 *    - Ability to channel funds from 'claimFees' into some other contracts
 *  - Support for new LP types:
 *    - 2pool/3pool/4pool: Curve-style Stable Pools & Crypto Pools
 *    - Upto 8-token weighted, stable, meta-boosted & meta-stable Balancer-style pools
 *    - Wrapped Concentrated Liquidity fungible pools (ERC1155)
 *  - "Enhanced" Griefing Protection Enabled for Unknown reward adders
 *    - Voter & Distributor can notify rewards freely without any restrictions
 *    - Choice of validation between best of SNX method (rewardRate not lower) or CRV method (more than left)
 *  - Remove "Boosted" rewards
 *    - No concept of derivedBalances
 *    - No veNFT attachments/detachments upon deposits/withdrawals
 *  - totalBribePayouts to replace fee0 & fees1 to support multi-token accounting of claimed fees
 *  - Introduce the concept of `bribeTokens` to help facilitate bribes from non-standard multi-token pools
 *  - Upgradable Reward-distribution Durations
 *  - Remove concept of MAX_REWARD_TOKENS
 *    - Only ve.team() can `addReward()` new tokens
 *
 *
 *  Version: 1.4.0
 *    - Remove the whole concept of Internal Bribes (Trade Fees Streamer).
 *    - Each deposit/withdraw/getReward also calls claimFees
 *    - Allow to notifyRewards to Bribe without the fear of griefing
 *        - Time-dilution of reward APR by extending periodFinish is not possible
 *        - Bribes are paid as a lumpsum. Trade Fees are treated as External Bribes.
 *    - Repurpose usage of fees0 & fees1 as indicators of net revenue of a gauge
 *  - Allow overriding fee receipient (like ABcDeFX) by Voter.team()
 *  - Voter.team() can siphon out unclaimed rewards.
 *    - The deposited "stake" tokens (user funds) cannot be rescued. (No Rugs!)
 *    - Only the Reward tokens can be rescue()'d.
 *    - Useful in cases of non-official/external/independent gauges
 *        - Especially in cases where "stake"d tokens have their own claimFees().
 *
 *
 *
 *
 *  Contributors:
 *   -   Synthetix Network
 *   -   Curve Finance
 *   -   Andre Cronje, Fantom & Solidly.Exchange
 *   -   543 (Sam), ftm.guru & Equalizer.exchange
 *
 *
 *	SPDX-License-Identifier: UNLICENSED
*/


pragma solidity 0.8.9;


// File: contracts/interfaces/IGaugeFactory.sol

interface IGaugeFactory {
    function createGauge(address, address, address, bool, address[] memory) external returns (address);
}

// File: contracts/interfaces/IVotingEscrow.sol

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}

// File: contracts/interfaces/IVoter.sol

interface IVoter {
    function _ve() external view returns (address);
    function governor() external view returns (address);
    function emergencyCouncil() external view returns (address);
    function protocolFeesTaker() external view returns (address);
    function attachTokenToGauge(uint _tokenId, address account) external;
    function attachable() external view returns (bool);
    function protocolFeesPerMillion() external view returns (uint);
    function detachTokenFromGauge(uint _tokenId, address account) external;
    function emitDeposit(uint _tokenId, address account, uint amount) external;
    function emitWithdraw(uint _tokenId, address account, uint amount) external;
    function isWhitelisted(address token) external view returns (bool);
    function notifyRewardAmount(uint amount) external;
    function distribute(address _gauge) external;
}
// File: contracts/interfaces/IPair.sol

interface IPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// File: contracts/interfaces/IBribe.sol

interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function rewardsListLength() external view returns (uint);
    function rewards(uint) external view returns (address);
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract GaugeEquivalent is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    struct Reward {
        address rewardsDistributor;
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    bool public paused;
    IERC20 public stake;
    mapping(address => Reward) public rewardData;
    address[] public rewardTokens;
    address[] public bribeTokens;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;
    mapping(address => bool) public isReward;
    mapping(address => bool) public isBribeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IBribe public bribe;
    IVotingEscrow public ve;
    IVoter public voter;
    bool public isForPair;

    address public feeTaker;

    mapping(address => uint) public payouts;
    mapping(address => uint) public payoutsNotified;
    mapping(address => mapping(address => uint)) public earnings;
    mapping(address => uint) public totalFeesPayouts;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stake,
        address _ebribe,
        address  __ve,
        address _voter,
        bool _forPair,
        address[] memory _allowedRewardTokens
    ) {

        stake = IERC20(_stake);
        bribe = IBribe(_ebribe);
        ve = IVotingEscrow(__ve);
        voter = IVoter(_voter);
        isForPair = _forPair;

        for (uint i; i < _allowedRewardTokens.length; i++) {
            if (_allowedRewardTokens[i] != address(0)) {
                isReward[_allowedRewardTokens[i]] = true;
                rewardTokens.push(_allowedRewardTokens[i]);
                rewardData[_allowedRewardTokens[i]].rewardsDistributor = _voter;
                rewardData[_allowedRewardTokens[i]].rewardsDuration = 7 days;
            }
        }
        if(_forPair) {
            //claimFees : Bribe Rewards
            //Pre-approve to save gas, since both Bribe & Gauge are immutable
            (address _token0, address _token1) = IPair(_stake).tokens();
            IERC20(_token0).approve(_ebribe, type(uint256).max);
            IERC20(_token1).approve(_ebribe, type(uint256).max);
            bribeTokens.push(_token0);
            bribeTokens.push(_token1);
            isBribeToken[_token0] = true;
            isBribeToken[_token1] = true;
            emit BribeTokenSet(_token0, _ebribe, true);
            emit BribeTokenSet(_token1, _ebribe, true);
        }
        ///else ve.team() must manually `addBribeTokens()`
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken).sub(rewardData[_rewardsToken].lastUpdateTime).mul(rewardData[_rewardsToken].rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    /// @param account 1
    /// @param _rewardsToken 2
    function earnedBy(address account, address _rewardsToken) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[account][_rewardsToken])).div(1e18).add(rewards[account][_rewardsToken]);
    }

    /// Backwards compatible view with 3qu471738 <= v1.3
    /// @param _rewardsToken 1
    /// @param account 2
    function earned(address _rewardsToken, address account) public view returns (uint256) {
        return earnedBy(account, _rewardsToken);
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardData[_rewardsToken].rewardsDuration);
    }

    function left(address _rewardsToken) external view returns (uint) {
        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) return 0;
        uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
        return remaining.mul(rewardData[_rewardsToken].rewardRate);
    }

    function rewardsListLength() external view returns (uint) {
        return rewardTokens.length;
    }

    function bribesListLength() external view returns (uint) {
        return bribeTokens.length;
    }

    /* ========== BACKWARDS-COMPATIBLE VIEW FUNCTIONS ========== */

    function _ve() external view returns (address) {
        return address(ve);
    }

    function periodFinish(address _tkn) external view returns (uint) {
        return rewardData[_tkn].periodFinish;
    }

    function rewardRate(address _tkn) external view returns (uint) {
        return rewardData[_tkn].rewardRate;
    }

    function lastUpdateTime(address _tkn) external view returns (uint) {
        return rewardData[_tkn].lastUpdateTime;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external onlyOwner {
        rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
    }

    function deposit(uint256 amount) public nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stake.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
        _claimFees();
    }

    function depositFor(address _user, uint256 amount) public nonReentrant notPaused updateReward(_user) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[_user] = _balances[_user].add(amount);
        stake.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(_user, amount);
        _claimFees();
    }

    function depositAll() external {
        deposit(stake.balanceOf(msg.sender));
    }

    function depositAllFor(address _user) external {
        depositFor(_user, stake.balanceOf(msg.sender));
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stake.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
        _claimFees();
    }

    function withdrawAll() external {
        withdraw(_balances[msg.sender]);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {

        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 _reward = rewards[msg.sender][_rewardsToken];
            if (_reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(msg.sender, _reward);
                emit ClaimRewards(msg.sender, _rewardsToken, _reward);
                payouts[_rewardsToken] += _reward;
                earnings[msg.sender][_rewardsToken] += _reward;
            }
        }
        _claimFees();
    }

    function _getReward(address account, address[] memory _tokens) internal nonReentrant updateReward(account) {
        for (uint i; i < _tokens.length; i++) {
            address _rewardsToken = _tokens[i];
            uint256 _reward = rewards[account][_rewardsToken];
            if (_reward > 0) {
                rewards[account][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(account, _reward);
                emit ClaimRewards(_rewardsToken, account, _reward);
                payouts[_rewardsToken] += _reward;
                earnings[account][_rewardsToken] += _reward;
            }
        }
        _claimFees();
    }

    function getReward(address account, address[] memory tokens) external {
        require(msg.sender == account || msg.sender == address(voter), "Un-authorized claim!");
        voter.distribute(address(this));
        _getReward(account, tokens);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external nonReentrant updateReward(address(0)) {
        require(_rewardsToken != address(stake), "Can't distribute staked token as reward!");
        require(isReward[_rewardsToken], "Not a reward!!" );
        /// The old pattern to get force collection of fees at least once a week during emission distribution to this gauge
        /// & distribute it to voters over the next week via the (external) Bribe
        _claimFees();

        /// Support feeOnTransfer tokens like ELITE etc.
        uint rtbb = IERC20(_rewardsToken).balanceOf(address(this));
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _reward);
        uint rtba = IERC20(_rewardsToken).balanceOf(address(this));
        _reward = rtba - rtbb;
        require(_reward > 0, "Reward amount must be greater than 0!");

        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = _reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            //Griefing Protection Enabled for Unknown reward adders
            uint _oldRewardRate = rewardData[_rewardsToken].rewardRate;
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = _reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
            if(
                msg.sender!=address(voter)
                || msg.sender!=rewardData[_rewardsToken].rewardsDistributor
            ) {
                require(
                    (
                        rewardData[_rewardsToken].rewardRate >= _oldRewardRate
                        || _reward > leftover
                    ), "Enhanced Griefing Protection Enabled!"
                );
            }
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
        emit RewardAdded(_rewardsToken, msg.sender, _reward);
        payoutsNotified[_rewardsToken] += _reward;
    }

    function claimFees() external nonReentrant returns (uint claimed0, uint claimed1) {
        return _claimFees();
    }

    function _claimFees() internal returns (uint claimed0, uint claimed1)  {
        uint _pfpm = voter.protocolFeesPerMillion();
        address _pft = _pfpm > 0 ? voter.protocolFeesTaker() : address(0);
        /// Equa7izer v1.5: Support Custom pools to be Gaugable
        if (!isForPair) {
        	/// For non-official/external/independent gauges only
        	/// If compatible, the claimed fees should be notified to Bribe
        	/// Else, this contract will hold the fees & ve.team() can rescue()
            uint _bn = bribeTokens.length;
        	IERC20[] memory _brews = new IERC20[](_bn);
        	uint[] memory _brewbals = new uint[](_bn);
        	for(uint _n; _n < _bn; _n++) {
        	    _brews[_n] = IERC20( bribeTokens[_n] );
        	    /// Record current balance to protect gauge deposits & rewards.
                /// Also Support feeOnTransfer tokens like ELITE etc.
                /// Also makes sure a bribe-reward isnt 'killed' or uninitialized.
        	    _brewbals[_n] =
        	        address(_brews[_n]) == address(0)
        	        ? 0
        	        : _brews[_n].balanceOf(address(this));
        	}
            try IPair(address(stake)).claimFees() {
                /// if call succeeds, gauge will have a surplus of extra tokens which can be sent to bribes
                /// useful in cases of non-equa1izer lps, like conc., weighted or multi-token Liquidity pools
                for(uint _n = 0; _n < _bn; _n++) {
                    /// Don't trigger bribes for 0x00 rewards
                    uint _a =
        	            address(_brews[_n]) == address(0)
        	            ? 0
        	            : _brews[_n].balanceOf(address(this));
                    /// Trigger only when a token balance increases when we try IPair(stake).claimFees()
                    /// because there could possibly be an overlap between rewardTokens & bribeTokens
                    if(_a > _brewbals[_n]) {
                        ///Protocol Fees
                        if( ( (_a - _brewbals[_n]) * _pfpm) / 1e6 > 0) {
                            _brews[_n].transfer(_pft, ( (_a.sub(_brewbals[_n])) * _pfpm) / 1e6 );
                            emit ProtocolFees(msg.sender,_pft,address(_brews[_n]),((_a.sub(_brewbals[_n])) * _pfpm) / 1e6);
                            _a = _brews[_n].balanceOf(address(this));
                        }
                        ///Normal Fees -> Bribe
                        if (feeTaker == address(0)) {
                            bribe.notifyRewardAmount( address(_brews[_n]), (_a.sub(_brewbals[_n])) );
                            emit ClaimFees(msg.sender, address(bribe), address(_brews[_n]), (_a - _brewbals[_n]) );
                            totalFeesPayouts[ address(_brews[_n]) ] += (_a - _brewbals[_n]);
                        }
                        ///Re-channeled Fees -> FeesTaker
                        else {
                            _brews[_n].transfer(feeTaker, (_a.sub(_brewbals[_n])) );
                            emit ClaimFees(msg.sender, feeTaker, address(_brews[_n]), (_a - _brewbals[_n]) );
                            totalFeesPayouts[ address(_brews[_n]) ] += (_a - _brewbals[_n]);
                        }
                    }
                    /// else: we dont have any fees here ser!
                }
                return (0, 0);
            }
            catch {
                /// if call fails, do nothing (much).
                return (0, 0);
            }
        }

        //else:
        /// For actual Protocol gauges, created by Voter, for E9ua1izer Factory Pairs
        (address _token0, address _token1) = IPair(address(stake)).tokens();
        /// Support feeOnTransfer tokens like ELITE etc.
        uint t0bb = IERC20(_token0).balanceOf(address(this));
        uint t1bb = IERC20(_token1).balanceOf(address(this));
        //(claimed0, claimed1) =
        try IPair(address(stake)).claimFees() {
            claimed0 = IERC20(_token0).balanceOf(address(this)) - t0bb;
            claimed1 = IERC20(_token1).balanceOf(address(this)) - t1bb;
            //claimed0 = t0ba - t0bb;
            //claimed1 = t1ba - t1bb;

            ///ProtocolFees
            if( ( claimed0 * _pfpm) / 1e6 > 0) {
                IERC20(_token0).transfer(_pft, (claimed0*_pfpm)/1e6 );
                emit ProtocolFees(msg.sender,_token0,_pft,(claimed0*_pfpm)/1e6);
                claimed0 = IERC20(_token0).balanceOf(address(this)).sub(t0bb);
            }
            if( ( claimed1 * _pfpm) / 1e6 > 0) {
                IERC20(_token1).transfer(_pft, (claimed1*_pfpm)/1e6 );
                emit ProtocolFees(msg.sender,_token1,_pft,(claimed1*_pfpm)/1e6);
                claimed1 = IERC20(_token1).balanceOf(address(this)).sub(t1bb);
            }

            ///Normal Fees -> Bribe
		    if (feeTaker == address(0)) {
            	if (claimed0 > 0) {
                	bribe.notifyRewardAmount(_token0, claimed0);
                	totalFeesPayouts[ _token0 ] += claimed0;	// stores total token0 fees claimed since genesis
                    emit ClaimFees(msg.sender, feeTaker, _token0, claimed0);
            	}
            	if (claimed1 > 0) {
                	bribe.notifyRewardAmount(_token1, claimed1);
                	totalFeesPayouts[ _token1 ] += claimed1;	// stores total token1 fees claimed since genesis
                    emit ClaimFees(msg.sender, feeTaker, _token1, claimed1);
            	}
            }

            ///Re-channeled Fees -> FeesTaker
            else {
            	IERC20(_token0).transfer(feeTaker, claimed0);
            	IERC20(_token1).transfer(feeTaker, claimed1);
                emit ClaimFees(msg.sender, feeTaker, _token0, claimed0);
                emit ClaimFees(msg.sender, feeTaker, _token1, claimed1);
                totalFeesPayouts[ _token0 ] += claimed0;	// stores total token0 fees claimed since genesis
                totalFeesPayouts[ _token1 ] += claimed1;	// stores total token1 fees claimed since genesis
            }

            return (claimed0, claimed1);
        }
        catch {
            ///dont revert if _claimFees_ fails, just skip it. Useful with fee-on-transfer tokens.
            return (0, 0);
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function addReward(address _rewardsToken, address _rewardsDistributor, uint256 _rewardsDuration) public onlyOwner {
        require(
            isReward[_rewardsToken] == false
            && rewardData[_rewardsToken].rewardsDuration == 0
            , "Already Initialized!"
        );
        require( _rewardsToken != address(stake), "Cannot reward staking token!");
        rewardTokens.push(_rewardsToken);
        isReward[_rewardsToken] = true;
        rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    }

    /// This can break claims of rewards!
    /// Useful during a platform-wide upgrade (optional)
    function rescue(uint _amt, address _token, address _to) external onlyOwner {
        if(_token == address(stake)) {
            /// totalSupply marks the sum of all user deposits.
            /// surplus checks for any additional holdings that are not user-deposits
            /// Helps rescue of extra rewards from single-side same-token staking.
            uint _surplus = (stake.balanceOf(address(this))).sub(_totalSupply);
            require( _amt <= _surplus, "Rescuing User Deposits Prohibited!");
        }
        IERC20(_token).transfer(_to, _amt);
        emit Recovered(_token, _amt);
    }

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > rewardData[_rewardsToken].periodFinish,
            "Reward period still active"
        );
        require(_rewardsDuration > 0, "Reward duration must be non-zero");
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
    }

    function addBribeToken(address _t) public onlyOwner {
        require(isBribeToken[_t] == false, "Bribe Token Active!");
        require( _t != address(stake), "Cannot bribe staking token!");
        IERC20(_t).approve(address(bribe), type(uint256).max);
        bribeTokens.push(_t);
        isBribeToken[_t] = true;
        emit BribeTokenSet(_t, address(bribe), true);
    }

    function removeBribeToken(address _t) public onlyOwner {
        require(isBribeToken[_t] == true, "Bribe Token Inactive!");
        IERC20(_t).approve(address(bribe), 0);
        uint _bl = bribeTokens.length;
        if(bribeTokens[_bl-1]==_t) {
            bribeTokens.pop();
            isBribeToken[_t] = false;
        }
        else {
            for(uint i; i < bribeTokens.length - 1; i++) {
                if(bribeTokens[i]==_t) {
                    bribeTokens[i] = bribeTokens[_bl-1];
                    bribeTokens.pop();
                    isBribeToken[_t] = false;
                }
            }
        }
        emit BribeTokenSet(_t, address(bribe), false);
    }

    function addBribeTokens(address[] memory _tks) external onlyOwner {
        for(uint _j; _j < _tks.length; _j++) {
            addBribeToken(_tks[_j]);
        }
    }

    function removeBribeTokens(address[] memory _tks) external onlyOwner {
        for(uint _j; _j < _tks.length; _j++) {
            removeBribeToken(_tks[_j]);
        }
    }

    /// When feeTaker is set, all Fees Claims go to it instead of going to the Bribe.
    /// Useful during a platform-wide upgrade (optional)
    function setFeeTaker(address _ft) external onlyOwner {
        feeTaker = _ft;
    }

    function setPaused(bool _b) external onlyOwner {
        paused = _b;
    }

    function setBribe(address _b) external {
        require(msg.sender==address(voter), "Un-authorized!");
        address _ob = address(bribe);
        for(uint i;i<bribeTokens.length;i++) {
            address _rt = bribeTokens[i];
            IERC20(_rt).approve(_ob, 0);	// revoke old-bribe allowances
            IERC20(_rt).approve(_b, type(uint256).max); // approve new bribe
        }
        bribe = IBribe(_b);
    }



    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earnedBy(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    modifier onlyOwner {
        require(msg.sender==ve.team(), "Only ve.team!");
        _;
    }

    modifier notPaused {
        require(!paused, "Paused!");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(address indexed token, address indexed notifier, uint256 reward);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ClaimRewards(address indexed token, address indexed user, uint256 reward);
    event RewardsDurationUpdated(address indexed token, uint256 newDuration);
    event Recovered(address indexed token, uint256 amount);
    event BribeTokenSet(address indexed token, address indexed bribe, bool indexed active);
    event ProtocolFees(address indexed initiator, address indexed taker, address indexed token, uint amount);
    event ClaimFees(address indexed initiator, address indexed bribe, address indexed token, uint amount);
}

// File: contracts/factories/GaugeFactory.sol



contract GaugeFactory is IGaugeFactory {
    address public lastGauge;
    event GaugeCreated(address indexed maker, address indexed pool, address g, address b, address v, bool i, address[] a);
    function createGauge(
        address _pool,
        address _bribe,
        address _ve,
        bool isPair,
        address[] memory _allowedRewards
    ) external returns (address) {
        GaugeEquivalent gauge = new GaugeEquivalent(
            _pool,
            _bribe,
            _ve,
            msg.sender,
            isPair,
            _allowedRewards
        );
        lastGauge = address(gauge);
        emit GaugeCreated(msg.sender, _pool, address(gauge), _bribe, _ve, isPair, _allowedRewards);
        return lastGauge;
    }
}