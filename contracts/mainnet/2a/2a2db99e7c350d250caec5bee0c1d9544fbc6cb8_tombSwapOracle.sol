/**
 *Submitted for verification at FtmScan.com on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function withdraw (uint256 amount) external returns (uint256);
}

interface ITombSwap {
    function pendingShare(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo (uint256) external view returns (address token, uint256 allocPoint, uint256 lastRewardTime, uint256 accTSharePerShare, bool isStarted);

}

contract tombSwapOracle {
    address public rewardPool = 0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43;
    address public tshare = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37;
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public lp = 0x4733bc45eF91cF7CcEcaeeDb794727075fB209F2;
    function getTsharePrice() public view returns(uint256){
        return IERC20(wftm).balanceOf(lp)*1e18/IERC20(tshare).balanceOf(lp);

    }
    function getReward(uint256 _pid, address _user) public view returns(uint256){
        return ITombSwap(rewardPool).pendingShare(_pid,_user)*getTsharePrice()/1e18;
    }
    function getPoolInfo(uint256 _pid) public view returns(address token, uint256 allocPoint, uint256 lastRewardTime, uint256 accTSharePerShare, bool isStarted){
        return ITombSwap(rewardPool).poolInfo(_pid);
    }
    

}