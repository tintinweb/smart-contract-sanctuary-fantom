// SPDX-License-Identifier: MIT OR Apache-2.0

import "./interfaces/DeFi/ICurveFactory.sol";
import "./interfaces/DeFi/ICurvePool.sol";
import "./interfaces/OneRingProduct/IOneRingCurveRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LibUtils} from "./libraries/LibUtils.sol";

pragma solidity 0.8.9;

contract OneRingCurveRouterV1 is IOneRingCurveRouter, Ownable {

  using SafeERC20 for IERC20;

  address public constant CURVE_FACTORY = 0x686d67265703D1f124c45E33d47d794c566889Ba;
  
  address private constant FRAX  = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;
  address private constant DAI   = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
  address private constant USDC  = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
  address private constant fUSDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;

  address private constant FRAX_DAI_USDC   = 0x7a656B342E14F745e2B164890E88017e27AE7320;
  address private constant MIM_fUSDT_USDC  = 0x2dd7C9371965472E5A5fD28fbE165007c61439E1;

  uint256 private constant FRAX_DECIMALS = 18;
  uint256 private constant DAI_DECIMALS = 18;
  uint256 private constant USDC_DECIMALS = 6;
  uint256 private constant fUSDT_DECIMALS = 6;

  mapping(address => mapping(address => address)) public exchangePools;
  mapping(address => bool) public isMetaPool;
  mapping(address => uint256) public tokensDecimals;
 
  event MetaPoolAdded(address indexed metaPool);
  event MetaPoolRemoved(address indexed metaPool);
  event ExchangeDeleted(address indexed from, address indexed to, address indexed pool);
  event ExchangeAdded(address indexed from, address indexed to, address indexed pool);

  error OneRingCurveRouter_Invalid_Input();
  error OneRingCurveRouter_Invalid_Amount();
  error OneRingCurveRouter_Tokens_Not_Supported();

  constructor() {
    tokensDecimals[FRAX] = 18;
    tokensDecimals[DAI] = 18;

    tokensDecimals[fUSDT] = 6;
    tokensDecimals[USDC] = 6;

    isMetaPool[FRAX_DAI_USDC]  = true;

    exchangePools[FRAX][USDC]  = FRAX_DAI_USDC;
    exchangePools[FRAX][DAI]   = FRAX_DAI_USDC;
    
    exchangePools[DAI][USDC]   = FRAX_DAI_USDC;
    exchangePools[DAI][FRAX]   = FRAX_DAI_USDC;

    exchangePools[USDC][FRAX]  = FRAX_DAI_USDC;
    exchangePools[USDC][DAI]   = FRAX_DAI_USDC;
    exchangePools[USDC][fUSDT] = MIM_fUSDT_USDC;
  
    exchangePools[fUSDT][USDC]  = MIM_fUSDT_USDC;
   
    address[5] memory tokens = [FRAX,DAI,USDC,USDC,fUSDT];
    address[5] memory pools = [FRAX_DAI_USDC,FRAX_DAI_USDC,FRAX_DAI_USDC,MIM_fUSDT_USDC,MIM_fUSDT_USDC];

    for(uint256 i = 0; i < 5; i++) {
      IERC20(tokens[i]).safeApprove(pools[i], type(uint256).max);
    }
    
  }
  
  // This function is expected to swap amount from 'from' to 'to'
  // It only works if it exists a pool to swap between those 
  // Or if this pool does not exists, then they must have USDC in common.
  function swap(address from, address to, uint256 amount) external returns(uint256) {
    if(from == address(0)) {
      revert OneRingCurveRouter_Invalid_Input();
    }

    if(to == address(0)) {
      revert OneRingCurveRouter_Invalid_Input();
    }

    if(amount == 0) {
      revert OneRingCurveRouter_Invalid_Input();
    }

    if(from == to) {
      return amount;
    }

    IERC20(from).safeTransferFrom(msg.sender, address(this), amount);

    address poolToUse = exchangePools[from][to];
    uint256 amountReceived;

    // we found a pool that contain both of the tokens
    if(poolToUse != address(0)) {
      amountReceived = _swap(from, to, poolToUse, amount);
    }

    else {
      address poolToGoToUSDC = exchangePools[from][USDC];
      address poolFromUSDCtoExpectedToken = exchangePools[USDC][to];

      if(poolToGoToUSDC == address(0) || poolFromUSDCtoExpectedToken == address(0)) {
        revert OneRingCurveRouter_Tokens_Not_Supported();
      }

      // We exchange first for USDC
      uint256 amountUSDCReceived = _swap(from, USDC, poolToGoToUSDC, amount);
      // Then we go from USDC to ``to''
      amountReceived = _swap(USDC, to, poolFromUSDCtoExpectedToken, amountUSDCReceived);
    }

    IERC20(to).safeTransfer(msg.sender, amountReceived);

    return amountReceived;
  }

  // Internal function that do the swaps, we calculate the minimum we want to receive and pass it as argumet to curve
  function _swap(address from, address to, address poolToUse, uint256 amount) internal returns(uint256) {
    (int128 _fromIndex, int128 _toIndex,) = ICurveFactory(CURVE_FACTORY).get_coin_indices(poolToUse, from, to);

    uint256 amountReceived;
    if(isMetaPool[poolToUse]) {
      uint256 fromDecimals = tokensDecimals[from];
      uint256 toDecimals = tokensDecimals[to];
      uint256 amountExpectedToReceive = LibUtils._convertFromDecimalsToDecimals(amount, fromDecimals, toDecimals);
      uint256 minimumToReceive = (amountExpectedToReceive*996)/1000;
      amountReceived = ICurvePool(poolToUse).exchange_underlying(_fromIndex, _toIndex, amount, minimumToReceive);
    }

    else {
      uint256 fromDecimals = tokensDecimals[from];
      uint256 toDecimals = tokensDecimals[to];
       uint256 amountExpectedToReceive = LibUtils._convertFromDecimalsToDecimals(amount, fromDecimals,toDecimals);
      uint256 minimumToReceive = (amountExpectedToReceive*996)/1000;
      amountReceived = ICurvePool(poolToUse).exchange(_fromIndex, _toIndex, amount, minimumToReceive);
    }

    return amountReceived;
  }
  
  
  ////////////////////////////////// Management Functions //////////////////////////////////////////////////

  function increaseAllowanceCurvePools(address[] calldata tokens, address[] calldata pools) external onlyOwner {
    if(tokens.length != pools.length) {
      revert OneRingCurveRouter_Invalid_Input();
    }
    for(uint256 i = 0; i < pools.length; i++) {
      IERC20(tokens[i]).safeApprove(pools[i],0);
      IERC20(tokens[i]).safeApprove(pools[i],type(uint256).max);
    }
  }

  function withdrawERC20(address erc20Contract) external onlyOwner {
    uint256 balance = IERC20(erc20Contract).balanceOf(address(this));
    IERC20(erc20Contract).safeTransfer(msg.sender,balance);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICurveFactory {
  function get_coin_indices(address _pool, address _from, address _to) external view returns(int128,int128,bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICurvePool {
  function exchange(int128 i, int128 j, uint256 dx, uint256 _min_dy) external returns(uint256);
  function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint256);
  function get_dy(int128 i, int128 j, uint256 _dx) external view returns(uint256);
  function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IOneRingCurveRouter {
  function swap(address from, address to, uint256 amount) external returns(uint256);
  function increaseAllowanceCurvePools(address[] calldata tokens, address[] calldata pools) external;
  function withdrawERC20(address erc20Contract) external;
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
pragma solidity 0.8.9;

import {LibStorage, StrategyManagerStorage, Strategy} from "./LibStorage.sol";

/// The point of this library is to have functions that are shared accross more than one facets or contracts.

library LibUtils {

  function sms() internal pure returns (StrategyManagerStorage storage) {
    return LibStorage.strategyManagerStorage();
  }

  function ios(bytes32 position) internal pure returns (Strategy storage) {
    return LibStorage.strategyStorage(position);
  }

  // @notice It asks every strategy the balance in PLAIN_USD each one has 
  // and accumulate them in the variable balance.
  // @return the total PLAIN_USD invested in all the active strategies. 
  function _getTotalInvestedBalanceInUSD() internal returns(uint256) {
    uint256 amountStrategies = sms().numberOfStrategiesActive;
    uint256 balance;

    for (uint256 index = 0; index < amountStrategies; index++) {
      bytes32 _strategyPosition = sms().activeStrategiesArray[index];
      Strategy storage _strategyInfo = ios(_strategyPosition);

      (bool success, bytes memory data) = _strategyInfo.strategyAddress.delegatecall(
        abi.encodeWithSignature("investedBalanceInUSD(bytes32)", _strategyPosition));

      require(success, "Call Reverted");

      balance += abi.decode(data,(uint256));
    }

    return balance;
  }

  // @notice It returns the amount of underlying invested at a given strategy
  function _getAmountOfUnderlyingInvestedAtStrategy(bytes32 strategyPosition) internal returns(uint256) {
    Strategy storage _strategyInfo = ios(strategyPosition);

    (, bytes memory data) = _strategyInfo.strategyAddress.delegatecall(
       abi.encodeWithSignature("underlyingBalance(bytes32)", strategyPosition));
       
    return abi.decode(data,(uint256));
  }

  // @notice It returns the amount of PLAIN_USD that is invested at a given strategy
  function _getUSDInvestedAtStrategy(bytes32 strategyPosition) internal returns(uint256) {
    
    Strategy storage _strategyInfo = ios(strategyPosition);

    (, bytes memory data) = _strategyInfo.strategyAddress.delegatecall(
       abi.encodeWithSignature("investedBalanceInUSD(bytes32)", strategyPosition));

    return abi.decode(data,(uint256));
  }

  // @notice It returns true if the strategy is currently being used to deposit user funds
  // it returns false otherwise.
  // @dev If the strategy is active it must be at the array strategyToIndexAtArray at the Strategy Manager Storage
  function _isStrategyActive(bytes32 strategyPosition) internal view returns(bool) {
    uint256 supposedIndex = sms().strategyToIndexAtArray[strategyPosition];
    bytes32 supposedStrategyPosition = sms().activeStrategiesArray[supposedIndex];

    if(supposedStrategyPosition != strategyPosition) {
      return false;
    }

    return true;
  }

  // @notice It returns true if the strategy has been created it returns false otherwise.
  // @dev If a strategy has been created it must have a register of where its logic is.
  function _hasStrategyBeenCreated(bytes32 strategyPosition) internal view returns(bool) {
    if(ios(strategyPosition).strategyAddress == address(0)) {
      return false;
    }

    return true;
  }

  // @notice It returns the position of a strategy
  // @dev the position is keccak256("onering.{strategytype}.{protocol}.{tokensinvolved}")
  function _calculateStoragePositionForStrategy(string calldata strategyType, string calldata protocol, string calldata tokensInvolved)   
    internal pure returns(bytes32) 
  {
    bytes memory stringPosition = abi.encodePacked("onering.",strategyType,".",protocol,".",tokensInvolved); 
    return keccak256(stringPosition); 
  }
  
  // @notice Function that helps to change the decimals of an amount.
  // @dev amount must have at least (fromDecimals + 1) digits.
  // this must be validated before calling this function.
  // @param amount, the amount to change its decimals.
  // @param fromDecimals, the original number of decimals that amount has.
  // @param toDecimals, the decimals to convert amount to. 
  function _convertFromDecimalsToDecimals(uint256 amount, uint256 fromDecimals, uint256 toDecimals) 
    internal pure returns(uint256)
  {

    if (toDecimals >= fromDecimals) {
      return (amount * (10 ** (toDecimals - fromDecimals)));
    }

    else {
      return (amount) / (10 ** (fromDecimals - toDecimals));
    }
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum VaultStatus {Closed,Open}

struct VaultStorage {
  VaultStatus status; 
  uint256 slippage; 
  uint256 withdrawalFee; 
  uint256 maxDepositUSDC;       
  uint256 maxAmountOf1USDToBurn; 
  uint256 lastBlockDepositWasCalled;
  address router;  
  mapping(address => bool) dontChargeFee; 
  mapping(address => bool) isTokenEnabled; 
}

struct StrategyManagerStorage {
  uint256 totalAllocation;
  uint256 numberOfStrategiesActive;
  bytes32[] activeStrategiesArray;
  mapping(bytes32 => uint256) strategyToIndexAtArray;
}

// These variables work for masterchef strategies
// If another type of strategy is added. It will need other variables.
// We will append the variables needed to this struct.
// So the strategies are not expected to use all the variables declared here.
// name, strategyAddress, router, underlyingAddress and allocation are the only ones that are mandatory for any strategy.
struct Strategy {
  string name;      
  address strategyAddress;
  address router;
  address underlyingAddress;
  uint256 allocation;
  uint256 poolId;
  address dexRouter;
  address rewardTokenAddress;
  address masterChefContract;
  // more variables can be appended to work with other strategies types.
}

library LibStorage {
  bytes32 constant VAULT_STORAGE_POSITION =  keccak256("onering.vault.storage");
  bytes32 constant STRATEGY_MANAGER_STORAGE_POSITION = keccak256("onering.strategymanager.storage");

  address public constant USDC_CONTRACT = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
  uint256 public constant USDC_DECIMALS = 6;
  uint256 public constant ONE_USD_DECIMALS = 18;
  uint256 public constant PLAIN_USD_DECIMALS = 3;       

  function vaultStorage() internal pure returns (VaultStorage storage vs) {
    bytes32 position = VAULT_STORAGE_POSITION;
    assembly {
      vs.slot := position
    }
  }

  function strategyManagerStorage() internal pure returns (StrategyManagerStorage storage sms) {
    bytes32 position = STRATEGY_MANAGER_STORAGE_POSITION;
    assembly {
      sms.slot := position
    }
  }

  function strategyStorage(bytes32 position) internal pure returns (Strategy storage ios) {
    assembly {
      ios.slot := position
    }
  }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.vaultStorage()` to just `vs()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */

contract WithStorage {
  function vs() internal pure returns (VaultStorage storage) {
    return LibStorage.vaultStorage();
  }

  function sms() internal pure returns (StrategyManagerStorage storage) {
    return LibStorage.strategyManagerStorage();
  }

  function ios(bytes32 position) internal pure returns(Strategy storage) {
    return LibStorage.strategyStorage(position);
  }
}