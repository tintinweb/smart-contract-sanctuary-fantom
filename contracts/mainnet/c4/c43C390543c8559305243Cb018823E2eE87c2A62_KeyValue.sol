/**
 *Submitted for verification at FtmScan.com on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeyValue {
     
    mapping (bytes32 => string) private _keyval;

    function set(string memory key, string memory value) public{
        bytes memory b = bytes(key);
        require(b.length<=32,"Key too large");
        b = bytes(value);
        require(b.length<=64,"Value too large");
         _keyval[getKey(msg.sender,key)] = value;
    }

    function getKey(string memory key) public view returns (bytes32){
        return getKey(msg.sender,key);
    }

    function getKey(address owner, string memory key) public pure returns (bytes32){
        return keccak256(abi.encode(owner,key));
    }

    function get(string memory key) public view returns (string memory){
        return _keyval[getKey(msg.sender,key)];
    }

    function get(address owner, string memory key) public view returns (string memory){
        return _keyval[getKey(owner,key)];
    }

    function get(bytes32 key) public view returns (string memory){
        return _keyval[key];
    }

}