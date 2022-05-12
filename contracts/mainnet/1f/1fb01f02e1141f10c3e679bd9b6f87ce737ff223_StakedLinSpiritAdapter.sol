/**
 *Submitted for verification at FtmScan.com on 2022-05-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.6.12;

interface VaultLike {
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _totalSupply);
    function totalReserve() external view returns (uint256 _totalReserve);
}

interface StakedLinSpiritLike {
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _totalSupply);
    function balance() external view returns (uint256 _balance);
}

contract StakedLinSpiritAdapter is VaultLike {
    address constant sLINSPIRIT = 0x3F569724ccE63F7F24C5F921D5ddcFe125Add96b;
    function decimals() external view override returns (uint8 _decimals)
    {
        return StakedLinSpiritLike(sLINSPIRIT).decimals();
    }
    function totalSupply() external view override returns (uint256 _totalSupply) {
        return StakedLinSpiritLike(sLINSPIRIT).totalSupply();
    }
    function totalReserve() external view override returns (uint256 _totalReserve) {
        return StakedLinSpiritLike(sLINSPIRIT).balance();
    }
}