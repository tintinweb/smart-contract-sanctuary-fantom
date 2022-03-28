//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CurveFactory {
  function get_coin_indices(address _pool, address _from, address _to) external view returns(int128,int128,bool);
}

interface CurvePools {
  function exchange(int128 i, int128 j, uint256 dx, uint256 _min_dy) external returns(uint256);
  function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint256);
  function get_dy(int128 i, int128 j, uint256 _dx) external view returns(uint256);
  function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256);
}

contract CurveRouter is Ownable {

  struct StrategyVaults {
    address addressVault;
    uint256 percentageAllocation;
  }

  // Even though the route information on what stables to exchange and
  // on which curve pool to exchange them, the deposit function is open
  // to any user, and we want to only allow certain stables and pools to be 
  // used. This is the purpose of these mappings.

  mapping(address => bool) public isStableCoinEnabled;
  mapping(address => bool) public isCurvePoolEnabled;
  mapping(address => bool) public isMetapool;

  address public constant CURVE_FACTORY = 0x686d67265703D1f124c45E33d47d794c566889Ba;

  uint256 private percentageMinimumToReceive;



  constructor(uint256 percentageMinimum) {
    percentageMinimumToReceive = percentageMinimum;
  }

  function router(
      address[] calldata pools, 
      address[] calldata _froms, 
      address[] calldata _tos,
      uint256 initialAmount
    ) external returns(uint256)
  {
    require(pools.length == _froms.length && _froms.length == _tos.length);

    uint256 amountReceived = initialAmount;
    
    for(uint256 i = 0; i < pools.length; i++) {
      address poolToUse = pools[i];
      address _fromToken = _froms[i];
      address _toToken = _tos[i];
      uint256 amountReceived = swapCurve(poolToUse, _fromToken, _toToken, amountReceived);
    }

    return amountReceived;

  }

  // Agregar chequeo de que amount sea mayor a cierta cantidad
  function swapCurve(address poolToUse, address _from, address _to, uint256 amount) internal returns(uint256 amountReceived) {
    require(isCurvePoolEnabled[poolToUse]);
    require(isStableCoinEnabled[_from]);
    require(isStableCoinEnabled[_to]);
    
    (int128 _fromIndex, int128 _toIndex,) = CurveFactory(CURVE_FACTORY).get_coin_indices(poolToUse, _from, _to);

    if(isMetapool[poolToUse]) {
      uint256 amountExpectedToReceive = CurvePools(poolToUse).get_dy_underlying(_fromIndex, _toIndex, amount);
      uint256 minimumToReceive = (amountExpectedToReceive*percentageMinimumToReceive)/100;
      amountReceived = CurvePools(poolToUse).exchange_underlying(_fromIndex, _toIndex, amount, minimumToReceive);
    } else {
      uint256 amountExpectedToReceive = CurvePools(poolToUse).get_dy(_fromIndex, _toIndex, amount);
      uint256 minimumToReceive = (amountExpectedToReceive*percentageMinimumToReceive)/100;
      amountReceived = CurvePools(poolToUse).exchange(_fromIndex, _toIndex, amount, minimumToReceive);
    }

  }

  // Curve Pools will need to transfer out, so this contract must grant approval to each pool to be able
  // to take out the tokens from this contract.
  function approveCurvePools(address[] calldata tokens, address[] calldata pools) external onlyOwner {
    require(tokens.length == pools.length);
    for(uint256 i = 0; i < pools.length; i++) {
      address tokenToApprove = tokens[i];
      address poolToBeApproved = pools[i];

      require(isStableCoinEnabled[tokenToApprove]);
      require(isCurvePoolEnabled[poolToBeApproved]);

      IERC20(tokens[i]).approve(pools[i],type(uint256).max);
    }
  }

  function addCurvePool(address[] calldata pools) external onlyOwner {
    for(uint256 i = 0; i < pools.length; i++) {
      address _CurvePool = pools[i];
      isCurvePoolEnabled[_CurvePool] = true;
    }
  }

  function disableCurvePool(address[] calldata pools) external onlyOwner {
    for(uint256 i = 0; i < pools.length; i++) {
      address _CurvePool = pools[i];
      isCurvePoolEnabled[_CurvePool] = false;
    }
  }

  function addUnderlying(address[] calldata stableCoins) external onlyOwner {
    for(uint256 i = 0; i < stableCoins.length; i++) {
      address _StableCoin = stableCoins[i];
      isStableCoinEnabled[_StableCoin] = true;
    }
  }

  function disableUnderlying(address[] calldata stableCoins) external onlyOwner {
    for(uint256 i = 0; i < stableCoins.length; i++) {
      address _StableCoin = stableCoins[i];
      isStableCoinEnabled[_StableCoin] = false;
    }
  }

  function addMetaPool(address curvePool, bool booleanValue) external onlyOwner {
    require(isCurvePoolEnabled[curvePool]);

    isMetapool[curvePool] = booleanValue;
  }

  function changeMinimumPercentage(uint256 newPercentage) external onlyOwner {
    require(newPercentage >= 85);
    percentageMinimumToReceive = newPercentage;
  }

  function withdrawERC20(address erc20Contract) external onlyOwner {
    uint256 balance = IERC20(erc20Contract).balanceOf(address(this));
    IERC20(erc20Contract).transfer(msg.sender, balance);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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