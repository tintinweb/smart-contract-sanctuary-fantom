/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface wsIERC20 is IERC20 {
    function sOHMValue(uint256 value) external view returns (uint256);
}

contract BalanceAggregator {
    IERC20 public EXOD = IERC20(0x3b57f3FeAaF1e8254ec680275Ee6E7727C7413c7);
    IERC20 public sEXOD = IERC20(0x8de250C65636Ef02a75e4999890c91cECd38D03D);
    wsIERC20 public wsEXOD =
        wsIERC20(0xe992C5Abddb05d86095B18a158251834D616f0D1);

    struct AccountBalance {
        address account;
        uint256 balance;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        balance = EXOD.balanceOf(account);
        balance += sEXOD.balanceOf(account);
        balance += wsEXOD.sOHMValue(wsEXOD.balanceOf(account));
    }

    function balanceOfM(address[] memory accounts)
        public
        view
        returns (AccountBalance[] memory)
    {
        AccountBalance[] memory results = new AccountBalance[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            results[i] = AccountBalance({
                account: accounts[i],
                balance: balanceOf(accounts[i])
            });
        }

        return results;
    }

    function decimals() public view returns (uint8) {
        return EXOD.decimals();
    }
}