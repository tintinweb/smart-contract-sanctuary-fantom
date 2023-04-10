/**
 *Submitted for verification at FtmScan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GMXListingsData {
    struct GMXData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 TokensToVest;
        uint256 GLPToVest;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingWETHBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
        uint256 SalePrice;
        uint256 EndAt;
    }

    struct GMXAccountData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 TokensToVest;
        uint256 GLPToVest;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingWETHBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
    }

    address constant private EsGMX = 0xe41c6c006De9147FC4c84b20cDFBFC679667343F;
    address constant private WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant private GMX = 0x01e77288b38b416F972428d562454fb329350bAc;
    address constant private GMXRewardRouter = 0x7b9e962dd8AeD0Db9A1D8a2D7A962ad8b871Ce4F;
    address constant private stakedGmxTracker = 0x727dB8FA7861340d49d13ea78321D0C9a1a79cd5;
    address constant private bonusGmxTracker = 0x04f23404553fcc388Ec73110A0206Dd2E76a6d95;
    address constant private feeGmxTracker = 0xe149164D8eca659E8912DbDEC35E3f7E71Fb5789;
    address constant private gmxVester = 0xa1a65D3639A1EFbFB18C82003330a4b1FB620C5a;
    address constant private stakedGlpTracker = 0xFfB69477FeE0DAEB64E7dE89B57846aFa990e99C;
    address constant private feeGlpTracker = 0x7B26207457A9F8fF4fd21A7A0434066935f1D8E7;
    address constant private glpVester = 0x2A3E489F713ab6F652aF930555b5bb3422711ac1;
    address constant private bnGMX = 0x0d8393CEa30df4fAFA7f00f333A62DeE451935C1;

    function GetGMXListingsData(address _Address) external view returns (GMXData memory) {
       GMXData memory GMXDataOut;
       GMXDataOut.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, GMX);
       GMXDataOut.esGMXBal = IERC20(EsGMX).balanceOf(_Address);
       GMXDataOut.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, EsGMX);
       GMXDataOut.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(_Address);
       GMXDataOut.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(_Address);
       GMXDataOut.TokensToVest = IVester(gmxVester).getCombinedAverageStakedAmount(_Address);
       GMXDataOut.GLPToVest = IVester(glpVester).getCombinedAverageStakedAmount(_Address);
       GMXDataOut.GLPBal = IERC20(stakedGlpTracker).balanceOf(_Address);
       GMXDataOut.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(_Address, bnGMX);
       GMXDataOut.PendingWETHBal = IRewardTracker(feeGmxTracker).claimable(_Address);
       GMXDataOut.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(_Address) + IRewardTracker(stakedGlpTracker).claimable(_Address);
       GMXDataOut.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(_Address);
       GMXDataOut.SalePrice = IGMXVault(_Address).SalePrice();
       GMXDataOut.EndAt = IGMXVault(_Address).EndAt();
       return (GMXDataOut);
    }

function GetGMXAccountData(address _Address) external view returns (GMXAccountData memory) {
       GMXAccountData memory GMXAccountDataOut;
       GMXAccountDataOut.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, GMX);
       GMXAccountDataOut.esGMXBal = IERC20(EsGMX).balanceOf(_Address);
       GMXAccountDataOut.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, EsGMX);
       GMXAccountDataOut.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(_Address);
       GMXAccountDataOut.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(_Address);
       GMXAccountDataOut.TokensToVest = IVester(gmxVester).getCombinedAverageStakedAmount(_Address);
       GMXAccountDataOut.GLPToVest = IVester(glpVester).getCombinedAverageStakedAmount(_Address);
       GMXAccountDataOut.GLPBal = IERC20(stakedGlpTracker).balanceOf(_Address);
       GMXAccountDataOut.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(_Address, bnGMX);
       GMXAccountDataOut.PendingWETHBal = IRewardTracker(feeGmxTracker).claimable(_Address);
       GMXAccountDataOut.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(_Address) + IRewardTracker(stakedGlpTracker).claimable(_Address);
       GMXAccountDataOut.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(_Address);
       return (GMXAccountDataOut);
    }
}

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IVester {
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

interface IGMXVault {
    function SalePrice() external view returns (uint256);
    function EndAt() external view returns (uint256);
}