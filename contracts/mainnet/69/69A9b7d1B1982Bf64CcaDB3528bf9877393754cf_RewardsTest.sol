/**
 *Submitted for verification at FtmScan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function transferFrom(address, address, uint) external;
    function transfer(address, uint) external;
    function approve(address, uint) external;
    function balanceOf(address) external returns (uint);
}

interface IGauge {
    function deposit(uint, uint) external;
    function withdraw(uint) external;
}

contract RewardsTest {
    address immutable owner;
    address immutable stake = 0x60a861Cd30778678E3d613db96139440Bd333143;
    address immutable gauge = 0x1d1A1871d1830D4b5087212c820E5f1252379c2c;
    uint immutable veNFT = 50740;

    mapping(address => uint) public balanceOf;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint _amount) external onlyOwner {
        IERC20(stake).transferFrom(msg.sender, address(this), _amount);
        IERC20(stake).approve(gauge, type(uint256).max);
        IGauge(gauge).deposit(_amount, veNFT);
        balanceOf[msg.sender] += _amount;
    }

    function withdraw(uint _amount) external onlyOwner {
        balanceOf[msg.sender] -= _amount;
        IGauge(gauge).withdraw(_amount);
        IERC20(stake).transfer(msg.sender, _amount);
    }

    function tf(uint _amount) external onlyOwner {
        IERC20(stake).transferFrom(msg.sender, address(this), _amount);
    }

    function st(uint _amount) external onlyOwner {
        IERC20(stake).approve(gauge, type(uint256).max);
        IGauge(gauge).deposit(_amount, veNFT);
    }

    function inc(uint _amount) external onlyOwner {
        balanceOf[msg.sender] += _amount;
    }

    function exit() external onlyOwner {
        IERC20(stake).transfer(msg.sender, IERC20(stake).balanceOf(address(this)));
    }
}