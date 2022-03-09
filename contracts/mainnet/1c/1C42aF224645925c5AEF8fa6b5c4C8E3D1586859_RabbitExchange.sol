/**
 *Submitted for verification at FtmScan.com on 2022-03-09
*/

pragma solidity ^0.6.12;

interface IERC20 {

    function transferFrom( address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address user) external returns (uint256);
    
}

contract RabbitExchange {

    address public synthetic_airdrop_token = 0xA9A634Cb9bf4e75D0CAe023F9941C83239819F27;
    address public realRABBITaddress = 0xd4D61fd5E365cBacF347DCCBD62755bfD23DA7fA;//change to real RABBIT upon deployment
    uint256 public start_time = 1646843793; //Friday, March 18, 2022 5:00:00 PM UTC
    //uint256 public start_time = 1647622800; //Friday, March 18, 2022 5:00:00 PM UTC

    constructor() public {

    }
    function exchange(uint256 amount) public{
        require (block.timestamp >= start_time, "Cant exchange yet");
        require (IERC20(synthetic_airdrop_token).balanceOf(msg.sender)>=amount, "Balance too low");
        require (IERC20(realRABBITaddress).balanceOf(address(this))>=amount, "Not enough RABBIT to claim");
        IERC20(synthetic_airdrop_token).transferFrom(msg.sender, address(this), amount);
        IERC20(realRABBITaddress).transfer(msg.sender, amount);
    }


}