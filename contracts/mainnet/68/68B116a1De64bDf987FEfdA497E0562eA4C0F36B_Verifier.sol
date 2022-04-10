/**
 *Submitted for verification at FtmScan.com on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Verifier {
    function verifyHash(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address signer) {
        return ecrecover(hash, v, r, s);
    }
}