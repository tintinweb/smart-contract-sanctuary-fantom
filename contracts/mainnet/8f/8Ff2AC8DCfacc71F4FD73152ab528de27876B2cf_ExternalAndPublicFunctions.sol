/**
 *Submitted for verification at FtmScan.com on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ExternalAndPublicFunctions {
    uint256 sum;


    function getSum() public returns(uint256){
        sum = sum + 1;
        return sum;
    }

    function _getSum() external returns(uint256){
        sum = sum + 1;
        return sum;
    }

    function usePublicFunction() public returns(uint256){
        uint256 _sum = getSum();
        sum = _sum + 3;
        return sum;
    }

    function useExternalFunction() public returns(uint256){
        uint256 _sum = this._getSum();
        sum = _sum + 3;
        return sum;
    }

    function _usePublicFunction() external returns(uint256){
        uint256 _sum = getSum();
        sum = _sum + 3;
        return sum;
    }

    function _useExternalFunction() external returns(uint256){
        uint256 _sum = this._getSum();
        sum = _sum + 3;
        return sum;
    }
}