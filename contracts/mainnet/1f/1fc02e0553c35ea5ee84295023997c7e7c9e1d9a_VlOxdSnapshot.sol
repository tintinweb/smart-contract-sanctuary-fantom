/**
 *Submitted for verification at FtmScan.com on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOxLens {
    function userProxyByAccount(address accountAddress)
        external
        view
        returns (address);
}

interface IVlOxd {
    function lockedBalanceOf(address) external view returns (uint256 amount);
}

contract VlOxdSnapshot {
    address public constant vlOxdAddress =
        0xDA00527EDAabCe6F97D89aDb10395f719E5559b9;
    address public constant oxLensAddress =
        0xDA00137c79B30bfE06d04733349d98Cf06320e69;
    IOxLens private oxLens = IOxLens(oxLensAddress);
    IVlOxd private vlOxd = IVlOxd(vlOxdAddress);

    function balanceOf(address accountAddress) external view returns (uint256) {
        address userProxyAddress = oxLens.userProxyByAccount(accountAddress);
        return vlOxd.lockedBalanceOf(userProxyAddress);
    }
}