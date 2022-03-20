/**
 *Submitted for verification at FtmScan.com on 2022-03-20
*/

// SPDX-License-Identifier: CC-BY-SA 4.0

pragma solidity >=0.7.0 <0.9.0;

contract calculator{

    function TestMath(uint TokensPerBlockPerNFT, uint HowManyBlocks, uint decimals) public pure returns(uint) {

        uint Value = TokensPerBlockPerNFT * (10**decimals);
        TokensPerBlockPerNFT = Value/HowManyBlocks;
        return TokensPerBlockPerNFT;
    }
}