/**
 *Submitted for verification at FtmScan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function approve(address a, uint256 b) external;
    function balanceOf(address a) external returns (uint256);
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Swap {
    IRouter spookyRouter = IRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

    IERC20 usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 tor  = IERC20(0x74E23dF9110Aa9eA0b6ff2fAEE01e740CA1c642e);
    IERC20 hec  = IERC20(0x74E23dF9110Aa9eA0b6ff2fAEE01e740CA1c642e);

    address public admin;

    uint256 ratioUsdc = 328;
    uint256 ratioTor  = 671;

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "!admin");
        _;
    }

    function swap(uint256 usdcAmt, uint256 torAmt, uint256 usdcAmtOut, uint256 torAmtOut) external onlyAdmin {
        usdc.transferFrom(msg.sender, address(this), usdcAmt);
        usdc.approve(address(spookyRouter), usdcAmt);

        tor.transferFrom(msg.sender, address(this), torAmt);
        tor.approve(address(spookyRouter), torAmt);

        address[] memory pathUsdc;
        pathUsdc = new address[](2);
        pathUsdc[0] = address(usdc);
        pathUsdc[1] = address(hec);

        spookyRouter.swapExactTokensForTokens(
            usdcAmt,
            usdcAmtOut,
            pathUsdc,
            admin,
            block.timestamp
        );

        address[] memory pathTor;
        pathTor = new address[](2);
        pathTor[0] = address(tor);
        pathTor[1] = address(hec);

        spookyRouter.swapExactTokensForTokens(
            torAmt,
            torAmtOut,
            pathTor,
            admin,
            block.timestamp
        );

        require(usdc.balanceOf(address(this)) == 0, "!0");
        require(tor.balanceOf(address(this)) == 0, "!0");
        require(hec.balanceOf(address(this)) == 0, "!0");
    }
}