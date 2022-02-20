/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

pragma solidity ^0.6.12;

interface IERC20 {

    function transferFrom( address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address user) external returns (uint256);
    
}

contract TestEggFaucet {

    address public TestEgg = 0xc72f6D95e0582af76D652c2dB3BEa7F9baFb8B15;

    constructor() public {

    }

    function getFaucet() public{
        IERC20(TestEgg).transfer(msg.sender, 500000000000000000);
    }

}