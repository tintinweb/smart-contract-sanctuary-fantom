// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IETF {
    function invest() external payable;

    function withdraw(uint256 _amount) external;

    function balanceOf(address _user) external view returns (uint256);

    function harvest() external;

    function userExpectedReturn(address _user) external view returns (uint256);
}

contract MASTER_ETF {
    mapping(address => uint256) public userToETF1Balance;
    mapping(address => uint256) public userToETF2Balance;
    IETF ETF1;
    IETF ETF2;

    constructor(address _ETF1, address _ETF2) {
        ETF1 = IETF(_ETF1);
        ETF2 = IETF(_ETF2);
    }

    function invest() public payable {
        uint256 amount = msg.value;
        uint256 preBalance1 = ETF1.balanceOf(address(this));
        ETF1.invest{value: amount / 2}();
        uint256 postBalance1 = ETF1.balanceOf(address(this));
        userToETF1Balance[msg.sender] += postBalance1 - preBalance1;

        uint256 preBalance2 = ETF2.balanceOf(address(this));
        ETF2.invest{value: amount / 2}();
        uint256 postBalance2 = ETF2.balanceOf(address(this));
        userToETF2Balance[msg.sender] += postBalance2 - preBalance2;
    }

    receive() external payable {}

    // withdrawl percentage should be in basis points.

    function withdraw(uint256 _percent) public {
        uint256 available1 = userToETF1Balance[msg.sender];
        uint256 available2 = userToETF2Balance[msg.sender];
        require(available1 != 0 && available2 != 0, "no investment");
        uint256 amount1 = (available1 * _percent) / 10000;
        uint256 amount2 = (available2 * _percent) / 10000;
        userToETF1Balance[msg.sender] -= amount1;
        userToETF2Balance[msg.sender] -= amount2;
        uint256 preBalance = address(this).balance;
        ETF1.withdraw(amount1);
        uint256 postBalance = address(this).balance;
        payable(msg.sender).transfer(postBalance - preBalance);

        preBalance = address(this).balance;
        ETF2.withdraw(amount2);
        postBalance = address(this).balance;
        payable(msg.sender).transfer(postBalance - preBalance);
    }

    function harvest() public {
        ETF1.harvest();
        ETF2.harvest();
    }

    function userReturn() public view returns (uint256) {
        uint256 out = ETF1.userExpectedReturn(msg.sender) +
            ETF2.userExpectedReturn(msg.sender);
        return out;
    }
}