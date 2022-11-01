/**
 *Submitted for verification at FtmScan.com on 2022-11-01
*/

// SPDX-License-Identifier: IDGAF
pragma solidity >=0.8.9;

interface ISwapRouter {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract SwapInfo {

    ISwapRouter public SoulSwapRouter;
    ISwapRouter public SpookySwapRouter;
    ISwapRouter public SpiritSwapRouter;

    constructor(
        address _soulRouter,
        address _spookyRouter,
        address _spiritRouter
        ) {
            SoulSwapRouter = ISwapRouter(_soulRouter);
            SpookySwapRouter = ISwapRouter(_spookyRouter);
            SpiritSwapRouter = ISwapRouter(_spiritRouter);
    }
   
    function getAmountsIn(uint amountOut, address[] memory path) public view returns(uint[6] memory _data) {
        uint[] memory amounts;

        amounts = SoulSwapRouter.getAmountsIn(amountOut, path);
        _data[0] = amounts[0];
        _data[1] = amounts[1];

        amounts = SpookySwapRouter.getAmountsIn(amountOut, path);
        _data[2] = amounts[0];
        _data[3] = amounts[1];

        amounts = SpiritSwapRouter.getAmountsIn(amountOut, path);
        _data[4] = amounts[0];
        _data[5] = amounts[1];   
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns(uint[6] memory _data) {
        uint[] memory amounts;

        amounts = SoulSwapRouter.getAmountsOut(amountIn, path);
        _data[0] = amounts[0];
        _data[1] = amounts[1];

        amounts = SpookySwapRouter.getAmountsOut(amountIn, path);
        _data[2] = amounts[0];
        _data[3] = amounts[1];

        amounts = SpiritSwapRouter.getAmountsOut(amountIn, path);
        _data[4] = amounts[0];
        _data[5] = amounts[1];   
    }
}