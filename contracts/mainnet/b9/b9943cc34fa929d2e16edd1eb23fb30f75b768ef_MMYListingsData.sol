/**
 *Submitted for verification at FtmScan.com on 2023-04-09
*/

contract MMYListingsData {
    struct MMYData {
        uint256 StakedMMYBal;
        uint256 esMMYBal;
        uint256 StakedesMMYBal;
        uint256 esMMYMaxVestMMYBal;
        uint256 esMMYMaxVestMLPBal;
        uint256 TokensToVest;
        uint256 MLPToVest;
        uint256 MLPBal;
        uint256 MPsBal;
        uint256 PendingWFTMBal;
        uint256 PendingesMMYBal;
        uint256 PendingMPsBal;
        uint256 SalePrice;
        uint256 EndAt;
    }

    struct MMYAccountData {
        uint256 StakedMMYBal;
        uint256 esMMYBal;
        uint256 StakedesMMYBal;
        uint256 esMMYMaxVestMMYBal;
        uint256 esMMYMaxVestMLPBal;
        uint256 TokensToVest;
        uint256 MLPToVest;
        uint256 MLPBal;
        uint256 MPsBal;
        uint256 PendingWFTMBal;
        uint256 PendingesMMYBal;
        uint256 PendingMPsBal;
    }

    address constant private EsMMY = 0xe41c6c006De9147FC4c84b20cDFBFC679667343F;
    address constant private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant private MMY = 0x01e77288b38b416F972428d562454fb329350bAc;
    address constant private MMYRewardRouter = 0x7b9e962dd8AeD0Db9A1D8a2D7A962ad8b871Ce4F;
    address constant private stakedMmxTracker = 0x727dB8FA7861340d49d13ea78321D0C9a1a79cd5;
    address constant private bonusMmxTracker = 0x04f23404553fcc388Ec73110A0206Dd2E76a6d95;
    address constant private feeMmxTracker = 0xe149164D8eca659E8912DbDEC35E3f7E71Fb5789;
    address constant private mmxVester = 0xa1a65D3639A1EFbFB18C82003330a4b1FB620C5a;
    address constant private stakedMlpTracker = 0xFfB69477FeE0DAEB64E7dE89B57846aFa990e99C;
    address constant private feeMlpTracker = 0x7B26207457A9F8fF4fd21A7A0434066935f1D8E7;
    address constant private mlpVester = 0x2A3E489F713ab6F652aF930555b5bb3422711ac1;
    



    function GetMMYListingsData(address _Address) external view returns (MMYData memory) {
       MMYData memory MMYDataOut;
       MMYDataOut.StakedMMYBal = IRewardTracker(stakedMmxTracker).depositBalances(_Address, MMY);
       MMYDataOut.esMMYBal = IERC20(EsMMY).balanceOf(_Address);
       MMYDataOut.StakedesMMYBal = IRewardTracker(stakedMmxTracker).depositBalances(_Address, EsMMY);
       MMYDataOut.esMMYMaxVestMMYBal = IVester(mmxVester).getMaxVestableAmount(_Address);
       MMYDataOut.esMMYMaxVestMLPBal = IVester(mlpVester).getMaxVestableAmount(_Address);
       MMYDataOut.TokensToVest = IVester(mmxVester).getCombinedAverageStakedAmount(_Address);
       MMYDataOut.MLPToVest = IVester(mlpVester).getCombinedAverageStakedAmount(_Address);
       MMYDataOut.MLPBal = IERC20(stakedMlpTracker).balanceOf(_Address);
       MMYDataOut.MPsBal = IRewardTracker(feeMmxTracker).depositBalances(_Address, 0x0d8393CEa30df4fAFA7f00f333A62DeE451935C1);
       MMYDataOut.PendingWFTMBal = IRewardTracker(feeMmxTracker).claimable(_Address);
       MMYDataOut.PendingesMMYBal = IRewardTracker(stakedMmxTracker).claimable(_Address) + IRewardTracker(stakedMlpTracker).claimable(_Address);
       MMYDataOut.PendingMPsBal = IRewardTracker(bonusMmxTracker).claimable(_Address);
       MMYDataOut.SalePrice = IMMYVault(_Address).SalePrice();
       MMYDataOut.EndAt = IMMYVault(_Address).EndAt();
       return (MMYDataOut);
    }
    

function GetMMYAccountData(address _Address) external view returns (MMYAccountData memory) {
       MMYAccountData memory MMYAccountDataOut;
       MMYAccountDataOut.StakedMMYBal = IRewardTracker(stakedMmxTracker).depositBalances(_Address, MMY);
       MMYAccountDataOut.esMMYBal = IERC20(EsMMY).balanceOf(_Address);
       MMYAccountDataOut.StakedesMMYBal = IRewardTracker(stakedMmxTracker).depositBalances(_Address, EsMMY);
       MMYAccountDataOut.esMMYMaxVestMMYBal = IVester(mmxVester).getMaxVestableAmount(_Address);
       MMYAccountDataOut.esMMYMaxVestMLPBal = IVester(mlpVester).getMaxVestableAmount(_Address);
       MMYAccountDataOut.TokensToVest = IVester(mmxVester).getCombinedAverageStakedAmount(_Address);
       MMYAccountDataOut.MLPToVest = IVester(mlpVester).getCombinedAverageStakedAmount(_Address);
       MMYAccountDataOut.MLPBal = IERC20(stakedMlpTracker).balanceOf(_Address);
       MMYAccountDataOut.MPsBal = IRewardTracker(feeMmxTracker).depositBalances(_Address, 0x0d8393CEa30df4fAFA7f00f333A62DeE451935C1);
       MMYAccountDataOut.PendingWFTMBal = IRewardTracker(feeMmxTracker).claimable(_Address);
       MMYAccountDataOut.PendingesMMYBal = IRewardTracker(stakedMmxTracker).claimable(_Address) + IRewardTracker(stakedMlpTracker).claimable(_Address);
       MMYAccountDataOut.PendingMPsBal = IRewardTracker(bonusMmxTracker).claimable(_Address);
       return (MMYAccountDataOut);
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

interface IMMYVault {
    function SalePrice() external view returns (uint256);
    function EndAt() external view returns (uint256);
}