/**
 *Submitted for verification at FtmScan.com on 2022-02-11
*/

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later


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




// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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


pragma solidity 0.8.11;

////import "@openzeppelin/contracts/access/Ownable.sol";

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Inspired by https://github.com/vetherasset/vader-protocol-v2/blob/main/contracts/tokens/vesting/LinearVesting.sol
/**
 * @dev Implementation of the Linear Vesting
 *
 * The straightforward vesting contract that gradually releases a
 * fixed supply of tokens to multiple vest parties over a 1 year
 * window.
 *
 * The token expects the {begin} hook to be invoked the moment
 * it is supplied with the necessary amount of tokens to vest
 */
contract Vesting is Ownable {
    /* ========== CONSTANTS ========== */

    address internal constant _ZERO_ADDRESS = address(0);

    uint256 internal constant _ONE_YEAR = 365 days;

    /* ========== RADIAL ALLOCATION ========== */

    // The Radial token
    IERC20 public constant RDL = IERC20(0x79360aF49edd44F3000303ae212671ac94bB8ba7);

    // Locker Farm allocation vested over {VESTING_DURATION} years
    uint256 public constant LOCKER_ALLOCATION = 6_000_000 * 1 ether;

    uint256 public constant TEAM_ALLOCATION = 15_000_000 * 1 ether;

    address public constant DAO = 0x8c027C15D5aAd465DF025FAd90bfD3E20e465c19;

    address public constant LP = 0x79d2DDAf5184Cfaff052d3c3af05A765A5a04cdE;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 public constant VESTING_DURATION = 1 * _ONE_YEAR;

    /* ========== STRUCTS ========== */

    // Struct of a vesting member, tight-packed to 256-bits
    struct Vester {
        uint192 amount;
        uint64 lastClaim;
        uint128 start;
        uint128 end;
    }

    /* ========== EVENTS ========== */

    event VestingInitialized(uint256 duration);

    event TeamVestingInitialized(uint256 duration);

    event VestingCreated(address user, uint256 amount);

    event Vested(address indexed from, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    // The start of the vesting period
    uint256 public start;

    // The end of the vesting period
    uint256 public end;

    // The status of each vesting member (Vester)
    mapping(address => Vester) public vest;

    // total amount vested for users
    uint256 public total;

    bool internal teamVestingInitialized;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the Radial token address
     *
     * Additionally, it transfers ownership to the Owner contract that needs to consequently
     * initiate the vesting period via {begin} after it mints the necessary amount to the contract.
     */
    constructor(address _admin) {
        require(
            _admin != _ZERO_ADDRESS,
            "Misconfiguration"
        );

        transferOwnership(_admin);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the amount a user can claim at a given point in time.
     *
     * Requirements:
     * - the vesting period has started
     */
    function getClaim(address _vester)
        external
        view
        hasStarted
        returns (uint256 vestedAmount)
    {
        Vester memory vester = vest[_vester];
        return
            _getClaim(
                vester.amount,
                vester.lastClaim,
                vester.start,
                vester.end
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows a user to claim their pending vesting amount of the vested claim
     *
     * Emits a {Vested} event indicating the user who claimed their vested tokens
     * as well as the amount that was vested.
     *
     * Requirements:
     *
     * - the vesting period has started
     * - the caller must have a non-zero vested amount
     */
    function claim() external returns (uint256 vestedAmount) {
        Vester memory vester = vest[msg.sender];

        require(
            vester.start != 0,
            "Not Started"
        );

        require(
            vester.start < block.timestamp,
            "Not Started Yet"
        );

        vestedAmount = _getClaim(
            vester.amount,
            vester.lastClaim,
            vester.start,
            vester.end
        );

        require(vestedAmount != 0, "Nothing to claim");

        vester.amount -= uint192(vestedAmount);
        vester.lastClaim = uint64(block.timestamp);

        vest[msg.sender] = vester;

        emit Vested(msg.sender, vestedAmount);

        RDL.transfer(msg.sender, vestedAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Allows the vesting period to be initiated.
     *
     * Emits a {VestingInitialized} event from which the start and
     * end can be calculated via it's attached timestamp.
     *
     * Requirements:
     *
     * - the caller must be the owner
     */
    function begin(address[] memory vesters, uint192[] memory amounts)
        external
        onlyOwner
    {
        require(
            vesters.length == amounts.length,
            "Invalid Inputs"
        );

        uint256 _start = block.timestamp;
        uint256 _end = _start + VESTING_DURATION;

        start = _start;
        end = _end;

        uint256 _total = total;
        for (uint256 i = 0; i < vesters.length; i++) {
            require(
                amounts[i] != 0,
                "Incorrect Amount Specified"
            );
            require(
                vesters[i] != _ZERO_ADDRESS,
                "Zero Vester Address Specified"
            );
            require(
                vest[vesters[i]].amount == 0,
                "Duplicate Vester Entry Specified"
            );
            vest[vesters[i]] = Vester(
                amounts[i],
                0,
                uint128(_start),
                uint128(_end)
            );
            _total = _total + amounts[i];
        }
        require(
            _total <= LOCKER_ALLOCATION,
            "Invalid Vest Amounts Specified"
        );

        total = _total;

        emit VestingInitialized(VESTING_DURATION);
    }

    function vestForTeam(address[] memory members, uint192[] memory amounts) 
        external 
        onlyOwner
    {
        require(
            !teamVestingInitialized, 
            "Team vesting started"
        );
        require(
            members.length == amounts.length, 
            "Invalid inputs"
        );

        uint256 _start = block.timestamp;
        uint256 _end = _start + VESTING_DURATION;
        uint256 _total = 0;

        start = _start;
        end = _end;

        for(uint256 i=0; i < members.length; i++) {
            require(
                amounts[i] != 0,
                "Incorrect Amount Specified"
            );
            require(
                members[i] != _ZERO_ADDRESS,
                "Zero Vester Address Specified"
            );
            require(
                vest[members[i]].amount == 0,
                "Duplicate Vester Entry Specified"
            );

            vest[members[i]] = Vester(
                amounts[i],
                0,
                uint128(_start),
                uint128(_end)
            );
            _total = _total + amounts[i];
        }

        require(
            _total == TEAM_ALLOCATION,
            "Invalid Vest Amounts Specified"
        );

        teamVestingInitialized = true;

        emit TeamVestingInitialized(VESTING_DURATION);
    }

    /**
     * @dev Adds a new vesting schedule to the contract.
     *
     * Requirements:
     * - Only {owner} can call.
     */
    function vestFor(address user, uint256 amount)
        external
        onlyOwner
        hasStarted
    {
        require(
            amount <= type(uint192).max,
            "Amount Overflows uint192"
        );
        require(
            vest[user].amount == 0,
            "Already a vester"
        );
        vest[user] = Vester(
            uint192(amount),
            0,
            uint128(block.timestamp),
            uint128(block.timestamp + VESTING_DURATION)
        );
        RDL.transferFrom(msg.sender, address(this), amount);

        emit VestingCreated(user, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getClaim(
        uint256 amount,
        uint256 lastClaim,
        uint256 _start,
        uint256 _end
    ) private view returns (uint256) {
        if (block.timestamp >= _end) return amount;
        if (lastClaim == 0) lastClaim = _start;

        return (amount * (block.timestamp - lastClaim)) / (_end - lastClaim);
    }

    /**
     * @dev Validates that the vesting period has started
     */
    function _hasStarted() private view {
        require(
            start != 0,
            "Vesting hasn't started yet"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if the vesting period hasn't started
     */
    modifier hasStarted() {
        _hasStarted();
        _;
    }
}