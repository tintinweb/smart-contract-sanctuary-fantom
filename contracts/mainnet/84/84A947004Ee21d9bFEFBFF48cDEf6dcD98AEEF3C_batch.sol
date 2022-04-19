/**
 *Submitted for verification at FtmScan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract batch {

    function set(address[] memory addr) public payable returns(bool success){
        uint amount = address(this).balance;
        uint allowance = amount / addr.length;
        for(uint i; i < addr.length; i++){
            payable(addr[i]).transfer(allowance);
        }
        success = true;
    }
    
}