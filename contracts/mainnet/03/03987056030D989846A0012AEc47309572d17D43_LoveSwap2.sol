/**
 *Submitted for verification at FtmScan.com on 2023-03-05
*/

// File: ILiquidDriverFeeDistributor.sol



pragma solidity >=0.7.0 <0.9.0;

interface ILiquidDriverFeeDistributor {
  function claim ( address _addr ) external returns ( uint256 );
}
// File: IPancakeRouter01.sol



pragma solidity >=0.7.0 <0.9.0;

interface IPancakeRouter01 {
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
// File: IPancakeRouter02.sol



pragma solidity >=0.7.0 <0.9.0;


interface IPancakeRouter02 is IPancakeRouter01 {
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: LoveSwap2.sol



pragma solidity >=0.7.0 <0.9.0;



// import "./OpsReady.sol";


contract LoveSwap2 {
    // using coopToken for IERC20;
    address public sushiRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    // address public token = 0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C;
    address public lqdr = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    address public beets = 0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e;
    address public boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address public linspirit = 0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C;
    address public deos = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;
    address public weth = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public rs = 0x4532280A66a0c1c709f7e0c40B14b4dEA83253C1;
    // address[] memory _tokens = [0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9];
    IERC20 public _token1 = IERC20(lqdr);
    IERC20 public _token2 = IERC20(beets);
    IERC20 public _token3 = IERC20(boo);
    IERC20 public _token4 = IERC20(linspirit);
    IERC20 public _token5 = IERC20(deos);

    // address public _ops = 0xebA27A2301975FF5BF7864b99F55A4f7A457ED10;
    // address public _taskCreator = 0x0af13072280E10907911ce5d046c2DfA1B604d23;
    IPancakeRouter02 public swap = IPancakeRouter02(sushiRouter);
    ILiquidDriverFeeDistributor public liquidDriverFeeistributor = ILiquidDriverFeeDistributor(0x095010A79B28c99B2906A8dc217FC33AEfb7Db93);

    // constructor(address _ops, address _taskCreator)OpsReady(_ops, _taskCreator){
        
    // }

    // function withdraw() external {
    //     payable(rs).transfer(this.getBalance());
    // }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
    
    // function increaseCount() external onlyDedicatedMsgSender {

    //     (uint256 fee, address feeToken) = _getFeeDetails();

    //     _transfer(fee, feeToken);
    // }

    function harvest() public {
        // liquidDriverFeeistributor.claim(rs);





        // balance = _token2.balanceOf(rs);
        // require (_token2.transferFrom(rs,address(this), balance),'transfer failed');
        // _token2.approve(sushiRouter, balance);
        // _path = new address[](2);
        // _path[0] = address(_token2);
        // _path[1] = weth;
        // swap.swapExactTokensForETH({
        //     path: _path,
        //     to: rs,
        //     amountIn: balance,
        //     deadline: block.timestamp + 300,
        //     amountOutMin: 0
        // });

        // balance = _token3.balanceOf(rs);
        // require (_token3.transferFrom(rs,address(this), balance),'transfer failed');
        // _token3.approve(sushiRouter, balance);
        // _path = new address[](2);
        // _path[0] = address(_token3);
        // _path[1] = weth;
        // swap.swapExactTokensForETH({
        //     path: _path,
        //     to: rs,
        //     amountIn: balance,
        //     deadline: block.timestamp + 300,
        //     amountOutMin: 0
        // });

        // balance = _token4.balanceOf(rs);
        // require (_token4.transferFrom(rs, address(this), balance), 'transfer failed');
        // _token4.approve(sushiRouter, balance);
        // _path = new address[](2);
        // _path[0] = address(_token4);
        // _path[1] = weth;
        // swap.swapExactTokensForETH({
        //     path: _path,
        //     to: rs,
        //     amountIn: balance,
        //     deadline: block.timestamp + 300,
        //     amountOutMin: 0
        // });

        // balance = _token5.balanceOf(rs);
        // require (_token5.transferFrom(rs,address(this), balance),'transfer failed');
        // _token5.approve(sushiRouter, balance);
        // _path = new address[](2);
        // _path[0] = address(_token5);
        // _path[1] = weth;
        // swap.swapExactTokensForETH({
        //     path: _path,
        //     to: rs,
        //     amountIn: balance,
        //     deadline: block.timestamp + 300,
        //     amountOutMin: 0
        // });

        // balance = 0;
        // (uint256 fee, address feeToken) = _getFeeDetails();

        // _transfer(fee, feeToken);

        // this.withdraw();
        // this.increaseCount();
    }

     function SwapTokenToETH(address _token, address _user) public {
    
        address[] memory _path = new address[](2);
        uint256 balance = _token1.balanceOf(_user);
        IERC20 token = IERC20(_token);
        // Swaps
        require (token.transferFrom(_user,address(this), balance),'transfer failed');
        token.approve(sushiRouter, balance);
        _path = new address[](2);
        _path[0] = _token;
        _path[1] = weth;
        swap.swapExactTokensForETH({
            path: _path,
            to: rs,
            amountIn: balance,
            deadline: block.timestamp + 300,
            amountOutMin: 0
        });
    }

    function CheckTokenBalance(address _token, address _user) public view returns (bool){
        IERC20 token = IERC20(_token);
        if (token.balanceOf(_user) > 0) {
        return true;} else {return false;}
    }

}