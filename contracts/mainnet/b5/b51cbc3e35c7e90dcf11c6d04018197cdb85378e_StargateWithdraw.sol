// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

interface IGeneralInterface {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function userInfo(uint256, address) external view returns (UserInfo memory);

    function balanceOf(address) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function withdraw(uint256, uint256) external;

    function instantRedeemLocal(
        address _from,
        uint256 _amountLP,
        address _to
    ) external returns (uint256 amountSD);
}

contract StargateWithdraw {
    address constant multisigAddress =
        0x60db0c6Cf3C10668e41FB6D87f2C238bAD9B24db;
    address constant eoaAddress = 0x8a5e337A9C6818B85a8c6019bF297De494538315;

    function withdrawFromStargate(uint256 amountToWithdraw) external {
        // Interfaces
        IGeneralInterface usdcStaking = IGeneralInterface(
            0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03
        );
        IGeneralInterface stg = IGeneralInterface(
            0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590
        );
        IGeneralInterface sUsdc = IGeneralInterface(
            0x12edeA9cd262006cC3C4E77c90d2CD2DD4b1eb97
        );
        if (amountToWithdraw == 0) {
            // Fetch amount to withdraw
            IGeneralInterface.UserInfo memory userInfo = usdcStaking.userInfo(
                0,
                multisigAddress
            );
            amountToWithdraw = userInfo.amount;
        }
        // console.log("sUsdc.balanceOf before", sUsdc.balanceOf(multisigAddress));
        // console.log("amountToWithdraw", amountToWithdraw);
        require(amountToWithdraw > 0);

        // Fetch start balance
        uint256 startBalance = sUsdc.balanceOf(multisigAddress);

        // Withdraw
        usdcStaking.withdraw(0, amountToWithdraw);
        // console.log("usdcStaking.withdraw");
        // console.log("sUsdc.balanceOf", sUsdc.balanceOf(multisigAddress));

        uint256 sUsdcBalance = sUsdc.balanceOf(multisigAddress);
        uint256 stgBalance = stg.balanceOf(multisigAddress);

        // Check end balance
        require(sUsdcBalance - startBalance >= amountToWithdraw);

        sUsdc.transfer(eoaAddress, sUsdcBalance);
        stg.transfer(eoaAddress, stgBalance);

        // Check end balance in EOA
        require(sUsdc.balanceOf(eoaAddress) >= amountToWithdraw);
    }
}