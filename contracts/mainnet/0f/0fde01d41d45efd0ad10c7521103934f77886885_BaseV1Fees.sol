/**
 *Submitted for verification at FtmScan.com on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

library Math {
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IBaseV1Callee {
    function hook(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IBaseV1Factory {
    function protocolAddresses(address _pair) external returns (address);
    function spiritMaker() external returns (address);
    function stableFee() external returns (uint256);
    function variableFee() external returns (uint256);
}

// Base V1 Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract BaseV1Fees {

    address internal immutable factory; // Factory that created the pairs
    address internal immutable pair; // The pair it is bonded to
    address internal immutable token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pair, saved localy and statically for gas optimization

    constructor(address _token0, address _token1, address _factory) {
        pair = msg.sender;
        factory = _factory;
        token0 = _token0;
        token1 = _token1;
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint amount0, uint amount1) external returns (uint256 claimed0, uint256 claimed1) {
        require(msg.sender == pair);
        uint256 counter = 4;
        // send 25% to protocol address if protocol address exists
        address protocolAddress = IBaseV1Factory(factory).protocolAddresses(pair);
        if (protocolAddress != address(0x0)) {
            if (amount0 > 0) _safeTransfer(token0, protocolAddress, amount0 / 4);
            if (amount1 > 0) _safeTransfer(token1, protocolAddress, amount1 / 4);
            counter--;
        }
        // send 25% to spiritMaker
        address spiritMaker = IBaseV1Factory(factory).spiritMaker();
        if (spiritMaker != address(0x0)) {
            if (amount0 > 0) _safeTransfer(token0, spiritMaker, amount0 / 4);
            if (amount1 > 0) _safeTransfer(token1, spiritMaker, amount1 / 4);
            counter--;
        }
        claimed0 = amount0 * counter / 4;
        claimed1 = amount1 * counter / 4;
        // send the rest to owner of LP
        if (amount0 > 0) _safeTransfer(token0, recipient, claimed0);
        if (amount1 > 0) _safeTransfer(token1, recipient, claimed1);
    }

}