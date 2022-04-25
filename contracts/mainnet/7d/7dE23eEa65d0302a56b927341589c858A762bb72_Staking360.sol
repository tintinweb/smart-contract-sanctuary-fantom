// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity ^0.8.11;

contract Staking360 is Ownable {
    IERC20 public TKN;
    address private feeAddress;

    uint256[] public periods;
    uint256[] public rates;
    uint16 public constant FEE_RATE = 40;
    uint256[] public rewardsPool;
    uint256[] public rewardsPoolMax;
    uint256 public MAX_STAKES = 100;

    struct Stake {
        uint8 class;
        uint256 initialAmount;
        uint256 finalAmount;
        uint256 timestamp;
        bool unstaked;
    }

    Stake[] public stakes;

    mapping(address => uint256[]) public stakesOf;
    mapping(uint256 => address) public ownerOf;

    struct LeaderboardItem {
        address user;
        uint256 totalStaked;
    }

    mapping(uint256 => mapping(address => uint256)) public leaderboardsUser;
    mapping(uint256 => LeaderboardItem[]) public leaderboards;

    event Staked(
        address indexed sender,
        uint8 indexed class,
        uint256 amount,
        uint256 finalAmount
    );
    event Unstaked(address indexed sender, uint8 indexed class, uint256 amount);
    event IncreaseRewardPool(address indexed adder, uint256 timestamp, uint256 added);
    event WithdrawedRewardFromPool(
        address indexed owner,
        uint256 timestamp,
        uint256 indexed class,
        uint256 withdrawed
    );

    ///@dev Creates Staking SC for PGK token.
    ///@param _TKN PGK token address
    ///@param _feeAddress wallet address to which the unstake fee will be sent
    constructor(IERC20 _TKN, address _feeAddress) {
        TKN = _TKN;
        feeAddress = _feeAddress;
        addPeriod(180 days, 46504);
        addPeriod(360 days, 473326);
    }

    ///@dev Allow users to stake PGK tokens for selected period
    ///@param _class selected period index in periods[]. By default 0 is 180 days, 1 is for 360 days
    ///@param _amount amount of PGK token to be staked.
    function stake(uint8 _class, uint256 _amount) public {
        require(_class < periods.length, 'Wrong class');
        require(_amount > 0, 'Cannot Stake 0 Tokens');
        require(myActiveStakesCount(msg.sender) < MAX_STAKES, 'MAX_STAKES overflow');
        uint256 _finalAmount = _amount + (_amount * rates[_class]) / 10000;
        require(
            rewardsPool[_class] >= _finalAmount - _amount,
            'Rewards pool is empty for now'
        );
        rewardsPool[_class] -= _finalAmount - _amount;
        TKN.transferFrom(msg.sender, address(this), _amount);
        uint256 _index = stakes.length;
        stakesOf[msg.sender].push(_index);
        stakes.push(
            Stake({
                class: _class,
                initialAmount: _amount,
                finalAmount: _finalAmount,
                timestamp: block.timestamp,
                unstaked: false
            })
        );
        ownerOf[_index] = msg.sender;

        // for leaderboards
        if (leaderboardsUser[_class][msg.sender] == 0) {
            leaderboards[_class].push(
                LeaderboardItem({user: msg.sender, totalStaked: 0})
            );
            leaderboardsUser[_class][msg.sender] = leaderboards[_class].length;
        }
        leaderboards[_class][leaderboardsUser[_class][msg.sender] - 1]
            .totalStaked += _amount;
        emit Staked(msg.sender, _class, _amount, _finalAmount);
    }

    ///@dev Allows users unstake their staked PGK token when staking period expired. Users will pay the unstake fee (4% of reward by default) to the _feeAddress
    ///@param _index index of user stake
    function unstake(uint256 _index) public {
        require(msg.sender == ownerOf[_index], 'Not correct index');
        Stake storage _s = stakes[_index];
        require(!_s.unstaked, 'Already unstaked');
        require(
            block.timestamp >= _s.timestamp + periods[_s.class],
            'Staking period not finished'
        );
        uint256 _reward = (_s.finalAmount - _s.initialAmount);
        uint256 total = _s.initialAmount + _reward;
        uint256 _fee = (_reward * FEE_RATE) / 1000;
        total -= _fee;
        TKN.transfer(feeAddress, _fee);
        TKN.transfer(msg.sender, total);
        _s.unstaked = true;

        leaderboards[_s.class][leaderboardsUser[_s.class][msg.sender] - 1]
            .totalStaked -= _s.initialAmount;
        emit Unstaked(msg.sender, _s.class, _s.finalAmount);
    }

    ///@dev Allows owner to withdraw non-PGK ERC20 tokens
    ///@param _TKN non-PGK ERC20 token address
    function returnAccidentallySent(IERC20 _TKN) public onlyOwner {
        require(address(_TKN) != address(TKN), 'Unable to withdraw staking token');
        uint256 _amount = _TKN.balanceOf(address(this));
        _TKN.transfer(msg.sender, _amount);
    }

    function increaseRewardPools(uint256[] memory _class, uint256[] memory _amount)
        public
        onlyOwner
    {
        require(
            _amount.length == rates.length,
            'increaseRewardsPool: _amount length should be the same as rates length'
        );
        require(
            _class.length == rates.length,
            'increaseRewardsPool: _amount length should be the same as rates length'
        );
        uint256 amountLength = _amount.length;
        for (uint256 i = 0; i < amountLength; i++) {
            increaseRewardPool(_class[i], _amount[i]);
        }
    }

    ///@dev Allows owner to increase reward pool of selected period
    ///@param _class selected period index in periods[]. By default 0 is 180 days, 1 is for 360 days
    ///@param _amount amount to send in reward pool
    function increaseRewardPool(uint256 _class, uint256 _amount) public onlyOwner {
        require(_class < periods.length, 'increaseRewardPool: wrong _class');
        require(_amount > 0, 'increaseRewardPoll: _amount should be > 0');
        rewardsPool[_class] += _amount;
        rewardsPoolMax[_class] += _amount;
        TKN.transferFrom(msg.sender, address(this), _amount);
        emit IncreaseRewardPool(msg.sender, block.timestamp, _amount);
    }

    ///@dev Allows owner to withdraw unused reward from reward pool. Doesn't affect any user stakes and rewards.
    /// If owner withrawed all reward from selected period, user just couldn't stake more until reward pool increased
    ///@param _class selected period index in periods[]. By default 0 is 180 days, 1 is for 360 days
    ///@param _amount amount to be withdrawed from reward pool
    function withdrawRewardFromPool(uint256 _class, uint256 _amount) public onlyOwner {
        require(_class < periods.length, 'withdrawRewardFromPool: wrong class');
        require(
            rewardsPool[_class] >= _amount,
            'withdrawRewardFromPool: not enough reward on reward pool'
        );
        TKN.transfer(msg.sender, _amount);
        rewardsPool[_class] -= _amount;
        rewardsPoolMax[_class] -= _amount;
        emit WithdrawedRewardFromPool(msg.sender, block.timestamp, _class, _amount);
    }

    ///@dev Allows owner to increase max amount of active stakes
    ///@param _max new maximum active stakes amount
    function updateMax(uint256 _max) external onlyOwner {
        MAX_STAKES = _max;
    }

    ///@dev Allows owner to change fee address to which the unstake fee will be sent
    ///@param newFeeAddress new fee address
    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), 'Zero address');
        feeAddress = newFeeAddress;
    }

    ///@dev Allows owner to add new staking period
    ///@param _period period duration
    ///@param _rate period rate
    function addPeriod(uint256 _period, uint256 _rate) public onlyOwner {
        require(_period > 0, 'addPeriod: period should be > 0');
        require(_rate > 0, 'addPeriod: rate should be > 0');
        periods.push(_period);
        rates.push(_rate);
        rewardsPool.push(0);
        rewardsPoolMax.push(0);
    }

    ///@dev Allows owner to change rate of selected period
    ///@param _class selected period index in periods[]. By default 0 is 180 days, 1 is for 360 days
    ///@param _rate period rate
    function changeRate(uint256 _class, uint256 _rate) public onlyOwner {
        require(_rate > 0, 'changeRate: rate must > 0');
        require(_class < periods.length, 'changeRate: wrong _class');
        rates[_class] = _rate;
    }

    struct StakingInfo {
        uint256[] periods;
        uint256[] rates;
        uint256 feeRate;
        uint256[] rewardsPool;
        uint256[] rewardsPoolMax;
        uint256 maxStakes;
    }

    function getStakingInfo() public view returns (StakingInfo memory) {
        return
            StakingInfo({
                periods: periods,
                rates: rates,
                feeRate: FEE_RATE,
                rewardsPool: rewardsPool,
                rewardsPoolMax: rewardsPoolMax,
                maxStakes: MAX_STAKES
            });
    }

    function getLeaderboard(uint256 _class)
        public
        view
        returns (LeaderboardItem[] memory)
    {
        return leaderboards[_class];
    }

    function stakesInfo(uint256 _from, uint256 _to)
        public
        view
        returns (Stake[] memory s)
    {
        s = new Stake[](_to - _from);
        for (uint256 i = _from; i < _to; i++) s[i - _from] = stakes[i];
    }

    function stakesInfoAll() public view returns (Stake[] memory s) {
        uint256 stakeLength = stakes.length;
        s = new Stake[](stakeLength);
        for (uint256 i = 0; i < stakeLength; i++) s[i] = stakes[i];
    }

    function stakesLength() public view returns (uint256) {
        return stakes.length;
    }

    function myStakes(address _me)
        public
        view
        returns (Stake[] memory s, uint256[] memory indexes)
    {
        uint256 stakeLength = stakesOf[_me].length;
        s = new Stake[](stakeLength);
        indexes = new uint256[](stakeLength);
        for (uint256 i = 0; i < stakeLength; i++) {
            indexes[i] = stakesOf[_me][i];
            s[i] = stakes[indexes[i]];
        }
    }

    function myActiveStakesCount(address _me) public view returns (uint256 l) {
        uint256[] storage _s = stakesOf[_me];
        uint256 stakeLength = _s.length;
        for (uint256 i = 0; i < stakeLength; i++) if (!stakes[_s[i]].unstaked) l++;
    }
}