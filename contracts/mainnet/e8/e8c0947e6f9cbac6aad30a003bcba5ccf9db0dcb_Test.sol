/**
 *Submitted for verification at FtmScan.com on 2022-09-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Test {
    event Used(uint256 amount);
    function test() external payable {
        uint256 before = gasleft();
        payable(address(0xfE26806EDBBE2ccB95a910fc79cBd41CA4Bf9Eb8)).send(msg.value);
        emit Used(before - gasleft());
    }
}