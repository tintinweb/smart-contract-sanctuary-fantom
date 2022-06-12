/**
 *Submitted for verification at FtmScan.com on 2022-06-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CountContract{

    uint256 public count;
    address public owner;

    constructor (address owner_param) {
        owner = owner_param;
    }

    event SetCountEvent (uint256 newCount);

    function setCount () public {
        count += 1;
        emit SetCountEvent(count);
    }

    function getAcount () view public returns (uint256) {
        return count;
    }
}