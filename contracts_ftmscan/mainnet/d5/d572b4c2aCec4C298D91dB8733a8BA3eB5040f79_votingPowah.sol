/**
 *Submitted for verification at FtmScan.com on 2022-02-05
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IMasterchef{
    function userInfo(uint, address) external view returns(uint amount, uint rewardDebt);
}

interface IERC20{
    function balanceOf(address) external view returns(uint);
    function totalSupply() external view returns(uint);
}

library SafeToken {
    function balanceOf(address token, address user) internal view returns (uint) {
        return IERC20(token).balanceOf(user);
    }
    function totalSupply(address token) internal view returns (uint) {
        return IERC20(token).totalSupply();
    }
}

contract votingPowah{
    using SafeToken for address;

    IMasterchef public chef = IMasterchef(0x41Abb76D39c4dCD885340f9B98c26b51250644cc);
    address public panic = address(0xA882CeAC81B22FC2bEF8E1A82e823e3E9603310B);
    address public lpToken = address(0xa341D77315e5E130ad386e034B4c9714cB149F4a);

    function pointsPerLp() public view returns(uint){
        uint totalPanic = panic.balanceOf(lpToken);
        uint totalLp = lpToken.totalSupply();
        return(totalPanic*8e18/totalLp);
    }

    function singleAssetBal(address _user) public view returns(uint){
        uint _onWallet = panic.balanceOf(_user);
        (uint _onChef,) = chef.userInfo(1,_user);
        return _onWallet + _onChef;
    }

    function lpBal(address _user) public view returns(uint){
        uint _onWallet = lpToken.balanceOf(_user);
        (uint _onChef,) = chef.userInfo(0,_user);
        return _onWallet + _onChef;
    }

    function powah(address _user) public view returns(uint){
        uint lpPoints = lpBal(_user)*pointsPerLp()/1e18;
        uint singlePoints = singleAssetBal(_user);
        return lpPoints + singlePoints;
    }
}