/**
 *Submitted for verification at FtmScan.com on 2023-04-19
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;
interface IStaking {
    function getOrderLengthAddress(address _addr) external view returns(uint256);
    function getOrders(address _addr,uint index) view external returns(uint256 amount,uint256 deposit_time);
}

contract StakingInsurance1 {
    IStaking public staking = IStaking(0xfaf312640Fc409baf20d2d9308DA8AC5c43dC25F);
    mapping(address => uint256) public unstake;
    uint256 private constant timeStepdaily =20*60;   
    constructor() public {    
    }
    function getOrderscheck(address _addr,uint index) view external returns(uint256,uint256)
    {
        (uint256 amount,uint256 deposit_time) = staking.getOrders(_addr,index);
        return (amount,deposit_time);
    }
    function payout() external {
        uint256 amount = stakePayoutOf();
        require(amount > 0, "StakingInsurance: ZERO_AMOUNT");    
        unstake[msg.sender] += amount;
        payable(msg.sender).transfer(amount); 
    }
    function stakePayoutOf() public view returns(uint256){
        uint256 unstakeamount=0;
        uint256 orderlength=staking.getOrderLengthAddress(msg.sender);
        for(uint8 i = 0; i < orderlength; i++){
            (uint256 amount,uint256 deposit_time) = staking.getOrders(msg.sender,i);            
            if(block.timestamp>deposit_time+timeStepdaily){ 
                unstakeamount +=amount*15/100;
            }
        }
        return (unstakeamount-unstake[msg.sender]);
    }
}