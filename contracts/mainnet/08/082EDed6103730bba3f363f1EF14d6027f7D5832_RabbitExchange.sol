/**
 *Submitted for verification at FtmScan.com on 2022-03-14
*/

pragma solidity ^0.6.12;

interface IERC20 {

    function transferFrom( address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address user) external returns (uint256);
    
}

contract RabbitExchange {

    address public synthetic_airdrop_token = 0xA9A634Cb9bf4e75D0CAe023F9941C83239819F27;
    address public realRABBITaddress = 0xe665B8185F697F215cD6cAc8c19FE9E1d849D6de;//Fill in after deployment of real RABBIT
    uint256 public start_time = 1647450000; //LP Start Time: Wed, March 16, 2022 5:00:00 PM UTC

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