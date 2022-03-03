/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: Arbitrage.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//import "hardhat/console.sol";

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract Recktor is Ownable {

  function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) public onlyOwner {
    IERC20(_tokenIn).approve(router, _amount);
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint deadline = block.timestamp + 300;
    uint256 amtBack1 = getAmountOutMin(router, _tokenIn, _tokenOut, _amount);
    uint256 amtMinimum = amtBack1 - ( (amtBack1 * 1)/100 );
    IUniswapV2Router(router).swapExactTokensForTokens(_amount, amtMinimum, path, address(this), deadline);
  }

  function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256 ) {
      address[] memory path;
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
      uint256 result = 0;
      try IUniswapV2Router(router).getAmountsOut(_amountIn, path) returns (uint256[] memory amountOutMins) {
      result = amountOutMins[path.length -1];
      } catch {
      }
      return result;
  }

  function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amountIn) external view returns (uint256) {
    uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amountIn);
    uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
    return amtBack2;
  }
  
  function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amountIn) external onlyOwner {
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amountIn);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

  


  function instaTrade(
      address[5] memory routers, // router0, router1, router2, router3, router4, 
      address[4] memory path, // stable ( or dead address 0x00..000 if want to avoid first swap ), a, b, c
      uint256 _amountIn

    ) external onlyOwner {


    //uint startBalance = IERC20(path[0]).balanceOf(address(this)); // stable balance
    uint tokenAInitialBalance = IERC20(path[1]).balanceOf(address(this)); // a balance
    uint tokenBInitialBalance = IERC20(path[2]).balanceOf(address(this)); // b balanccec
    uint tokenCInitialBalance = IERC20(path[3]).balanceOf(address(this)); // c balance


    uint tradeableAAmount;
    
    if(  path[0] != 0x0000000000000000000000000000000000000000 ) { 
      // if the token A is not a stable coin
      swap(routers[0], path[0], path[1], _amountIn); // STABLE -> A
      tradeableAAmount = IERC20(path[1]).balanceOf(address(this)) - tokenAInitialBalance; // trade only the A gotten from the swap
      tokenAInitialBalance = tradeableAAmount; // compare the end with the traded A amount
    } else {
      // if the token A is a stable coin
      tradeableAAmount = _amountIn; // trade the amount passed as parameter
    }

    require( tradeableAAmount > 0, "Cannot trade, insufficent A amount" );

    swap(routers[1], path[1], path[2], tradeableAAmount); // A -> B

    uint tradeableBAmount = IERC20(path[2]).balanceOf(address(this)) - tokenBInitialBalance;

    swap(routers[2], path[2], path[3], tradeableBAmount); // B -> C

    uint tradeableCAmount = IERC20(path[3]).balanceOf(address(this)) - tokenCInitialBalance;

    swap(routers[3], path[3], path[1], tradeableCAmount); // C -> A

    //uint tradeableAAmountFinal = IERC20(path[1]).balanceOf(address(this)) - tokenAInitialBalance;

    // swap(routers[4], path[1], path[0], tradeableAAmountFinal); // A -> STABLE

    require(IERC20(path[1]).balanceOf(address(this)) > tokenAInitialBalance, "Trade Reverted, No Profit Made");

  }

  function recoverEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function recoverTokens(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

}