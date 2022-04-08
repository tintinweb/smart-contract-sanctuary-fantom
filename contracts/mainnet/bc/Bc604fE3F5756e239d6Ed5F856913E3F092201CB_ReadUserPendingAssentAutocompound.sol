// SPDX-License-Identifier: MIT

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

pragma solidity 0.8.11;

import "./IERC20.sol";

interface IAutoCompound {
    function userInfo(address _user) external view returns (uint256, uint256, uint256);

    function tokenBalanceOf() external view returns (uint256);

    function calculateTotalPendingTokenRewards() external view returns (uint256);
}

contract ReadUserPendingAssentAutocompound {

	// ASNT token
    IERC20 immutable public sASNT;
    IAutoCompound public immutable autoCompound;

    constructor(
        IERC20 _sASNT,
        IAutoCompound _autoCompound
    ) {
        sASNT = _sASNT;
        autoCompound = _autoCompound;
    }

    function pendingPerUser(address _user) public view returns (uint256 pending,uint256 userShare,uint256 inUserWallet,uint256 userASNTValue,uint256 userEarnSinceLastAction) {

        (,uint256 tokenAtLastUserAction ,) = IAutoCompound(autoCompound).userInfo(_user);


        if (sASNT.totalSupply() > 0){
            // ratio of user sASNT holdings
            userShare = sASNT.balanceOf(_user) * 1e18 / sASNT.totalSupply();
            
            //User ASNT available value to withdrawal
            userASNTValue = sASNT.balanceOf(_user) * IAutoCompound(autoCompound).tokenBalanceOf() / sASNT.totalSupply();
            
            //Live pending per user in the masterchef / Only for debug
            pending = IAutoCompound(autoCompound).calculateTotalPendingTokenRewards() * userShare / 1e18;

            //Reward accumulated since last user action (deposit/withdrawal)
            if (userASNTValue > tokenAtLastUserAction) {
                userEarnSinceLastAction = userASNTValue - tokenAtLastUserAction; 
            }          
        }

        //balance in user wallet
        inUserWallet = sASNT.balanceOf(_user);     

        return (pending,userShare,inUserWallet,userASNTValue,userEarnSinceLastAction);
    }



}