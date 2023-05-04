// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault is IERC20 {
    // returns value of one wMLP in MLP tokens
    function pricePerShare() external view returns (uint256);
}

interface IMlpManager {
    // Returns AUM of MLP for calculating price.
    function getAum(bool maximise) external view returns (uint256);
}

contract wMlpPessimisticOracle is Ownable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Morphex's MLP Manager, use this to pull our total AUM in MLP.
    IMlpManager public immutable mlpManager;

    /// @notice Address for MLP, Morphex's LP token and the want token for our wMLP vault.
    IERC20 public immutable mlp;

    /// @notice Address of our wMLP, a Yearn vault token.
    IVault public immutable wMlp;

    /// @notice Set a hard cap on our wMLP price that we know it is unlikely to go above any time soon.
    /// @dev This may be adjusted by owner.
    uint256 public manualPriceCap;

    /// @notice Mapping of the low price for a given day.
    mapping(uint256 => uint256) public dailyLows;

    /* ========== CONSTRUCTOR ========== */

    constructor(IMlpManager _mlpManager, IERC20 _mlp, IVault _wMlp) {
        mlpManager = _mlpManager;
        mlp = _mlp;
        wMlp = _wMlp;
        manualPriceCap = 1.5e18;
    }

    /* ========== EVENTS ========== */

    event RecordDailyLow(uint256 price);
    event ManualPriceCapUpdated(uint256 manualWmlpPriceCap);

    /* ========== VIEWS ========== */

    /// @notice Decimals of our price, used by Scream's main oracle
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice Current day used for storing daily lows
    /// @dev Note that this is in unix time
    function currentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice Gets the current price of wMLP colateral
    /// @dev Return our price using a standard Chainlink aggregator interface
    /// @return The 48-hour low price of wMLP
    function latestRoundData()
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (
            uint80(0),
            int256(_getPrice()),
            uint256(0),
            uint256(0),
            uint80(0)
        );
    }

    /// @notice Gets the current price of wMLP colateral without any corrections
    function getLivePrice() public view returns (uint256) {
        // aum reported in USD with 30 decimals
        uint256 mlpPrice = (mlpManager.getAum(false) * 1e6) / mlp.totalSupply();

        // add in vault gains
        uint256 sharePrice = wMlp.pricePerShare();

        return (mlpPrice * sharePrice) / 1e18;
    }

    function _getPrice() internal view returns (uint256) {
        uint256 normalizedPrice = _getNormalizedPrice();
        uint256 day = currentDay();

        // get today's low
        uint256 todaysLow = dailyLows[day];
        if (todaysLow == 0 || normalizedPrice < todaysLow) {
            todaysLow = normalizedPrice;
        }

        // get yesterday's low
        uint256 yesterdaysLow = dailyLows[day - 1];

        // calculate price based on two-day low
        uint256 twoDayLow = todaysLow > yesterdaysLow && yesterdaysLow > 0
            ? yesterdaysLow
            : todaysLow;
        if (twoDayLow > 0 && normalizedPrice > twoDayLow) {
            return twoDayLow;
        }

        // if the current price is our lowest, use it
        return normalizedPrice;
    }

    // pull the total AUM in Morphex's MLP, and multiply by our vault token's share price
    function _getNormalizedPrice()
        internal
        view
        returns (uint256 normalizedPrice)
    {
        // aum reported in USD with 30 decimals
        uint256 mlpPrice = (mlpManager.getAum(false) * 1e6) / mlp.totalSupply();

        // add in vault gains
        uint256 sharePrice = wMlp.pricePerShare();

        normalizedPrice = (mlpPrice * sharePrice) / 1e18;

        // use a hard cap to protect against oracle pricing errors
        if (normalizedPrice > manualPriceCap) {
            normalizedPrice = manualPriceCap;
        }
    }

    /* ========== CORE FUNCTIONS ========== */

    /// @notice Checks current wMLP price and saves the price if it is the day's lowest
    /// @dev This may be called by anyone; the more times it is called the better
    function updatePrice() external {
        // get normalized price
        uint256 normalizedPrice = _getNormalizedPrice();

        // potentially store price as today's low
        uint256 day = currentDay();
        uint256 todaysLow = dailyLows[day];
        if (todaysLow == 0 || normalizedPrice < todaysLow) {
            dailyLows[day] = normalizedPrice;
            todaysLow = normalizedPrice;
            emit RecordDailyLow(normalizedPrice);
        }
    }

    /* ========== SETTERS ========== */

    /// @notice Set the hard price cap for our wMLP, which has 18 decimals
    /// @dev This may only be called by owner
    function setManualWmlpPriceCap(
        uint256 _manualWmlpPriceCap
    ) external onlyOwner {
        manualPriceCap = _manualWmlpPriceCap;
        emit ManualPriceCapUpdated(_manualWmlpPriceCap);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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