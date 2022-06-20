// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Endpoint.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IERC20Detailed.sol";
import "../swappers/Swapper.sol";

contract StablecoinEndpointWrapper is Endpoint {
  uint256 totalDeposited;
  AggregatorV3Interface underlyingPriceOracle;
  AggregatorV3Interface stablecoinPriceOracle;
  IERC20Detailed underlying;
  Swapper swapper;
  uint256 endpointId;
  uint8 private constant decimalOffset = 12;

  constructor(
    IYamaRouter _router,
    Swapper _swapper,
    IERC20Detailed _underlying,
    IERC20Detailed _stablecoin,
    AggregatorV3Interface _underlyingPriceOracle,
    AggregatorV3Interface _stablecoinPriceOracle,
    uint256 _endpointId
  ) Endpoint(_router, _stablecoin) {
    swapper = _swapper;
    underlying = _underlying;
    underlyingPriceOracle = _underlyingPriceOracle;
    stablecoinPriceOracle = _stablecoinPriceOracle;
    endpointId = _endpointId;
    require(
      underlyingPriceOracle.decimals() == stablecoinPriceOracle.decimals());
  }

  function decimals() internal view returns (uint256) {
    return underlyingPriceOracle.decimals() + decimalOffset;
  }

  // underlying price / stablecoin price
  function priceRatio() internal view returns (uint256 ratio) {
    (,int256 underlyingPrice,,,) = underlyingPriceOracle.latestRoundData();
    underlyingPrice *= int256(10 ** decimalOffset);
    (,int256 stablecoinPrice,,,) = stablecoinPriceOracle.latestRoundData();
    stablecoinPrice *= int256(10 ** decimalOffset);
    ratio = (
      uint256(underlyingPrice) * (10 ** decimals())) / uint256(stablecoinPrice);

    uint8 underlyingDecimals = underlying.decimals();
    uint8 tokenDecimals = IERC20Detailed(address(token)).decimals();

    if (tokenDecimals > underlyingDecimals) {
      ratio *= (10 ** (tokenDecimals - underlyingDecimals));
    } else if (underlyingDecimals > tokenDecimals) {
      ratio /= (10 ** (underlyingDecimals - tokenDecimals));
    }
  }

  function withdrawableAmount() external view override returns (uint256) {
    uint256 underlyingValue = (totalDeposited * router.depositorRatio(
      endpointId)) / (10 ** router.decimals());
    return (underlyingValue * (10 ** decimals())) / priceRatio();
  }

  function acceptableSlippage(uint256 amount) internal pure returns (uint256) {
    return (amount / 100) * 2;
  }

  function tokenToUnderlying(uint256 tokenAmount) internal view returns (
    uint256 underlyingAmount
  ) {
    return (tokenAmount * (10 ** decimals())) / priceRatio();
  }

  function underlyingToToken(uint256 underlyingAmount) internal view returns (
    uint256 tokenAmount
  ) {
    return (underlyingAmount * priceRatio()) / (10 ** decimals());
  }

  function underlyingToLp(uint256 underlyingAmount) internal view returns (
    uint256 lpAmount
  ) {
    return (underlyingAmount * (10 ** router.decimals())) / (
      router.depositorRatio(endpointId));
  }

  // Called when tokens have been deposited into the pool.
  // Should verify that the router contract is calling.
  function deposit(uint256 amount) external override onlyRouter {
    token.transferFrom(msg.sender, address(this), amount);
    uint256 amountOutMin = tokenToUnderlying(amount);
    amountOutMin -= acceptableSlippage(amountOutMin);

    token.approve(address(swapper), amount);
    uint256 amountUnderlying = swapper.swap(
      token,
      underlying,
      amountOutMin,
      amount
    );

    underlying.approve(address(router), amountUnderlying);
    totalDeposited += router.deposit(endpointId, amountUnderlying);
  }

  // Called when tokens are being withdrawn from the pool.
  // Must give approval to the lending pool contract to transfer the tokens.
  // Otherwise, a default is declared.
  // Should verify that the router contract is calling.
  function withdraw(uint256 amount) external override onlyRouter returns (
    uint256 withdrawn
  ) {
    uint256 amountUnderlying = tokenToUnderlying(amount);
    uint256 lpAmount = underlyingToLp(amountUnderlying);

    if (lpAmount > totalDeposited) {
      lpAmount = totalDeposited;
    }
    amountUnderlying = router.withdraw(endpointId, lpAmount);
    totalDeposited -= lpAmount;
    uint256 amountOutMin = underlyingToToken(amountUnderlying);
    amountOutMin -= acceptableSlippage(amountOutMin);

    underlying.approve(address(swapper), amountUnderlying);
    withdrawn = swapper.swap(
      underlying,
      token,
      amountOutMin,
      amountUnderlying
    );

    token.approve(address(router), withdrawn);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IYamaRouter.sol";


abstract contract Endpoint {
  IERC20 token;
  IYamaRouter router;


  constructor(IYamaRouter _router, IERC20 _token) {
    token = _token;
    router = _router;
  }

  modifier onlyRouter {
    require(msg.sender == address(router));
    _;
  }

  function withdrawableAmount() virtual external view returns (uint256) {}

  function expectedAPY() virtual external view returns (uint256) {}

  // Called when tokens have been deposited into the lending pool.
  function deposit(uint256 amount) virtual external onlyRouter {}

  // Called when tokens are being withdrawn from the lending pool.
  // Must give approval to the router contract to transfer the tokens.
  // Otherwise, a default is declared.
  function withdraw(uint256 amount) virtual external onlyRouter returns (
    uint256 withdrawn
  ) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
abstract contract Swapper {
  address protocol;

  constructor(address _protocol) {
    protocol = _protocol;
  }

  // Must be authorized.
  // Swaps an ERC20 token for the native token and sends it back.
  // amount is in requested tokens.
  // spent is in ERC20 tokens
  function swapToNative(
    IERC20 token,
    uint256 requestedAmount,
    uint256 amountInMax
  ) public virtual returns (uint256 spent) {}

  function swap(
    IERC20 token1,
    IERC20 token2,
    uint256 amountOutMin,
    uint256 amountIn
  ) public virtual returns (uint256 received) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IYamaRouter {
  struct Endpoint {
    address endpoint;
    string name;
    uint256 minEndpointRatio;
    address token;
    address lpToken;
    bool verified;
  }

  function getEndpointToken(uint256 endpointId) external view returns (address token);

  function getEndpointLPToken(uint256 endpointId) external view returns (address lpToken);

  // Only available for some endpoints.
  function getExpectedAPY(uint256 endpointId) external view returns (uint256);

  function endpointsLength() external view returns (uint256 length);

  function endpoints(uint256 endpointId) external view returns (
    address endpoint,
    string memory name,
    uint256 minEndpointRatio,
    address token,
    address lpToken,
    bool verified
  );

  // This scales depositorRatio()
  function decimals() external view returns (uint256 decimals);

  // How much of the underlying token 1 LP token is worth, i.e. the exchange
  // rate.
  function depositorRatio(uint256 id) external view returns (uint256 amount);

  // Deposit amount in the underlying token and receive a quantity of LP tokens
  // based on depositorRatio().
  // The contract must have approval to transfer the given amount of the
  // underlying token.
  // lpTokenAmount is the amount of issued LP tokens.
  function deposit(uint256 id, uint256 amount) external returns (uint256 lpTokenAmount);

  // Withdraw lpTokenAmount to receive a quantity of underlying tokens based
  // on depositorRatio().
  // depositorPay is the amount of received tokens after withdrawal.
  function withdraw(uint256 id, uint256 lpTokenAmount) external returns (uint256 depositorPay);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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