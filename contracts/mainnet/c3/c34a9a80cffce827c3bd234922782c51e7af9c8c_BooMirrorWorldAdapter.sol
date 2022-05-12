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

interface BooMirrorWorldLike {
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _totalSupply);
    function boo() external view returns (address _boo);
}

interface IERC20 {
    function balanceOf(address _account) external view returns (uint256 _balance);
}

contract BooMirrorWorldAdapter is VaultLike {
    address constant xBOO = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    function decimals() external view override returns (uint8 _decimals)
    {
        return BooMirrorWorldLike(xBOO).decimals();
    }
    function totalSupply() external view override returns (uint256 _totalSupply) {
        return BooMirrorWorldLike(xBOO).totalSupply();
    }
    function totalReserve() external view override returns (uint256 _totalReserve) {
        return IERC20(BooMirrorWorldLike(xBOO).boo()).balanceOf(xBOO);
    }
}