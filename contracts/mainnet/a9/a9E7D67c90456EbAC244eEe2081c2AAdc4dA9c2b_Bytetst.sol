// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
pragma abicoder v2;

library BytesLib {
  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, 'slice_overflow');
    require(_bytes.length >= _start + _length, 'slice_outOfBounds');
    bytes memory tempBytes;
    assembly {
      switch iszero(_length)
      case 0 {
        tempBytes := mload(0x40)
        let lengthmod := and(_length, 31)
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)
        for {
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }
        mstore(tempBytes, _length)
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      default {
        tempBytes := mload(0x40)
        mstore(tempBytes, 0)
        mstore(0x40, add(tempBytes, 0x20))
      }
    }
    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
    address tempAddress;
    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }
    return tempAddress;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, 'toUint16_outOfBounds');
    uint16 tempUint;
    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }
    return tempUint;
  }

  function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
    require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
    uint24 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x3), _start))
    }
    return tempUint;
  }
}

library PathHelper {
  using BytesLib for bytes;
  uint256 private constant ADDR_SIZE = 20;
  uint256 private constant FEE_SIZE = 3;
  uint256 private constant TOKEN_AND_POOL_OFFSET = ADDR_SIZE + FEE_SIZE;
  uint256 private constant POOL_DATA_OFFSET = TOKEN_AND_POOL_OFFSET + ADDR_SIZE;
  uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POOL_DATA_OFFSET + TOKEN_AND_POOL_OFFSET;

  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  function numPools(bytes memory path) internal pure returns (uint256) {
    return ((path.length - ADDR_SIZE) / TOKEN_AND_POOL_OFFSET);
  }

  function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(TOKEN_AND_POOL_OFFSET);
  }

  function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(0, POOL_DATA_OFFSET);
  }

  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(TOKEN_AND_POOL_OFFSET, path.length - TOKEN_AND_POOL_OFFSET);
  }
}

contract Bytetst {
  using PathHelper for bytes;

  struct SwapCallbackData {
    bytes path;
    address source;
  }

  function getCb(address tokenOut, uint24 fee, address tokenIn) public view returns(SwapCallbackData memory) {
    return SwapCallbackData({
      path: abi.encodePacked(tokenOut, fee, tokenIn),
      source: msg.sender
    });
  }

  function getCb2(address tokenOut, uint24 fee, address tokenIn) public view returns(bytes memory) {
    return abi.encode(abi.encodePacked(tokenOut, fee, tokenIn), msg.sender);
  }

  function getCb3(address tokenOut, uint24 fee, address tokenIn) public view returns(bytes memory) {
    return abi.encodePacked(abi.encodePacked(tokenOut, fee, tokenIn), msg.sender);
  }

  function decodeCb(bytes calldata data) public pure returns(address tokenIn, address tokenOut, uint24 fee) {
    SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
    (tokenIn, tokenOut, fee) = swapData.path.decodeFirstPool();
  }

  function decodeCb2(bytes calldata data) public pure returns (bool) {
    SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
    return swapData.path.hasMultiplePools();
  }

  function decodeCb3(bytes calldata data) public pure returns(bytes memory) {
    SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
    return swapData.path;
  }
}