/**
 *Submitted for verification at FtmScan.com on 2022-09-19
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.9;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract DelilandEnergyGrid {
    address ENERg = 0x126eE076DA8cc4ffCA5cd89BB4a0EbfE6Fa09189;
    address pENERg = 0x5740BC97388E468829e5d43bcF3E56DAc65fDC1A;

    function _powerConsumption () internal view returns (uint256) {
        return ( IERC20(ENERg).totalSupply() / 2 );
    }

    function powerConsumption () public view returns (uint256) {
        return _powerConsumption();
    }

    function _powerProduction () internal view returns (uint256) {
        return IERC20(ENERg).balanceOf(pENERg);
    }

    function powerProduction () public view returns (uint256) {
        return _powerProduction();
    }
  
    function isPowered () public view returns (bool) {
        return ( _powerProduction() > _powerConsumption() );
    }
}