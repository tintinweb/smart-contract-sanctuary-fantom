/**
 *Submitted for verification at FtmScan.com on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract settlement {
    address constant fdn = 0x431e81E5dfB5A24541b5Ff8762bDEF3f32F96354;
    address constant fusd = 0xAd84341756Bf337f5a0164515b1f6F993D194E1f;
    address constant dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

    function swap(uint amount) external {
        _safeTransferFrom(amount);
        _safeTransfer(amount);
    }

    function claim(erc20 token) external {
        require(msg.sender == fdn);
        token.transfer(fdn, token.balanceOf(address(this)));
    }

    function _safeTransfer(uint256 value) internal {
        (bool success, bytes memory data) =
        fusd.call(abi.encodeWithSelector(erc20.transfer.selector, msg.sender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(uint256 value) internal {
        (bool success, bytes memory data) =
        dai.call(abi.encodeWithSelector(erc20.transferFrom.selector, msg.sender, fdn, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}