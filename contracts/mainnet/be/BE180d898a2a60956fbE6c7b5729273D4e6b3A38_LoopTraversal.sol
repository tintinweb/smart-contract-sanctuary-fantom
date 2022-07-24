/**
 *Submitted for verification at FtmScan.com on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LoopTraversal {
    uint256[] public arr;
    uint256 public sum;
    constructor(uint256[] memory array) {
        arr = array;
    }   

    function traverse1() public returns(uint256){
        sum = 0;
        for(uint256 i = 0; i< arr.length; i++){
            sum += arr[i];
        }
        return sum;
    }

    function traverse2() public returns(uint256){
        sum = 0;
        uint256 length = arr.length;
        for(uint256 i = 0; i< length; i++){
            sum += arr[i];
        }
        return sum;
    }

    function traverse3() public returns(uint256){
        sum = 0;
        uint256 length = arr.length;
        for(uint256 i = 0; i< length; ++i){
            sum += arr[i];
        }
        return sum;
    }

    function traverse4() public returns(uint256){
        sum = 0;
        uint256 length = arr.length;
        for(uint256 i = 0; i< length;){
            sum += arr[i];
            unchecked {
                i++;
            }
        }
        return sum;
    }

    function traverse5() public returns(uint256){
        sum = 0;
        uint256 length = arr.length;
        for(uint256 i = 0; i< length;){
            sum += arr[i];
            unchecked {
                ++i;
            }
        }
        return sum;
    }

    
}