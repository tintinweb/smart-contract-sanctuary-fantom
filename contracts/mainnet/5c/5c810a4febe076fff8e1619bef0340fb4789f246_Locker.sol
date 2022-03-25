/**
 *Submitted for verification at FtmScan.com on 2022-03-25
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.13;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Locker {
    address public OlimpusDev = 0xb65b90c8F300B7C89525182ac804cc9526271771;
    uint256 public unlockTimestamp;
    
    constructor() {
        unlockTimestamp = 1654041600; // Jun 1 2022 00:00:00 GMT
    }
    
    function withdraw(IERC20 token) external {
        require(msg.sender == OlimpusDev, "Only the chosen from the gods can withdraw");
        require(block.timestamp > unlockTimestamp, "withdraw is not allowed by the gods yet");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
}