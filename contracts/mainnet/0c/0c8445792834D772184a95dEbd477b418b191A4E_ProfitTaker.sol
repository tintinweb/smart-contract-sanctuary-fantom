/**
 *Submitted for verification at FtmScan.com on 2022-04-22
*/

pragma solidity >=0.8.0;

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


contract ProfitTaker {
  address owner = 0x3e522051A9B1958Aa1e828AC24Afba4a551DF37d;

  function sweep() public {
    payable(owner).call{value: address(this).balance}("");
  }

  receive() external payable {
      // 0xF491e7B69E4244ad4002BC14e878a34207E38c29

      // BTC: 15%
      address[] memory _btcPath;
      _btcPath = new address[](2);
      _btcPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
      _btcPath[1] = 0x321162Cd933E2Be498Cd2267a90534A804051b11;
      IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 3*msg.value/20}(0, _btcPath, msg.sender, block.timestamp);
      // ETH: 15%
      address[] memory _ethPath;
      _ethPath = new address[](2);
      _ethPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
      _ethPath[1] = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
      IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 3*msg.value/20}(0, _ethPath, msg.sender, block.timestamp);
      // USDC: 30%
      address[] memory _usdcPath;
      _usdcPath = new address[](2);
      _usdcPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
      _usdcPath[1] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
      IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/10)}(0, _usdcPath, msg.sender, block.timestamp);
      // BOO: 15%
      address[] memory _sPath;
      _sPath = new address[](2);
      _sPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
      _sPath[1] = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
      IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/20)}(0, _sPath, msg.sender, block.timestamp);
      // CRV: 25%
      address[] memory _crvPath;
      _crvPath = new address[](2);
      _crvPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
      _crvPath[1] = 0x1E4F97b9f9F913c46F1632781732927B9019C68b;
      IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/20)}(0, _crvPath, msg.sender, block.timestamp);
  }

  fallback() external payable {
    // BTC: 15%
    address[] memory _btcPath;
    _btcPath = new address[](2);
    _btcPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    _btcPath[1] = 0x321162Cd933E2Be498Cd2267a90534A804051b11;
    IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 3*msg.value/20}(0, _btcPath, msg.sender, block.timestamp);
    // ETH: 15%
    address[] memory _ethPath;
    _ethPath = new address[](2);
    _ethPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    _ethPath[1] = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 3*msg.value/20}(0, _ethPath, msg.sender, block.timestamp);
    // USDC: 30%
    address[] memory _usdcPath;
    _usdcPath = new address[](2);
    _usdcPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    _usdcPath[1] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/10)}(0, _usdcPath, msg.sender, block.timestamp);
    // BOO: 15%
    address[] memory _sPath;
    _sPath = new address[](2);
    _sPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    _sPath[1] = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/20)}(0, _sPath, msg.sender, block.timestamp);
    // CRV: 25%
    address[] memory _crvPath;
    _crvPath = new address[](2);
    _crvPath[0] = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    _crvPath[1] = 0x1E4F97b9f9F913c46F1632781732927B9019C68b;
    IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29).swapExactETHForTokensSupportingFeeOnTransferTokens{value: (3*msg.value/20)}(0, _crvPath, msg.sender, block.timestamp);
  }
}