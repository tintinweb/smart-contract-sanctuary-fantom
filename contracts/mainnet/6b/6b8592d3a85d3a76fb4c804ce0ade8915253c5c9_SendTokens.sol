/**
 *Submitted for verification at FtmScan.com on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SendTokens {
    
function SendAirdrop(address mytoken, address[] calldata where, uint256[] calldata amount) external {
        IERC20 token = IERC20(mytoken);
        uint256 total = 0;
        for (uint256 i = 0; i < where.length; i++)
            total += amount[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < where.length; i++)
            require(token.transfer(where[i], amount[i]));
    }






}