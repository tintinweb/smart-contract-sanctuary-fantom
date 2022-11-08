// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

//import { VerificationTest02A } from "./VerificationTest02A.sol";


contract VerificationTest02 /*is VerificationTest02A*/ {

    address private immutable data;

    constructor(address _data) {
        data = _data;
    }

    function showData() external view returns (address) {
        return data;
    }

}