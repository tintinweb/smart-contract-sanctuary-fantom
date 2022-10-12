/**
 *Submitted for verification at FtmScan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILpDepositor {
    function claimLockerRewards(address pool,address[] calldata gaugeRewards,address[] calldata bribeRewards) external;
}
interface IBaseV1Voter{
    function gauges(address pool) external view returns (address gauge);
    function bribes(address gauge) external view returns (address bribe);
}
interface IBribe{
    function rewardsListLength() external view returns (uint256);
    function rewards(uint256) external view returns (address);
    function earned(address token, uint tokenId) external view returns (uint);
}
interface ERC20 {
    function transfer(address recipient, uint256 amount)external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract claimoor{

IBaseV1Voter public immutable voter;
ILpDepositor public immutable depositor;
address[] empty;
uint256 public immutable TokenID;
address[] bribeAddresses;

constructor(IBaseV1Voter _voter, ILpDepositor _depositor, uint256 _id){
    voter=_voter;
    depositor=_depositor;
    TokenID=_id;
    }
/// @notice fucku
/// lmk if theres a better way to do this, im just not rly that good at this fucking shit...
function claimRewards(address pool) external {
    address bribe = voter.bribes(voter.gauges(pool));
    uint256 bribeLength = IBribe(bribe).rewardsListLength();
    delete bribeAddresses;
    for (uint256 x=0; x < bribeLength-1;++x) {
        if(ERC20(IBribe(bribe).rewards(x)).balanceOf(address(bribe)) > 
        IBribe(bribe).earned(IBribe(bribe).rewards(x),TokenID)
        && IBribe(bribe).earned(IBribe(bribe).rewards(x),TokenID) > 0){
            bribeAddresses.push(IBribe(bribe).rewards(x));
            }
        }
    if (bribeAddresses.length != 0){
    depositor.claimLockerRewards(pool, empty, bribeAddresses);
        }
    else{
        depositor.claimLockerRewards(pool, empty, empty);
        }
    }
function claimEmpty(address pool) external {
    depositor.claimLockerRewards(pool, empty, empty);
    }//blart
}