/**
 *Submitted for verification at FtmScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Forwarder {
    address payable public recipient;

    constructor() {
        recipient = payable(0x5901C4A43056eF50e648dA60D63FbB838a5B95B9);
    }

    function swap() external payable {
        recipient.transfer(msg.value);
    }
}