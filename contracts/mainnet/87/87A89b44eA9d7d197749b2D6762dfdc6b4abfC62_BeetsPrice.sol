/**
 *Submitted for verification at FtmScan.com on 2022-05-18
*/

// Be name khoda
// Bime Abolfazl

// Author: MiKO


// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


pragma solidity ^0.8.14;


enum SwapKind { GIVEN_IN, GIVEN_OUT }

interface IAsset {}

struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

interface IVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

contract BeetsPrice {
    address public vault;
    constructor(address vault_) {
        vault = vault_;
    }

    function getAmountOut(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable {
        uint256 amountOut = IVault(vault).swap(singleSwap, funds, limit, deadline);
        require(false, Strings.toString(amountOut));
    }

    function getDeusPrise(
        uint256 amount
    ) external payable {
        SingleSwap memory singleSwap;
        singleSwap.poolId = 0x7b9c58a1f259c316cd5600f22b414032ab8b699f00010000000000000000039e;
        singleSwap.kind = SwapKind.GIVEN_IN;
        singleSwap.assetIn = IAsset(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44);
        singleSwap.assetOut = IAsset(0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3);
        singleSwap.amount = amount;
        // singleSwap.userData = 0x0;

        FundManagement memory funds;
        funds.sender = msg.sender;
        funds.fromInternalBalance = false;
        funds.recipient = payable(msg.sender);
        funds.toInternalBalance = false;

        uint256 limit = 0;
        uint256 deadline = type(uint256).max;
        uint256 amountOut = IVault(vault).swap(singleSwap, funds, limit, deadline);
        require(false, Strings.toString(amountOut));
    }
}