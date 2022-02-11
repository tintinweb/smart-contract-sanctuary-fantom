// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

interface IPrinterManager {
  function setPrinterFees(
      address _token,
      uint256 _devFee, 
      uint256 _marketingFee, 
      uint256 _reflectionFee, 
      uint256 _liquidityFee,
      uint256 _feeDenominator
  ) external;
}

contract Compounder is Ownable {

  uint256 internal devFee = 150;
  uint256 internal marketingFee = 150;

  uint256 internal liquidityFee = 400;
  uint256 internal reflectionFee = 800;

  uint256 internal feeDenominator = 10000;

  bool public isActive; 

  IERC20 public WFTM;

  IERC20 public GSCARABp; 
  IERC20 public SCARAp; 

  IUniswapV2Router02 public spiritRouter;
  IUniswapV2Router02 public spookyRouter;

  IPrinterManager public manager; 

  mapping(address => bool) public acceptedTokens; 

  constructor(
    IERC20 wftm_,
    IERC20 gscarabp_,
    IERC20 scarap_,
    IUniswapV2Router02 spiritRouter_, 
    IUniswapV2Router02 spookyRouter_,
    IPrinterManager manager_
  ) {
    WFTM = wftm_;
    GSCARABp = gscarabp_; 
    SCARAp = scarap_; 
    spiritRouter = spiritRouter_; 
    spookyRouter = spookyRouter_; 
    manager = manager_;

    isActive = true;
  }

  function setActive(bool _newValue) external onlyOwner{
    isActive = _newValue;
  }

  function setToken(address newTokenToAccept) external onlyOwner {
    acceptedTokens[newTokenToAccept] = true; 
  }

  function setTokens(address [] memory newTokensToAccept) external onlyOwner {
    for(uint256 i = 0; i < newTokensToAccept.length; i++) {
      acceptedTokens[newTokensToAccept[i]] = true; 
    }
  }

  function setDefaultFees(uint256 _devFee, uint256 _marketingFee, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _feeDenominator) external onlyOwner {
    devFee = _devFee;
    marketingFee = _marketingFee;
    reflectionFee = _reflectionFee;
    liquidityFee = _liquidityFee;
    feeDenominator = _feeDenominator;
  }

  function resetTokenFees(address _token) internal {
    manager.setPrinterFees(_token, devFee, marketingFee, reflectionFee, liquidityFee, feeDenominator);
  }

  function disableTokenFees(address _token) internal {
    manager.setPrinterFees(_token, 0, 0, 0, 0, feeDenominator);
  }

  function getSwapAmountOut(
    uint256 amountIn,
    IERC20 tokenIn,
    IERC20 tokenOut
  ) public view returns(uint256, bool) {
    require(acceptedTokens[address(tokenIn)], 'Token In not allowed');
    require(acceptedTokens[address(tokenOut)], 'Token Out not allowed');

    uint256 amountOutSingle = getSwapAmountOutSingle(amountIn, tokenIn, tokenOut);
    uint256 amountOutHop = getSwapAmountOutHop(amountIn, tokenIn, tokenOut);
    
    if(amountOutHop > amountOutSingle) {
      return (amountOutHop, true); 
    } else {
      return (amountOutSingle, false); 
    }
    
  }

  function compoundReflectionsToToken(
      uint256 amountIn,
      IERC20 tokenIn,
      IERC20 tokenOut
  ) external onlyWhenActive onlyTokenHolders {    
      // Only accept tokens we set; 
      require(acceptedTokens[address(tokenIn)], 'Token In not allowed');
      require(acceptedTokens[address(tokenOut)], 'Token Out not allowed');

      // Pull tokens from msg.sender; 
      tokenIn.transferFrom(msg.sender, address(this), amountIn);
      require(tokenIn.balanceOf(address(this)) == amountIn, 'Contract did not pull tokens');

      disableTokenFees(address(tokenOut));

      // Swap reflection to WFTM; 

      // Aprove the tokens to the router; 
      tokenIn.approve(address(spiritRouter), amountIn);
      (, bool doHop) = getSwapAmountOut(amountIn, tokenIn, tokenOut);
      if(doHop) {

        address[] memory path = new address[](2);
          path[0] = address(tokenIn);
          path[1] = address(WFTM);

        // swap token to WFTM;
        spiritRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 
            1, 
            path,
            address(this),
            (block.timestamp)
        );
        uint256 amountWFTMout = WFTM.balanceOf(address(this));
        if(tokenOut == SCARAp) {
          
          WFTM.approve(address(spiritRouter), amountWFTMout);

          address[] memory tokenPath = new address[](2);
            tokenPath[0] = address(WFTM);
            tokenPath[1] = address(tokenOut);

          spiritRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountWFTMout, 
            1, 
            tokenPath,
            address(this),
            (block.timestamp)
          );

        

        } else if (tokenOut == GSCARABp) {

          WFTM.approve(address(spookyRouter), amountWFTMout);

          address[] memory tokenPath = new address[](2);
            tokenPath[0] = address(WFTM);
            tokenPath[1] = address(tokenOut);

          spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountWFTMout, 
            1, 
            tokenPath,
            msg.sender,
            (block.timestamp)
          );

        }

      } else {

        address[] memory path = new address[](3);
          path[0] = address(tokenIn);
          path[1] = address(WFTM);
          path[2] = address(tokenOut);

        spiritRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          amountIn, 
          1, 
          path,
          msg.sender,
          (block.timestamp)
        ); 
  
      }
    
      resetTokenFees(address(tokenOut));
  }

  function getSwapAmountOutHop(
    uint256 amountIn, 
    IERC20 tokenIn, 
    IERC20 tokenOut
  ) internal view returns(uint256) {

    address[] memory path0 = new address[](2);
      path0[0] = address(tokenIn);
      path0[1] = address(WFTM);

    address[] memory path1 = new address[](2);
      path1[0] = address(WFTM);
      path1[1] = address(tokenOut);
    
    uint256[] memory amountsOut0 = spiritRouter.getAmountsOut(amountIn, path0);
    
    uint256[] memory amountsOut1;
    if(tokenOut == GSCARABp) {
      amountsOut1 = spookyRouter.getAmountsOut(amountsOut0[amountsOut0.length -1], path1);

    } else if(tokenOut == SCARAp) {
      amountsOut1 = spiritRouter.getAmountsOut(amountsOut0[amountsOut0.length -1], path1);
    }

    return amountsOut1[amountsOut1.length -1];
  }

  function getSwapAmountOutSingle(
    uint256 amountIn, 
    IERC20 tokenIn, 
    IERC20 tokenOut
  ) internal view returns(uint256) {

    address[] memory path = new address[](3);
      path[0] = address(tokenIn);
      path[1] = address(WFTM);
      path[2] = address(tokenOut);

    uint256[] memory amountsOut;
    
    if(tokenOut == GSCARABp) {
      amountsOut = spookyRouter.getAmountsOut(amountIn, path);

    } else if(tokenOut == SCARAp) {
      amountsOut = spiritRouter.getAmountsOut(amountIn, path);
    }
    
    return amountsOut[amountsOut.length -1];
  }

  modifier onlyWhenActive() {
    require(
     isActive == true, 'Swapper not active'
    );
    _;
  }

  modifier onlyTokenHolders() {
    require(
      GSCARABp.balanceOf(msg.sender) > 0 || SCARAp.balanceOf(msg.sender) > 0, 'Only for token Holders'
    );
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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