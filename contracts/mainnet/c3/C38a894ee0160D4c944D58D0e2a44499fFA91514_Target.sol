/**
 *Submitted for verification at FtmScan.com on 2022-10-28
*/

pragma solidity >= 0.8.0;

contract Target {
    bool public result;

    function execute() external {
        uint j = 0;
        for(uint i; i < 100000; i++){
            j++;
        }
        result = true;
    }
}