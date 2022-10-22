/**
 *Submitted for verification at FtmScan.com on 2022-10-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;


interface IOracle {
    function price() external view returns (uint256);
}

interface IDeiLenderSolidex {
    function getLiquidationPrice(address user) external view returns (uint256);
    function oracle() external view returns(IOracle);
}

contract IsSolventLinding {
    IDeiLenderSolidex public ddLenderContract;
    IDeiLenderSolidex public udLenderContract;

    constructor(){
        ddLenderContract = IDeiLenderSolidex(0x118FF56bb12E5E0EfC14454B8D7Fa6009487D64E);
        udLenderContract = IDeiLenderSolidex(0x8D643d954798392403eeA19dB8108f595bB8B730);
    }

    function isSolvent(address user) external view returns (bool, bool) {
        bool ddIsSolvent = ddLenderContract.getLiquidationPrice(user) > ddLenderContract.oracle().price();
        bool udIsSolvent = udLenderContract.getLiquidationPrice(user) > udLenderContract.oracle().price();
        return (ddIsSolvent, udIsSolvent);

    }

}