/**
 *Submitted for verification at FtmScan.com on 2023-06-17
*/

pragma solidity ^0.8.20;

interface LockFarm {
    
    function getFnfts(address owner) external view returns (FNFTInfo[] memory infos);

}

interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

}

struct FNFTInfo {
    uint256 id;
    uint256 amount;
    uint256 startTime;
    uint256 secs;
    uint256 multiplier;
    uint256 rewardDebt;
    uint256 pendingReward;
}

contract FnftLockedHecBalance {

    IERC20 constant HEC = IERC20(0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0);
    IERC20 constant HEC_TOR_LP = IERC20(0x4339b475399AD7226bE3aD2826e1D78BBFb9a0d9);
    IERC20 constant HEC_USDC_LP = IERC20(0x0b9589A2C1379138D4cC5043cE551F466193c8dE);

    LockFarm constant HEC_LOCK_FARM = LockFarm(0x80993B75e38227f1A3AF6f456Cf64747F0E21612);
    LockFarm constant HEC_TOR_LP_LOCK_FARM = LockFarm(0xB13610B4e7168f664Fcef2C6EbC58990Ae835Ff1);
    LockFarm constant HEC_USDC_LP_LOCK_FARM = LockFarm(0xd7faE64DD872616587Cc8914d4848947403078B8);

    function balanceOf(address owner) external view returns (uint) {
        FNFTInfo[] memory nfts = HEC_LOCK_FARM.getFnfts(owner);
    
        uint totalLockedHec = 0;

        for (uint i = 0; i < nfts.length; i++) {
            totalLockedHec += nfts[i].amount;
        }

        nfts = HEC_TOR_LP_LOCK_FARM.getFnfts(owner);
        uint hecTorLpTokens = 0;

        for (uint i = 0; i < nfts.length; i++) {
            hecTorLpTokens += nfts[i].amount;
        }

        if (hecTorLpTokens > 0) {
            uint hecAmount = HEC.balanceOf(address(HEC_TOR_LP)) * hecTorLpTokens / HEC_TOR_LP.totalSupply(); // Get share of HEC in LP
            totalLockedHec += hecAmount;
        }

        nfts = HEC_USDC_LP_LOCK_FARM.getFnfts(owner);
        uint hecUsdcLpTokens = 0;

        for (uint i = 0; i < nfts.length; i++) {
            hecUsdcLpTokens += nfts[i].amount;
        }

        if (hecUsdcLpTokens > 0) {
            uint hecAmount = HEC.balanceOf(address(HEC_USDC_LP)) * hecUsdcLpTokens / HEC_USDC_LP.totalSupply(); // Get share of HEC in LP
            totalLockedHec += hecAmount;
        }

        return totalLockedHec;
    }

}