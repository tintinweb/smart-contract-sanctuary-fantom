/**
 *Submitted for verification at FtmScan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Multicall  {

    function multiCall(
        address[] calldata targets,
        bytes[] calldata data
    ) external returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].delegatecall(data[i]);
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }

    function call(
        address[] calldata targets,
        bytes[] calldata data
    ) external returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call(data[i]);
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }

    function getData(string memory data) external pure returns (bytes memory) {
        return abi.encodeWithSignature(data);
    }
}