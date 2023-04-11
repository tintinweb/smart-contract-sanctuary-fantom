/**
 *Submitted for verification at FtmScan.com on 2023-04-11
*/

pragma solidity ^0.8.17;

contract AccountEligible{
    address constant private EsMMYAddress = 0xe41c6c006De9147FC4c84b20cDFBFC679667343F;
    address constant private WFTMAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant private MMYAddress = 0x01e77288b38b416F972428d562454fb329350bAc;
    address constant private MMYRewardRouterAddress = 0x7b9e962dd8AeD0Db9A1D8a2D7A962ad8b871Ce4F;
    address constant private stakedMmyTracker = 0x727dB8FA7861340d49d13ea78321D0C9a1a79cd5;
    address constant private bonusMmyTracker = 0x04f23404553fcc388Ec73110A0206Dd2E76a6d95;
    address constant private feeMmyTracker = 0xe149164D8eca659E8912DbDEC35E3f7E71Fb5789;
    address constant private mmyVester = 0xa1a65D3639A1EFbFB18C82003330a4b1FB620C5a;
    address constant private stakedMlpTracker = 0xFfB69477FeE0DAEB64E7dE89B57846aFa990e99C;
    address constant private feeMlpTracker = 0x7B26207457A9F8fF4fd21A7A0434066935f1D8E7;
    address constant private mlpVester = 0x2A3E489F713ab6F652aF930555b5bb3422711ac1;
    function TransferEligible(address _receiver) external view returns (bool Eligible) {
        Eligible = true;
        if (IRewardTracker(stakedMmyTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedMmyTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusMmyTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusMmyTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }       
        if (IRewardTracker(feeMmyTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeMmyTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(mmyVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(mmyVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedMlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedMlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeMlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeMlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(mlpVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(mlpVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(mmyVester).balanceOf(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(mlpVester).balanceOf(_receiver) > 0) {
            Eligible = false;
        }
    }
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
interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
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
interface IVester {
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);
    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}