/**
 *Submitted for verification at FtmScan.com on 2022-03-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract BasicSwap {
    address private immutable owner;
    IWETH private constant WETH = IWETH(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    }

    function swapFromToken(uint256 _amountIn, address _tokenIn, address _pairAddress, bytes memory payload) external {
        IERC20 TokenInERC20 = IERC20(_tokenIn);
        uint256 _tokenBalanceBefore = TokenInERC20.balanceOf(msg.sender);
        TokenInERC20.transfer(_pairAddress, _amountIn);
        (bool _success, bytes memory _response) = _pairAddress.call(payload);
        require(_success); _response;
        uint256 _tokenBalanceAfter = TokenInERC20.balanceOf(msg.sender);
        require(_tokenBalanceAfter > _tokenBalanceBefore);
    }

    function swapFromETH(uint256 _amountIn, address _pairAddress, bytes memory payload) external {
        uint256 _wethBalanceBefore = WETH.balanceOf(msg.sender);
        WETH.transfer(_pairAddress, _amountIn);
        (bool _success, bytes memory _response) = _pairAddress.call(payload);
        require(_success); _response;
        uint256 _wethBalanceAfter = WETH.balanceOf(msg.sender);
        require(_wethBalanceAfter > _wethBalanceBefore);
    }
}