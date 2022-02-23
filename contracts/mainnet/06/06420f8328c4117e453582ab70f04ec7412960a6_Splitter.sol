/**
 *Submitted for verification at FtmScan.com on 2022-02-22
*/

pragma solidity 0.8.11;



interface IERC20 {
    function balanceOf(address) view external returns (uint256);
    function transfer(address,uint256) external;
}


// File: <stdin>.sol

contract Splitter {

    IERC20 constant geist = IERC20(0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d);

    address constant receiverA = 0x3d05B64AF3F7F991c703c9d7A95f30111F9dcFab;
    address constant receiverB = 0x6e4084315030747EDd36E5780E0F4e6879D9a1DB;

    function split() external {
        uint amount = geist.balanceOf(address(this));
        geist.transfer(receiverA, amount / 2);
        geist.transfer(receiverB, amount / 2);
    }

}