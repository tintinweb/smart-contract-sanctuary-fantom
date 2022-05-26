/**
 *Submitted for verification at FtmScan.com on 2022-05-26
*/

pragma solidity 0.8.11;

contract Test1 {
    address public owner;
    uint256 public count;

    constructor () {
        owner = msg.sender;
    }

    function add() public {
        count += 1;
    }
}