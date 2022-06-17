/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: GLWTPL

pragma solidity ^0.8.14;

// Fantom mainnet
contract Receiver03 {

    address owner;

    event ReceiveNumber(uint256 number);

    event StandardReceiveCalled();
    event StandardFallbackCalled();

    constructor() {
        owner = msg.sender;
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        uint256 number = abi.decode(_data, (uint256));

        emit ReceiveNumber(number);

        require(number == 42);

        success = true;
        result = '';
    }

    receive() external payable {
        emit StandardReceiveCalled();
    }

    fallback() external payable {
        emit StandardFallbackCalled();
    }

    function cleanup() external {
        require(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);
    }
}