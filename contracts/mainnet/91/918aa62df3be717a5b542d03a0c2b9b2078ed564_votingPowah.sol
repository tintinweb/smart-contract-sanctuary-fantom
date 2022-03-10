/**
 *Submitted for verification at FtmScan.com on 2022-03-10
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;


interface IStaking{
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function lockedBalances(
        address user
    ) view external returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
}

contract votingPowah{

    IStaking public staking = IStaking(0x536b88CC4Aa42450aaB021738bf22D63DDC7303e);

    function powah(address _user) public view returns(uint){
        (uint _onLock,,,) = staking.lockedBalances(_user);
        return _onLock;
    }

}