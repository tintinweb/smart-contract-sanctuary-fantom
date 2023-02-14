// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library CalldataDecoder {
    /// @notice In `allocate` we pack config (address, uint88, bool, bool) into bytes32 to save some gas on calldata length
    /// @dev parses bytes into the original data format
    /// this piece of code is not very clean, we plan to reimplement it in the future releases
    function decodeAllocation(bytes32 data)
        public
        pure
        returns (address pool, uint88 amount, bool isRedeem, bool useFullBalance)
    {
        bytes20 pool_bytes;
        // unable to handle amount larger than 309e24
        bytes11 amount_bytes;
        bytes1 type_bytes;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), data)
            pool_bytes := mload(add(freemem_pointer, 0x00))
            amount_bytes := mload(add(freemem_pointer, 0x14))
            type_bytes := mload(add(freemem_pointer, 0x1F))
        }
        pool = address(pool_bytes);
        amount = uint88(amount_bytes);
        uint8 flags = uint8(type_bytes & 0x0F);
        isRedeem = flags / 8 == 0;
        useFullBalance = flags % 2 == 1;
    }

    function decodeClaim(bytes32 data) public pure returns (address pool, uint88 amount, uint8 index) {
        bytes20 pool_bytes;
        // unable to handle amount larger than 309e24
        bytes11 amount_bytes;
        bytes1 index_bytes;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), data)
            pool_bytes := mload(add(freemem_pointer, 0x00))
            amount_bytes := mload(add(freemem_pointer, 0x14))
            index_bytes := mload(add(freemem_pointer, 0x1F))
        }
        pool = address(pool_bytes);
        amount = uint88(amount_bytes);
        index = uint8(index_bytes);
    }
}