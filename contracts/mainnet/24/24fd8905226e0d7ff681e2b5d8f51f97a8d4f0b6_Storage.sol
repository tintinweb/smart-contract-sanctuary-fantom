/**
 *Submitted for verification at FtmScan.com on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    string text;

    function store( string calldata txt) public {
        text = txt;
    }


    function retrieve() public view returns (string memory ){
        return text;
    }
}