// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interface/ILiquidCryptoBridge_v1.sol";

import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapRouterETH.sol";
import "./interface/IUniswapRouterAVAX.sol";
import "./interface/IUniswapRouterCelo.sol";
import "./interface/IUniswapRouterMetis.sol";

import "./interface/IBeefyUniV2Zap.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
}

contract Basket is Ownable {
  address public bridge;
  address public beefyzap;

  string private constant SIGNING_DOMAIN = "LiquidCryptoBridge_v1-Voucher";

  mapping (address => mapping (address => uint256)) public xlpSupply;

  struct Swaper {
    address router;
    address[] path0;
    address[] path1;
    uint256 routertype;
  }

  constructor() {}

  function deposit(address account, address vault, address router, address[] calldata path, uint256 routertype, uint256 iscoin) public payable {
    _deposit(account, vault, router, path, routertype, iscoin, msg.value);    
  }

  function depositViaBridge(ILiquidCryptoBridge_v1.SwapVoucher memory voucher, uint256 fee, address account, address vault, address router, address[] calldata path, uint256 routertype, uint256 iscoin) public {
    uint256 amount = ILiquidCryptoBridge_v1(bridge).withdrawForUser(voucher, fee);
    _deposit(account, vault, router, path, routertype, iscoin, amount);
  }

  /**
   * @param routertype 1:BNB 2:ETH
   * @param iscoin 1:coin 0:token
   */
  function _deposit(address account, address vault, address router, address[] calldata path, uint256 routertype, uint256 iscoin, uint256 amount) private {
    if (iscoin == 0) {
      if (routertype == 1) {
        IUniswapRouter(router).swapExactBNBForTokens{value: amount}(0, path, address(this), block.timestamp);
      }
      else if (routertype == 2) {
        IUniswapRouterETH(router).swapExactETHForTokens{value: amount}(0, path, address(this), block.timestamp);
      }
      else if (routertype == 3) {
        IUniswapRouterAVAX(router).swapExactAVAXForTokens{value: amount}(0, path, address(this), block.timestamp);
      }
      else if (routertype == 4) {
        IUniswapRouterCelo(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
      }
      else if (routertype == 5) {
        IUniswapRouterMetis(router).swapExactMetisForTokens{value: amount}(0, path, address(this), block.timestamp);
      }
      uint256 tokenbalance = IERC20(path[1]).balanceOf(address(this));
      _approveTokenIfNeeded(path[1], address(beefyzap));
      IBeefyUniV2Zap(beefyzap).beefIn(vault, 0, path[1], tokenbalance);
    }
    else {
      IBeefyUniV2Zap(beefyzap).beefInETH{value: amount}(vault, 0);
    }
    uint256 xlpbalance = IERC20(vault).balanceOf(address(this));
    xlpSupply[vault][account] = xlpSupply[vault][account] + xlpbalance;
    // IERC20(vault).transfer(account, xlpbalance);
  }

  function moveBasket2Pool(address vault, uint256 amount) public {
    require(amount <= xlpSupply[vault][msg.sender], "Your balance is not enough");
    IERC20(vault).transfer(msg.sender, amount);
  }

  function withdraw(address account, address vault, Swaper memory swper, uint256 amount) public {
    uint256 outAmount = _withdraw(vault, swper, amount);

    (bool success1, ) = account.call{value: outAmount}("");
    require(success1, "Failed to withdraw");
  }

  function withdrawViaBridge(address account, address vault, Swaper memory swper, uint256 amount, uint256 voucherIndex, uint256 inChain, uint256 outChain, uint256 price, uint256 rate, uint256 fee) public {
    uint256 inAmount = _withdraw(vault, swper, amount);
    uint256 outAmount = inAmount * price / rate;

    ILiquidCryptoBridge_v1.SwapVoucher memory voucher = ILiquidCryptoBridge_v1.SwapVoucher(
      voucherIndex, account, inChain, inAmount, outChain, outAmount
    );
    
    ILiquidCryptoBridge_v1(bridge).depositForUser{value: inAmount}(voucher, fee);
  }

  function _withdraw(address vault, Swaper memory swper, uint256 amount) private returns(uint256) {
    _approveTokenIfNeeded(vault, address(beefyzap));
    IBeefyUniV2Zap(beefyzap).beefOut(vault, amount);

    if (swper.routertype == 1) {
      if (swper.path0.length > 1) {
        uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
        IUniswapRouter(swper.router).swapExactTokensForBNB(t0amount, 0, swper.path0, address(this), block.timestamp);
      }
      if (swper.path1.length > 1) {
        uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
        IUniswapRouter(swper.router).swapExactTokensForBNB(t1amount, 0, swper.path1, address(this), block.timestamp);
      }
    }
    else if (swper.routertype == 2) {
      if (swper.path0.length > 1) {
        uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
        IUniswapRouterETH(swper.router).swapExactTokensForETH(t0amount, 0, swper.path0, address(this), block.timestamp);
      }
      if (swper.path1.length > 1) {
        uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
        IUniswapRouterETH(swper.router).swapExactTokensForETH(t1amount, 0, swper.path1, address(this), block.timestamp);
      }
    }
    else if (swper.routertype == 3) {
      if (swper.path0.length > 1) {
        uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
        IUniswapRouterAVAX(swper.router).swapExactTokensForAVAX(t0amount, 0, swper.path0, address(this), block.timestamp);
      }
      if (swper.path1.length > 1) {
        uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
        IUniswapRouterAVAX(swper.router).swapExactTokensForAVAX(t1amount, 0, swper.path1, address(this), block.timestamp);
      }
    }
    else if (swper.routertype == 4) {
      if (swper.path0.length > 1) {
        uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
        IUniswapRouterCelo(swper.router).swapExactTokensForTokens(t0amount, 0, swper.path0, address(this), block.timestamp);
      }
      if (swper.path1.length > 1) {
        uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
        IUniswapRouterCelo(swper.router).swapExactTokensForTokens(t1amount, 0, swper.path1, address(this), block.timestamp);
      }
    }
    else if (swper.routertype == 5) {
      if (swper.path0.length > 1) {
        uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
        IUniswapRouterMetis(swper.router).swapExactTokensForMetis(t0amount, 0, swper.path0, address(this), block.timestamp);
      }
      if (swper.path1.length > 1) {
        uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
        IUniswapRouterMetis(swper.router).swapExactTokensForMetis(t1amount, 0, swper.path1, address(this), block.timestamp);
      }
    }

    address weth = swper.path0[swper.path0.length-1];
    uint256 wethBalance = IERC20(weth).balanceOf(address(this));
    IWETH(weth).withdraw(wethBalance);

    return wethBalance;
  }

  function setBridge(address addr) public onlyOwner {
    bridge = addr;
  }

  function setBeefyzap(address addr) public onlyOwner {
    beefyzap = addr;
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterMetis {
    function swapExactMetisForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForMetis(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterCelo {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterAVAX {
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IUniswapRouter {
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCryptoBridge_v1 {
  struct SwapVoucher {
    uint256 relayindex;
    address account;
    uint256 inChain;
    uint256 inAmount;
    uint256 outChain;
    uint256 outAmount;
  }

  function depositForUser(SwapVoucher calldata voucher, uint256 fee) external payable;
  function withdrawForUser(SwapVoucher calldata voucher, uint256 fee) external returns(uint256);
  function refundFaildVoucher(uint256 index, uint256 amount, uint256 fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IBeefyUniV2Zap {
    function beefIn (address beefyVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external;
    function beefInETH (address beefyVault, uint256 tokenAmountOutMin) external payable;
    function beefOut (address beefyVault, uint256 withdrawAmount) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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