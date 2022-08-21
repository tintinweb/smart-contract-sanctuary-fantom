/**
 *Submitted for verification at FtmScan.com on 2022-08-21
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



contract testingcontract {

    uint256 public abc = 1;
    function test() public {

        abc = 2;
        revert();
    
    }

    function interate() public {
        for (uint256 i = 0; i < 10000; i++) {
            abc += 1;
        }
        }
    }