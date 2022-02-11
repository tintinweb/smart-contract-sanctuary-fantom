/**
 *Submitted for verification at FtmScan.com on 2022-02-07
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
interface IERC20 {
    function decimals() external view returns(uint8);
    function balanceOf(address owner) external view returns(uint);
    function totalSupply() external view returns(uint);
}
interface Investment{
    function totalValueDeployed() external view returns (uint);
}
contract CurveGaugeInvestment is IERC20{
    function balanceOf(address owner) override external view returns(uint){
        return owner==0xCB54EA94191B280C296E6ff0E37c7e76Ad42dC6A?totalSupply():0;
    }
    function decimals() override external pure returns(uint8){
        return 9;
    }
    function totalSupply() override public view returns(uint){
        return Investment(0x344456Df952FA32Be9C860c4EB23385384C4ef7A).totalValueDeployed();
    }
}