/**
 *Submitted for verification at FtmScan.com on 2022-09-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IVDEUS{
function getVirtualPrice() external view returns (uint256);
function calculateSwap(uint8 tokenindexfrom, uint8 tokenindexTo, uint256 dx) external view returns(uint256);
function getAPrecise() external view returns(uint256);
}
contract cDEUS_Stats {
    constructor(){}

IVDEUS vDEUScontract = IVDEUS(0x54a5039C403fff8538fC582e0e3f07387B707381);

// LP value in dollars at $250
function getTotalAtTwoFiddy(uint256 yourLP) external view returns(uint256){
    return (((yourLP * (vDEUScontract.getVirtualPrice()) * 250) / 1e18));
}
// current ratio of deus <> vDEUS swap
function getCurrentRatio() external view returns(uint256){
    return(vDEUScontract.calculateSwap(1,0,1000000000000000000) /1e15);

}
// LP value in Deus e.g. 993 = 0.993 deus per LP
function getLPValueInDeus() external view returns(uint256){
    return vDEUScontract.getVirtualPrice()/1e15;
}
// A coefficient on the swap
function getARatio() external view returns(uint256){
    return vDEUScontract.getAPrecise();
}
}