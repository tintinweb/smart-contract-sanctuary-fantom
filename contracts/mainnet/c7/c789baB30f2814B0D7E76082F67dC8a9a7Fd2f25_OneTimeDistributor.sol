/**
 *Submitted for verification at FtmScan.com on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


interface IMonsterERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract OneTimeDistributor {
    address public immutable token;
    address public immutable receiver;

    address private immutable owner;

    event Claimed(address receiver, uint256 amount);

    uint public totalSupply;
    uint public limit = 65780;

    constructor(address token_, address receiver_) {
        owner = msg.sender;

        token = token_;
        receiver = receiver_;
    }

    function claim(uint amount) external {
        require(msg.sender == owner, "Only Owner");
        require(totalSupply + amount <= limit);

        totalSupply += amount;
        require(IMonsterERC20(token).mint(receiver, amount*1e18), 'Mint failed');

        emit Claimed(receiver, amount);
    }
}