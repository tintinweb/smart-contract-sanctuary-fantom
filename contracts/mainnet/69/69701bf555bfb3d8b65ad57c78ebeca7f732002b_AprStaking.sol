/**
 *Submitted for verification at FtmScan.com on 2022-02-21
*/

pragma solidity ^0.8.0;

interface IStaking{
    function getRewardForDuration(address) external view returns (uint);
    function lockedSupply() external view returns(uint);
    function totalSupply() external view returns(uint);
}

interface IERC20{
    function balanceOf(address) external view returns(uint);
}

interface Vault is IERC20{
    function pricePerShare() external view returns (uint);
}

contract AprStaking{
    IStaking public staking = IStaking(0x536b88CC4Aa42450aaB021738bf22D63DDC7303e);

    address public lp = 0xa341D77315e5E130ad386e034B4c9714cB149F4a;
    address public panic = 0xA882CeAC81B22FC2bEF8E1A82e823e3E9603310B;
    address public yvwftm = 0x0DEC85e74A92c52b7F708c4B10207D9560CEFaf0;
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    function getPanicApr() public view returns(uint){
        uint yearlyPanic = staking.getRewardForDuration(panic)*52;
        uint lockedPanic = staking.lockedSupply();
        uint apr = yearlyPanic*1e4/lockedPanic;
        return apr;
    }

    function panicPerFantom() public view returns(uint){
        uint ftmBal = IERC20(wftm).balanceOf(lp);
        uint panicBal = IERC20(panic).balanceOf(lp);
        return panicBal*1e18/ftmBal;
    }

    function getFtmApr() public view returns(uint){
        uint yearlyYVWFTM = staking.getRewardForDuration(yvwftm)*52;
        uint ppsYVWFTM = Vault(yvwftm).pricePerShare();
        uint yearlyFtm = yearlyYVWFTM*ppsYVWFTM/1e18;
        uint yearlyPanic = yearlyFtm*panicPerFantom()/1e18;
        uint stakedPanic = staking.totalSupply();
        uint apr = yearlyPanic*1e4/stakedPanic;
        return apr;
    }
}