/**
 *Submitted for verification at FtmScan.com on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VariablePacking_2 {
    uint256 var1 = 1;
    uint8 var2 = 1;
    uint8 var3 = 1;

    function foo() public {
        var1 = 2;
        var2 = 3;
        var3 = 4;
    }

    function foo2() public {
        var2 = 5;
        var3 = 6;
    }
}