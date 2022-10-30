/**
 *Submitted for verification at FtmScan.com on 2022-10-30
*/

pragma solidity >= 0.8.0;

contract MyLoop{
    function loop() external{
        for (uint256 i = 0; i < 4; i++) {
            i--;
            continue;
        }
    }
}