// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRouter {
	function getAmountsOut(
		uint256 amountIn, 
		address[] calldata path
	) external view returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IMinter {
	function mintRewards(
		uint256 _invested,
		uint256 _amount
	) external;
}

interface IStaking {
	function stake(
		uint256 _amount,
		address _depositor
	) external;
}

interface IEvol {
	function burn(uint256 _amount) external;
}

contract BondNative is Ownable {
	using SafeERC20 for IERC20;

	event LogDeposit(address indexed recipient, uint256 payout);

	struct Bond {
		uint256 payout;
		uint256 invested;
		uint32 lastTime;
		uint32 remainingVestingTime;
	}

	address public evol;
	address public stable;
	address public minter;
	address private payee;
	address private liquidityHandler;
	address public router;
	address public pair;
	address public staking;
	address public native;

	// rates are in thousandths of a %. i.e 1000 = 10%
	uint256 public rewardRate;
	uint256 public liquifyRate;
	uint256 public maxPayoutRate;
	uint256 public cashoutMintRate;

	uint256 public totalInvested;
	uint256 public totalRemainingRewards; 
	mapping(address => Bond) public bondOf;
	uint32 public vestingTime;

	uint256 public swapAmountIn;
	uint256 public swapAmountOut;
	bool public swapping = true;
	bool public liquify = true;
	bool private lock;

	constructor(
		address[] memory addresses,
		uint256[] memory rates,
		uint256[] memory swapAmounts,
		uint32 _vestingTime
	) {
		require(addresses[0] != address(0), "Bond: Evol cannot be address zero");
		require(addresses[1] != address(0), "Bond: Stable cannot be address zero");
		require(addresses[2] != address(0), "Bond: Minter cannot be address zero");
		require(addresses[3] != address(0), "Bond: Router cannot be address zero");
		require(addresses[4] != address(0), "Bond: Payee cannot be address zero");
		require(addresses[5] != address(0), "Bond: LiquidityHandler cannot be address zero");
		require(addresses[6] != address(0), "Bond: Staking cannot be address zero");
		require(addresses[7] != address(0), "Bond: native cannot be address zero");
		evol = addresses[0];
		stable = addresses[1];
		minter = addresses[2];
		router = addresses[3];
		payee = addresses[4];
		liquidityHandler = addresses[5];
		staking = addresses[6];
		native = addresses[7];
		
		require(rates[0] > 0, "Bond: RewardRate must be greater than 0");
		require(rates[1] > 0 && rates[1] < 10000, "Bond: liquifyRate must between 0 and 10000");
		require(rates[2] >= 0 && rates[2] < 10000, "Bond: maxPayoutRate must between 0 and 10000");
		require(rates[3] > 0 && rates[3] < 10000, "Bond: cashoutMintRate must between 0 and 10000");
		rewardRate = rates[0];
		liquifyRate = rates[1];
		maxPayoutRate = rates[2];
		cashoutMintRate = rates[3];
		
		require(swapAmounts[0] != 0, "Bond: SwapAmountIn cannot be zero");
		require(swapAmounts[1] != 0, "Bond: SwapAmountOut cannot be zero");
		swapAmountIn = swapAmounts[0] * (10**18);
		swapAmountOut = swapAmounts[1] * (10**18);

		require(_vestingTime > 36 * 60 * 60, "Bond: Vesting time must be greater than 36h");
		vestingTime = _vestingTime;
	}

	function deposit(uint256 _amount, uint256 _minPayout, address _depositor) external payable {
		require(_depositor != address(0), "Bond: Depositor cannot de address zero");

		_amount = msg.value; // amount as param for front

		(uint256 priceInDollars, uint256 priceInEvol) = _getPrices(_amount);
		uint256 payout = priceInEvol * (10000 + rewardRate) / 10000;

		require(payout >= _minPayout && payout >= 1000000000, "Bond: Payout is too small");
		require(payout <= maxPayout(), "Bond: Payout is too large");

		uint256 contractNativeBalance = address(this).balance;
		if (swapping && !lock && contractNativeBalance > swapAmountIn) {
			lock = true;

			uint256 stableBalance = swapExactETHForTokens(contractNativeBalance, stable);

			uint256 toLiquify = stableBalance * liquifyRate / 10000;

			if (liquify) {
				(, uint256 excessStable) = swapAndLiquify(toLiquify);
				IERC20(stable).safeTransfer(payee, stableBalance - toLiquify + excessStable);
			} else {
				swapAndBurn(toLiquify);
				IERC20(stable).safeTransfer(payee, stableBalance - toLiquify);
			}

			lock = false;
		}

		bondOf[_depositor] = Bond({
			payout: bondOf[_depositor].payout + payout,
			invested: bondOf[_depositor].invested + _amount,
			lastTime: uint32(block.timestamp),
			remainingVestingTime: vestingTime
		});

		totalInvested += priceInDollars;
		totalRemainingRewards += payout;
		IMinter(minter).mintRewards(priceInDollars, payout);
		emit LogDeposit(_depositor, payout);
	}

	function claim(address _recipient, bool _toStake) public { 
		Bond memory bond = bondOf[_recipient];
		uint256 vestedPerc = alreadyVestedPerc(_recipient);

		if (vestedPerc >= 10000) {
			delete bondOf[_recipient];
			stakeOrSend(_recipient, _toStake, bond.payout);
		} else {
			uint256 payout = bond.payout * vestedPerc / 10000;
			bondOf[_recipient] = Bond({
				payout: bond.payout - payout,
				invested: bond.invested,
				lastTime: uint32(block.timestamp),
				remainingVestingTime: bond.remainingVestingTime - (uint32(block.timestamp) - bond.lastTime)
			});
			stakeOrSend(_recipient, _toStake, payout);
		}
	}

	function _getPrices(uint256 _amount) internal view returns (uint256, uint256) {
		address[] memory path = new address[](3);
		path[0] = native;
		path[1] = stable;
		path[2] = evol;
		uint256[] memory amountsOut = new uint256[](3);
		amountsOut = IRouter(router).getAmountsOut(_amount, path);
		return (amountsOut[1], amountsOut[2]);
	}

	function swapAndLiquify(uint256 _amount) private returns (uint256, uint256) {
		uint256 swappedHalf = _amount / 2;
		uint256 otherHalf = _amount - swappedHalf;
		uint256 amountOut = swapExactTokensForTokens(swappedHalf, stable, evol);
		return addLiquidity(otherHalf, amountOut);
	}

	function swapAndBurn(uint256 _amount) private {
		uint256 amountOut = swapExactTokensForTokens(_amount, stable, evol);
		IEvol(evol).burn(amountOut);
	}
	
	function swapExactETHForTokens(uint256 _amount, address path1) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = native;
		path[1] = path1;
		return IRouter(router).swapExactETHForTokens{value: _amount}(
			0,
			path,
			address(this),
			block.timestamp
		)[1];
	}

	function swapExactTokensForTokens(uint256 _amount, address path0, address path1) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = path0;
		path[1] = path1;
		IERC20(path0).approve(router, _amount);
		return IRouter(router).swapExactTokensForTokens(
			_amount,
			0,
			path,
			address(this),
			block.timestamp
		)[1];
	}

	function addLiquidity(uint256 _stableAmount, uint256 _evolAmount) private returns (uint256, uint256) {
		IERC20(evol).approve(router, _evolAmount);
		IERC20(stable).approve(router, _stableAmount);
		(uint256 swappedEvol, uint256 swappedStable,) = IRouter(router).addLiquidity(
			evol, stable,
			_evolAmount, _stableAmount,
			0, 0,
			liquidityHandler, block.timestamp
		);
		return (_evolAmount - swappedEvol, _stableAmount - swappedStable);
	}

	function stakeOrSend(address _recipient, bool _toStake, uint256 _amount) private {
		if (swapping) {
			uint256 additionalAmount = _amount * (10000 + cashoutMintRate) / 10000 - _amount;

			if (additionalAmount > 0) {
				IMinter(minter).mintRewards(0, additionalAmount);
			}

			uint256 toSwap = IERC20(evol).balanceOf(address(this)) - totalRemainingRewards;
			if (toSwap > swapAmountOut) {
				uint256 swapped = swapExactTokensForTokens(toSwap, evol, stable);
				IERC20(stable).safeTransfer(payee, swapped);
			}
		}

		if (!_toStake) {
			IERC20(evol).safeTransfer(_recipient, _amount);
		} else {
			IERC20(evol).approve(staking, _amount);
			IStaking(staking).stake(_amount, _recipient);
		}
		totalRemainingRewards -= _amount;
	}
	
	function alreadyVestedPerc(address _recipient) public view returns (uint256) {
		Bond memory bond = bondOf[_recipient];
		uint256 remainingSeconds = bond.remainingVestingTime;
		if (remainingSeconds > 0) {
			uint256 secondsSinceLast = uint32(block.timestamp) - bond.lastTime;
			return secondsSinceLast * 10000 / remainingSeconds;
		}
		return 0;
	}

	function maxPayout() public view returns (uint256) {
		return IERC20(evol).totalSupply() * maxPayoutRate / 10000;
	}

	function pendingPayoutFor(address _recipient) public view returns (uint256) {
		uint256 vestedPerc = alreadyVestedPerc(_recipient);
		if (vestedPerc >= 10000) {
			return bondOf[_recipient].payout;
		}
		return bondOf[_recipient].payout * vestedPerc / 10000;
	}

	function setEvol(address _evol) external onlyOwner {
		evol = _evol;
	}
	
	function setStable(address _stable) external onlyOwner {
		stable = _stable;
	}
	
	function setMinter(address _minter) external onlyOwner {
		minter = _minter;
	}

	function setPayee(address _payee) external onlyOwner {
		payee = _payee;
	}
	
	function setLiquidityHandler(address _liquidityHandler) external onlyOwner {
		liquidityHandler = _liquidityHandler;
	}
	
	function setRouter(address _router) external onlyOwner {
		router = _router;
	}

	function setPair(address _pair) external onlyOwner {
		pair = _pair;
	}

	function setStaking(address _staking) external onlyOwner {
		staking = _staking;
	}

	function setNative(address _native) external onlyOwner {
		native = _native;
	}

	function setRewardRate(uint256 _rate) external onlyOwner {
		require(_rate > 0, "Bond: RewardRate must be greater than 0");
		rewardRate = _rate;
	}

	function setLiquifyRate(uint256 _rate) external onlyOwner {
		require(_rate > 0 && _rate < 10000, "Bond: LiquifyRate must between 0 and 10000");
		liquifyRate = _rate;
	}

	function setMaxPayoutRate(uint256 _rate) external onlyOwner {
		require(_rate >= 0 && _rate < 10000, "Bond: MaxPayoutRate must between 0 and 10000");
		maxPayoutRate = _rate;
	}
	
	function setCashoutMintRate(uint256 _rate) external onlyOwner {
		require(_rate > 0 && _rate < 10000, "Bond: CashoutMintRate must between 0 and 10000");
		cashoutMintRate = _rate;
	}

	function setVestingTime(uint32 _vestingTime) external onlyOwner {
		require(_vestingTime > 36 * 60 * 60, "Bond: VestingTime must be greater than 36h");
		vestingTime = _vestingTime;
	}
	
	function setSwapAmountIn(uint256 _swapAmountIn) external onlyOwner {
		require(_swapAmountIn > 0, "Bond: SwapAmountIn must be greater than 0");
		swapAmountIn = _swapAmountIn * (10**18);
	}
	
	function setSwapAmountOut(uint256 _swapAmountOut) external onlyOwner {
		require(_swapAmountOut > 0, "Bond: SwapAmountOut must be greater than 0");
		swapAmountOut = _swapAmountOut * (10**18);
	}

	function setSwapping(bool _swapping) external onlyOwner {
		swapping = _swapping;
	}

	function setLiquify(bool _liquify) external onlyOwner {
		liquify = _liquify;
	}
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}