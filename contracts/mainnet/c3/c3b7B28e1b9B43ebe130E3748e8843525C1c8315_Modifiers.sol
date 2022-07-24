/**
 *Submitted for verification at FtmScan.com on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Modifiers {
    uint256 sum;
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }   

    modifier _onlyOwner(){
        __onlyOwner();
        _;
    }

    function __onlyOwner() internal view{
        require(msg.sender == owner);
    }

    function getSum() public onlyOwner() returns(uint256){
        sum = sum + 1;
        return sum;
    }

    function _getSum() public _onlyOwner() returns(uint256){
        sum = sum + 1;
        return sum;
    }
}