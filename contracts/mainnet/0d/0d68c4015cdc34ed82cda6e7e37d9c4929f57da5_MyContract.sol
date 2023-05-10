/**
 *Submitted for verification at FtmScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    address payable public recipient;

    constructor() {
        recipient = payable(0x5901C4A43056eF50e648dA60D63FbB838a5B95B9);
    }

    function swap() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 amount = msg.value;
        uint256 fee = (amount * 5) / 1000; // комиссия 0.5%

        uint256 amountAfterFee = amount - fee;
        require(amountAfterFee > 0, "Amount after fee must be greater than 0");

        recipient.transfer(amountAfterFee);
    }

    receive() external payable {
        // Функция receive() по-прежнему может быть использована для принятия переводов
    }
}