/**
 *Submitted for verification at FtmScan.com on 2023-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    event Log(string message);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        emit Log("new number stored!");
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}