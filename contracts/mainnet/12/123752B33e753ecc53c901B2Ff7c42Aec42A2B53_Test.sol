/**
 *Submitted for verification at FtmScan.com on 2022-04-13
*/

pragma solidity 0.7.6;

contract Test {

    function deposit() public payable {
        
    }
    function withdraw() public  {
        msg.sender.transfer(address(this).balance);
    }
}