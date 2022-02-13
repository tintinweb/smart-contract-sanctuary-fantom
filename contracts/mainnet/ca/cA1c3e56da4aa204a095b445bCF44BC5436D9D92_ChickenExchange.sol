/**
 *Submitted for verification at FtmScan.com on 2022-02-13
*/

pragma solidity ^0.6.12;

interface IERC20 {

    function transferFrom( address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address user) external returns (uint256);
    
}

contract ChickenExchange {

    address public synthetic_airdrop_token = 0xd4D61fd5E365cBacF347DCCBD62755bfD23DA7fA;
    address public realCHICKENaddress = 0x429D04D02eFB32b213D4D5b372DF733D0d533341;
    uint256 public start_time = 1644940800; //Tuesday, February 15, 2022 4:00:00 PM UTC

    constructor() public {

    }
    function exchange(uint256 amount) public{
        require (block.timestamp >= start_time, "Cant exchange yet");
        require (IERC20(synthetic_airdrop_token).balanceOf(msg.sender)>=amount, "Balance too low");
        require (IERC20(realCHICKENaddress).balanceOf(address(this))>=amount, "Not enough CHICKEN to claim");
        IERC20(synthetic_airdrop_token).transferFrom(msg.sender, address(this), amount);
        IERC20(realCHICKENaddress).transfer(msg.sender, amount);
    }


}