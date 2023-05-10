/**
 *Submitted for verification at FtmScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.8.0;

interface sbfMMYInterface{
    function tokensPerInterval() external view returns (uint256);
}

contract testOracle {

    sbfMMYInterface internal dataFeedsbfMMY;

    constructor() public {
        dataFeedsbfMMY = sbfMMYInterface(0xe149164D8eca659E8912DbDEC35E3f7E71Fb5789);
    }

    function getLatest() public view returns (uint256) {
        (uint256 tokensPerInterval) = dataFeedsbfMMY.tokensPerInterval();
        return tokensPerInterval;
    }

}