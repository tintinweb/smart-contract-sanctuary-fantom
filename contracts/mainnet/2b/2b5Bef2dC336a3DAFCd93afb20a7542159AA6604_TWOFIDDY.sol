/**
 *Submitted for verification at FtmScan.com on 2022-09-23
*/

//SPDX-License-Identifier: TWO FIDDY
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
pragma solidity ^0.8.0;
interface IVDEUS{
function getVirtualPrice() external view returns (uint256);
}
contract TWOFIDDY {

constructor(){}
IVDEUS vDEUScontract = IVDEUS(0x54a5039C403fff8538fC582e0e3f07387B707381);
function getTotalAtTwoFiddy(uint256 yourLP) external view returns(string memory , uint256){
return ("Your Dollar amount at $250",((yourLP * (vDEUScontract.getVirtualPrice()) * 250) / 1e18));
}
}
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/
/*TWO FIDDY*/