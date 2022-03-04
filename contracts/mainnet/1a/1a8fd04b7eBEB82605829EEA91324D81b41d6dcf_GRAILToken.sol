// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/tokens/IERC20Mintable.sol";
import "./interfaces/tokens/IRegularToken.sol";
import "./interfaces/IDividends.sol";
import "./abstracts/ERC20/ERC20BurnSupply.sol";
import "./abstracts/ERC20/WrapERC20WithPenalty.sol";

contract GRAILToken is
  Ownable,
  ERC20("Excalibur dividend token", "GRAIL"),
  ERC20BurnSupply,
  WrapERC20WithPenalty,
  IERC20Mintable
{
  using SafeMath for uint256;

  address private _masterContractAddress;
  address private _bondingFactoryContractAddress;
  IDividends private _dividendsContract;

  uint256 public constant MAXIMUM_PENALTY_PERIOD = 14 days;
  uint256 public constant MINIMUM_PENALTY_PERIOD = 3 days;

  constructor(
    uint256 penaltyPeriod,
    uint256 penaltyMin,
    uint256 penaltyMax,
    IRegularToken regularTokenContract
  ) WrapERC20WithPenalty(penaltyPeriod, penaltyMin, penaltyMax, regularTokenContract) {}

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event MasterContractAddressInitialized(address masterContractAddress);
  event BondingFactoryContractAddressInitialized(address BondingFactoryContractAddress);
  event DividendsContractAddressInitialized(address dividendsContractAddress);
  event UnwrapPenaltyPeriodUpdated(uint256 previousUnwrapPenaltyPeriod, uint256 newUnwrapPenaltyPeriod);

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /*
   * @dev Throws if called by any account other than the master
   */
  modifier onlyMasterOrBondingFactory() {
    require(
      _isMaster() || _isBondingFactory(),
      "GRAILToken: caller is not the master or the exc converter factory"
    );
    _;
  }

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  function masterContractAddress() external view returns (address) {
    return _masterContractAddress;
  }

  function BondingFactoryContractAddress() external view returns (address) {
    return _bondingFactoryContractAddress;
  }

  function dividendsContractAddress() external view returns (address) {
    return address(_dividendsContract);
  }

  /****************************************************/
  /****************** INTERNAL VIEWS ******************/
  /****************************************************/

  /**
   * @dev Returns true if caller is the Master contract
   */
  function _isMaster() internal view returns (bool) {
    return msg.sender == _masterContractAddress;
  }

  /**
   * @dev Returns true if caller is the BondingFactory contract
   */
  function _isBondingFactory() internal view returns (bool) {
    return msg.sender == _bondingFactoryContractAddress;
  }

  /*****************************************************************/
  /****************** EXTERNAL OWNABLE FUNCTIONS  ******************/
  /*****************************************************************/

  /**
   * @dev Sets Master contract address
   *
   * Can only be initialize one time
   * Must only be called by the owner
   */
  function initializeMasterContractAddress(address master) external onlyOwner {
    require(_masterContractAddress == address(0), "GRAILToken: master already initialized");
    require(master != address(0), "GRAILToken: master initialized to zero address");
    _masterContractAddress = master;
    emit MasterContractAddressInitialized(master);
  }

  /**
   * @dev Sets EXC bonding factory contract address
   *
   * Can only be initialize one time
   * Must only be called by the owner
   */
  function initializeBondingFactoryContractAddress(address bondingFactoryContractAddress) external onlyOwner {
    require(_bondingFactoryContractAddress == address(0), "GRAILToken: BondingFactory already initialized");
    require(
      bondingFactoryContractAddress != address(0),
      "GRAILToken: BondingFactory initialized to zero address"
    );
    _bondingFactoryContractAddress = bondingFactoryContractAddress;
    emit BondingFactoryContractAddressInitialized(bondingFactoryContractAddress);
  }

  /**
   * @dev Sets Dividends contract address
   *
   * Can only be initialize one time
   * Must only be called by the owner
   */
  function initializeDividendsContract(IDividends dividendsContract) external onlyOwner {
    require(address(_dividendsContract) == address(0), "GRAILToken: dividends already initialized");
    require(address(dividendsContract) != address(0), "GRAILToken: dividends initialized to zero address");
    _dividendsContract = dividendsContract;
    emit DividendsContractAddressInitialized(address(dividendsContract));
  }

  /**
   * @dev Updates the unwrapPenaltyPeriod
   *
   * Must be a value between MINIMUM_PENALTY_PERIOD and MAXIMUM_PENALTY_PERIOD
   */
  function updateUnwrapPenaltyPeriod(uint256 penaltyPeriod) external onlyOwner {
    require(penaltyPeriod <= MAXIMUM_PENALTY_PERIOD, "GRAILToken: _unwrapPenaltyPeriod mustn't exceed maximum");
    require(penaltyPeriod >= MINIMUM_PENALTY_PERIOD, "GRAILToken: _unwrapPenaltyPeriod mustn't exceed minimum");
    uint256 prevPenalityPeriod = _unwrapPenaltyPeriod;
    _unwrapPenaltyPeriod = penaltyPeriod;
    emit UnwrapPenaltyPeriodUpdated(prevPenalityPeriod, _unwrapPenaltyPeriod);
  }

  /**
   * @dev Creates `amount` token to `account`
   *
   * Can only be called by the MasterChef or BondingFactory
   * See {ERC20-_mint}
   */
  function mint(address account, uint256 amount) external override onlyMasterOrBondingFactory returns (bool) {
    _mint(account, amount);
    return true;
  }

  /**
   * @dev Destroys `amount` tokens from the caller
   *
   * See {ERC20BurnSupply-_burn}
   */
  function burn(uint256 amount) external override {
    _burn(_msgSender(), amount);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  /**
   * @dev Overrides _transfer function
   *
   * Updates dividendsContract user data if set
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    uint256 senderPreviousBalance = balanceOf(sender);
    uint256 recipientPreviousBalance = balanceOf(recipient);
    super._transfer(sender, recipient, amount);
    if (address(_dividendsContract) != address(0)) {
      _dividendsContract.updateUser(sender, senderPreviousBalance, totalSupply());
      _dividendsContract.updateUser(recipient, recipientPreviousBalance, totalSupply());
    }
  }

  /**
   * @dev Overrides _burn function
   *
   * Updates dividendsContract user data if set
   */
  function _burn(address account, uint256 amount) internal override(ERC20, ERC20BurnSupply) {
    uint256 previousTotalSupply = totalSupply();
    uint256 accountPreviousBalance = balanceOf(account);
    ERC20BurnSupply._burn(account, amount);
    if (address(_dividendsContract) != address(0)) {
      _dividendsContract.updateUser(account, accountPreviousBalance, previousTotalSupply);
    }
  }

  /**
   * @dev Overrides _mint function
   *
   * Updates dividendsContract user data if set
   */
  function _mint(address account, uint256 amount) internal override {
    uint256 previousTotalSupply = totalSupply();
    uint256 accountPreviousBalance = balanceOf(account);
    super._mint(account, amount);
    if (address(_dividendsContract) != address(0)) {
      _dividendsContract.updateUser(account, accountPreviousBalance, previousTotalSupply);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, WrapERC20WithPenalty) {
    WrapERC20WithPenalty._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./IERC20Mintable.sol";

interface IRegularToken is IERC20Mintable {
  function divTokenContractAddress() external view returns (address);

  function initializeDivTokenContractAddress(address _divToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external returns (bool);

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20BurnSupply is IERC20 {
  function burnSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IDividends {
  function distributedTokensLength() external view returns (uint256);

  function distributedToken(uint256 index) external view returns (address);

  function isDistributedToken(address token) external view returns (bool);

  function updateUser(address userAddress, uint256 previousUserGrailBalance, uint256 previousTotalSupply) external;

  function addDividendsToPending(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./ERC20AvgReceiveTime.sol";
import "../../interfaces/tokens/IRegularToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * ERC20 implementation allowing to swap (unwrap) the current (=wrapped) token to regularToken (=unwrapped) with a
 * penalty based on average receive time
 *
 * Requires the authorization to mint the regularToken
 */
abstract contract WrapERC20WithPenalty is ERC20, ERC20AvgReceiveTime, ReentrancyGuard {
  using SafeMath for uint256;

  IRegularToken public immutable regularTokenAddress;

  /**
   * @dev Period in seconds during which the penalty to unwrap is decreasing, from _unwrapPenaltyMax to
   * _unwrapPenaltyMin
   */
  uint256 internal _unwrapPenaltyPeriod;

  /**
   * @dev Wrapped token to regular token unwrap max penalty
   * This penalty is intended to decrease over holding time
   * Example :
   *  - if _unwrapPenaltyMax = 30*1e10 (=30%). At maximum penalty : 1 unwrapped = 0.7 regular
   */
  uint256 internal _unwrapPenaltyMax;

  /**
   * @dev Wrapped token to regular token unwrap min penalty
   * A user's penalty to unwrap will be at this minimum once the _unwrapPenaltyPeriod is over
   * Example :
   *  - if _unwrapPenaltyMin = 10*1e10 (=10%). At minimum penalty : 1 unwrapped = 0.9 regular
   */
  uint256 internal _unwrapPenaltyMin;

  /**
   * @dev Initializes the contract of the token to unwrap to
   */
  constructor(
    uint256 penaltyPeriod,
    uint256 penaltyMin,
    uint256 penaltyMax,
    IRegularToken regularToken
  ) {
    require(penaltyMax >= _unwrapPenaltyMin && penaltyMax <= 100 && penaltyMax <= 100, "WrapERC20WithPenalty: invalid penalty min/max");
    _unwrapPenaltyPeriod = penaltyPeriod;
    _unwrapPenaltyMin = penaltyMin.mul(1e10);
    _unwrapPenaltyMax = penaltyMax.mul(1e10);
    regularTokenAddress = regularToken;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Unwrap(address account, uint256 wrapTokenAmount, uint256 unwrappedTokenAmount);

  /**************************************************/
  /****************** PUBLIC VIEWS ******************/
  /**************************************************/

  function unwrapPenaltyPeriod() external view returns (uint256) {
    return _unwrapPenaltyPeriod;
  }

  function unwrapPenaltyMin() external view returns (uint256) {
    return _unwrapPenaltyMin.div(1e10);
  }

  function unwrapPenaltyMax() external view returns (uint256) {
    return _unwrapPenaltyMax.div(1e10);
  }

  /**
   * @dev Calculates the current unwrapping penalty (* 1e10) for a given account
   * The penalty decreases over time (based on holding duration) from unwrapPenaltyMax% initially, to unwrapPenaltyMin%
   * when unwrapPenaltyPeriod is over
   */
  function getAccountPenalty(address account) public view returns (uint256) {
    uint256 avgHoldingDuration = getAvgHoldingDuration(account);

    // check if unwrapPenaltyPeriod has been exceeded
    if (avgHoldingDuration >= _unwrapPenaltyPeriod) {
      return _unwrapPenaltyMin;
    }

    if (avgHoldingDuration > 0) {
      return
        _unwrapPenaltyMax.sub(
          (_unwrapPenaltyMax.sub(_unwrapPenaltyMin)).mul(avgHoldingDuration).div(_unwrapPenaltyPeriod)
        );
    }

    return _unwrapPenaltyMax;
  }

  /**
   * @dev Returns the amount of regular token an account will get when unwrapping "amount" of wrapped token
   *
   * This function assumes that the amount is equal or lower than the current account's balance, else the result
   * won't be accurate
   */
  function getExpectedUnwrappedTokenAmount(address account, uint256 amount) public view returns (uint256) {
    uint256 currentPenalty = getAccountPenalty(account);
    if (currentPenalty > 0) {
      uint256 max = 1e12;
      return amount.mul(max.sub(currentPenalty)).div(1e12);
    }
    return amount;
  }

  /****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
  /****************************************************************/

  /**
   * @dev Unwraps a given amount of wrapped token to regular token
   *
   * Wrapped token amount is burnt
   * Regular token is minted to the user account
   */
  function unwrap(uint256 amount) external nonReentrant {
    address account = msg.sender;

    require(balanceOf(account) >= amount, "WrapERC20WithPenalty: unwrap amount exceeds balance");
    require(amount > 0, "WrapERC20WithPenalty: unwrap amount 0");

    uint256 unwrappedTokenAmount = getExpectedUnwrappedTokenAmount(account, amount);

    emit Unwrap(account, amount, unwrappedTokenAmount);
    _burn(account, amount);
    regularTokenAddress.mint(account, unwrappedTokenAmount);
  }

  /********************************************************/
  /****************** INTERNAL FUNCTIONS ******************/
  /********************************************************/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20AvgReceiveTime) {
    ERC20AvgReceiveTime._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/tokens/IERC20BurnSupply.sol";

/**
 * ERC20 implementation including burn supply management
 */
abstract contract ERC20BurnSupply is ERC20, IERC20BurnSupply {
  using SafeMath for uint256;

  uint256 private _burnSupply;

  function burnSupply() external view override returns (uint256) {
    return _burnSupply;
  }

  /**
   * @dev Extends default ERC20 to add amount to burnSupply
   */
  function _burn(address account, uint256 amount) internal virtual override {
    super._burn(account, amount);
    _burnSupply = _burnSupply.add(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * ERC20 implementation handling the average timestamp at which an account received his tokens
 */
abstract contract ERC20AvgReceiveTime is ERC20 {
  using SafeMath for uint256;

  event AvgReceiveTimeUpdated(address account, uint256 divTokenAmount, bool isSender, uint256 result);

  // Average time at which each account has received tokens, updated into _beforeTokenTransfer hook
  mapping(address => uint256) private _accountsAvgReceiveTime;

  /**
   * @dev Returns the average time at which an account received his tokens
   */
  function avgReceiveTimeOf(address account) public view returns (uint256) {
    return _accountsAvgReceiveTime[account];
  }

  /**
   * @dev Returns the average duration in seconds during which an account has held his tokens
   */
  function getAvgHoldingDuration(address account) public view returns (uint256) {
    uint256 avgReceiveTime = _accountsAvgReceiveTime[account];
    if (avgReceiveTime > 0) {
      return _currentBlockTimestamp().sub(avgReceiveTime);
    }
    return 0;
  }

  /**
   * @dev Pre-calculates the average received time of account tokens
   */
  function _getAccountAvgReceiveTime(
    address account,
    uint256 divTokenAmount,
    bool isSender
  ) internal view returns (uint256) {
    uint256 currentBlockTimestamp = _currentBlockTimestamp();

    // balance before transfer is done (not including divTokenAmount)
    uint256 userBalance = balanceOf(account);
    uint256 accountAvgReceiveTime = avgReceiveTimeOf(account);

    if (userBalance == 0) {
      return currentBlockTimestamp;
    }

    // account is sending divTokenAmount tokens
    if (isSender) {
      // check if user is sending all of his tokens
      if (userBalance == divTokenAmount) {
        // reinitialize "account"s avgReceiveTime
        return 0;
      } else {
        return accountAvgReceiveTime;
      }
    }

    // account is receiving divTokenAmount tokens
    uint256 previousTimeWeight = accountAvgReceiveTime.mul(userBalance);
    uint256 currentTimeWeight = currentBlockTimestamp.mul(divTokenAmount);
    uint256 avgReceiveTime = (previousTimeWeight.add(currentTimeWeight)).div(userBalance.add(divTokenAmount));

    // should never happen
    if (avgReceiveTime > currentBlockTimestamp) {
      return currentBlockTimestamp;
    }

    return avgReceiveTime;
  }

  /**
   * @dev Updates accountsAvgReceiveTime for each affected account on every transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (amount == 0 || from == to) {
      return;
    }

    if (from != address(0)) {
      // "from" is sending "amount" of tokens to "to"
      _accountsAvgReceiveTime[from] = _getAccountAvgReceiveTime(from, amount, true);
      emit AvgReceiveTimeUpdated(from, amount, true, _accountsAvgReceiveTime[from]);
    }

    if (to != address(0)) {
      // "to" is receiving "amount" of tokens from "from"
      _accountsAvgReceiveTime[to] = _getAccountAvgReceiveTime(to, amount, false);
      emit AvgReceiveTimeUpdated(to, amount, false, _accountsAvgReceiveTime[to]);
    }
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}