/**
 *Submitted for verification at FtmScan.com on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
interface Easy {
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface xEasy {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function xEasyForEasy(uint256 _xEasyAmount) external view returns (uint256 easyAmount_);
}

contract TotalEasy {
    Easy immutable EASY_CONTRACT = Easy(0x26A0D46A4dF26E9D7dEeE9107a27ee979935F237);
    xEasy immutable xEASY_CONTRACT = xEasy(0x5Cd9C4bcFDa86dd4C13AF8B04B30B4D8651F2D7C);

    function getTotalEasyCount(address _user) external view returns (uint256) {
        uint256 easyBalance = EASY_CONTRACT.balanceOf(_user);
        uint256 easyInxEasy = xEASY_CONTRACT.xEasyForEasy(xEASY_CONTRACT.balanceOf(_user));

        return easyBalance + easyInxEasy;
    }
}