/**
 *Submitted for verification at FtmScan.com on 2022-08-28
*/

// File: contracts/receive.sol


pragma solidity ^0.8.16;

contract Receiver {
    address public firstOwner;
    address public secondOwner;

    constructor(address _first, address _second) {
        firstOwner = _first;
        secondOwner = _second;
    }

    receive() external payable {}

    function split() external {
        require(msg.sender == firstOwner || msg.sender == secondOwner);
        uint _balance = getBalance();
        uint _amount = _calculate(_balance);
        payable(firstOwner).transfer(_amount);
        payable(secondOwner).transfer(_amount);
    }

    function getBalance() public view returns (uint) {
        address _this = address(this);
        uint _balance = _this.balance;
        return _balance;
    }

    function _calculate(uint _balance) private pure returns (uint) {
        return _balance * 50 / 100;
    }

    function changeMyAdrress(address _new) external {
        require(msg.sender == firstOwner || msg.sender == secondOwner);
        if (msg.sender == firstOwner) {
            firstOwner = _new;
        }
        if (msg.sender == secondOwner) {
            secondOwner = _new;
        }
    }
}