// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TestCon {
    mapping(uint256 => uint256) map;

    /* ========== CONSTRUCTOR ========== */
    constructor(){
    }


    function add(uint256[] calldata indexes, uint256[] calldata values)
        public
    {
        for(uint256 i = 0; i < indexes.length; i++){
            map[indexes[i]] = values[i];
        }
    }
}