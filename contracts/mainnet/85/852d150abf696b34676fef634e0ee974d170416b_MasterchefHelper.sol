/**
 *Submitted for verification at FtmScan.com on 2023-02-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IMC {
    struct PoolInfo {
        uint128 accTokensPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    function poolInfo(uint256) external view returns (PoolInfo memory);

    function tokenPerSecond() external view returns (uint256); // xdeus
    function rewardPerSecond() external view returns (uint256); // spooky, beets
    function tokenPerBlock() external view returns (uint256); // bdei
}

interface ISwapFlashLoan {
    function getVirtualPrice() external view returns (uint256);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
    external
    view
    returns (uint256[] memory);
}

interface IVault {
    function getPoolTokenInfo(bytes32 poolId, address token)
    external
    view
    returns (
        uint256 cash,
        uint256 managed,
        uint256 lastChangeBlock,
        address assetManager
    );
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract MasterchefHelper {
    address constant public masterchef_xdeus = 0x62ad8dE6740314677F06723a7A07797aE5082Dbb;
    address constant public masterchef_spooky = 0xDdB816c59200aF55b1Ca20735Ef086626a2C6a8D;
    address constant public masterchef_beets = 0x90177BF4f4a5aaF5812508dbC1EBA8752C5cd605;
    address constant public masterchef_bdei = 0x67932809213AFd6bac5ECD2e4e214Fe18209c419;

    address constant public DEI = 0xDE1E704dae0B4051e80DAbB26ab6ad6c12262DA0;
    address constant public USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address constant public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant public legacyDEI = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3;

    address constant public xDEUS = 0x953Cd009a490176FcEB3a26b9753e6F01645ff28;  // xdeus 0
    address constant public DEUS_xDEUS = 0xECd9E18356bb8d72741c539e75CEAdB3C5869ea0; // xdeus 2
    address constant public DEUS = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;  // spooky, beets
    address constant public bDEI = 0x05f6ea7F80BDC07f6E0728BbBBAbebEA4E142eE8;  // bdei 0
    address constant public DEI_bDEI = 0xDce9EC1eB454829B6fe0f54F504FEF3c3C0642Fc;  // bdei 1

    address constant public DEUS_xDEUS_POOL = 0x54a5039C403fff8538fC582e0e3f07387B707381;  // SwapFlashLoan
    address constant public DEI_bDEI_POOL = 0x9caC3CE5D8327aa5AF54b1b4e99785F991885Bf3;  // SwapFlashLoan
    address constant public SPOOKY_WFTM_DEUS = 0xaF918eF5b9f33231764A5557881E6D3e5277d456;
    address constant public SPOOKY_USDC_DEI = 0x91f7120898b4be26cC1e84F421e76725c07d1361;

    bytes32 constant public DEI_USDC_BEETS_POOL_ID = 0x4e415957aa4fd703ad701e43ee5335d1d7891d8300020000000000000000053b;
    address constant public BEETS_VAULT = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;

    function getRewardPerSecond() external view returns (
        uint256 rewardPerSecond_xdeus,
        uint256 rewardPerSecond_spooky,
        uint256 rewardPerSecond_beets,
        uint256 tokenPerBlock_bdei) {
        rewardPerSecond_xdeus = IMC(masterchef_xdeus).tokenPerSecond();
        rewardPerSecond_spooky = IMC(masterchef_spooky).rewardPerSecond();
        rewardPerSecond_beets = IMC(masterchef_beets).rewardPerSecond();
        tokenPerBlock_bdei = IMC(masterchef_bdei).tokenPerBlock();
    }

    function getAllocPoint() external view returns (
        uint256 allocPoint_xdeus0,
        uint256 allocPoint_xdeus2,
        uint256 allocPoint_spooky0,
        uint256 allocPoint_spooky2,
        uint256 allocPoint_beets,
        uint256 allocPoint_bdei0,
        uint256 allocPoint_bdei1) {
        allocPoint_xdeus0 = IMC(masterchef_xdeus).poolInfo(0).allocPoint;
        allocPoint_xdeus2 = IMC(masterchef_xdeus).poolInfo(2).allocPoint;
        allocPoint_spooky0 = IMC(masterchef_spooky).poolInfo(0).allocPoint;
        allocPoint_spooky2 = IMC(masterchef_spooky).poolInfo(2).allocPoint;
        allocPoint_beets = IMC(masterchef_beets).poolInfo(0).allocPoint;
        allocPoint_bdei0 = IMC(masterchef_bdei).poolInfo(0).allocPoint;
        allocPoint_bdei1 = IMC(masterchef_bdei).poolInfo(1).allocPoint;
    }

    function getTVL() external view returns (
        uint256 tl_xdeus0,
        uint256 tl_xdeus2,
        uint256 tl_spooky0,
        uint256 tl_spooky2,
        uint256 tvl_beets,
        uint256 tl_bdei0,
        uint256 tl_bdei1
    ) {
        // value in xDEUS
        tl_xdeus0 = IERC20(xDEUS).balanceOf(masterchef_xdeus);
        // value in xDEUS
        tl_xdeus2 = ISwapFlashLoan(DEUS_xDEUS_POOL).calculateRemoveLiquidity(IERC20(DEUS_xDEUS).balanceOf(masterchef_xdeus))[0] * 2;

        // value in DEUS
        tl_spooky0 = IERC20(DEUS).balanceOf(SPOOKY_WFTM_DEUS) * 2;
        // value in USDC
        tl_spooky2 = IERC20(USDC).balanceOf(SPOOKY_USDC_DEI) * 1e12 * 2;

        (uint256 usdc_cash,,,) = IVault(BEETS_VAULT).getPoolTokenInfo(DEI_USDC_BEETS_POOL_ID, USDC);
        (uint256 dei_cash,,,) = IVault(BEETS_VAULT).getPoolTokenInfo(DEI_USDC_BEETS_POOL_ID, DEI);
        tvl_beets = usdc_cash * 1e12 + dei_cash;

        // value in legacyDEI
        tl_bdei0 = ISwapFlashLoan(DEI_bDEI_POOL).calculateSwap(1, 0, IERC20(bDEI).balanceOf(masterchef_bdei));

        // value in legacyDEI
        tl_bdei1 = ISwapFlashLoan(DEI_bDEI_POOL).calculateRemoveLiquidity(IERC20(DEI_bDEI).balanceOf(masterchef_bdei))[0] * 2;
    }
}