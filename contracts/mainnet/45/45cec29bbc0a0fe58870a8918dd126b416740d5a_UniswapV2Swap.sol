/**
 *Submitted for verification at FtmScan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UniswapV2Swap {
    address public owner;
    address private constant ROUTER_FUNI = 0x67A937eA41Cd05ec8c832a044afC0100F30Aa4b5; // Funi router
    address private constant ROUTER_SPRT = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52; // Spiritswap router
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private constant FUSD = 0xAd84341756Bf337f5a0164515b1f6F993D194E1f;
    address private constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    IUniswapV2Router private router_funi = IUniswapV2Router(ROUTER_FUNI);
    IUniswapV2Router private router_sprt = IUniswapV2Router(ROUTER_SPRT);
    IERC20 private wftm = IERC20(WFTM);
    IERC20 private fusd = IERC20(FUSD);
    IERC20 private usdc = IERC20(USDC);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }

    // Swap FUSD to WFTM to USDC
    function swap(uint _a0in, uint _a1om, uint _a2om)
        external onlyOwner returns (uint _a2ou)
    {
        fusd.transferFrom(msg.sender, address(this), _a0in);
        fusd.approve(address(router_funi), _a0in);

        address[] memory path;
        path = new address[](2);
        path[0] = FUSD;
        path[1] = WFTM;

        uint[] memory amounts = router_funi.swapExactTokensForTokens(
            _a0in,_a1om,path,address(this),block.timestamp+60);

        uint _a1in = amounts[1];
        wftm.approve(address(router_sprt), _a1in);

        path[0] = WFTM;
        path[1] = USDC;
        amounts = router_sprt.swapExactTokensForTokens(
            _a1in,_a2om,path,msg.sender,block.timestamp+60);

        // amounts[0] = WFTM amount, amounts[1] = FUSD amount
        return amounts[1];
    }
}

interface IUniswapV2Router {
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
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWFTM is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}