/**
 *Submitted for verification at FtmScan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @title Small library for working with strings
 * @author yearn.finance
 */

library Strings {
  /**
   * @notice Search for a needle in a haystack
   * @param haystack The string to search
   * @param needle The string to search for
   */
  function stringStartsWith(string memory haystack, string memory needle)
    public
    pure
    returns (bool)
  {
    return indexOfStringInString(needle, haystack) == 0;
  }

  /**
   * @notice Find the index of a string in another string
   * @param needle The string to search for
   * @param haystack The string to search
   * @return Returns -1 if no match is found, otherwise returns the index of the match
   */
  function indexOfStringInString(string memory needle, string memory haystack)
    public
    pure
    returns (int256)
  {
    bytes memory _needle = bytes(needle);
    bytes memory _haystack = bytes(haystack);
    if (_haystack.length < _needle.length) {
      return -1;
    }
    bool _match;
    for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
      for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
        uint8 needleChar = uint8(_needle[needleIdx]);
        if (haystackIdx + needleIdx >= _haystack.length) {
          return -1;
        }
        uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
        if (needleChar == haystackChar) {
          _match = true;
          if (needleIdx == _needle.length - 1) {
            return int256(haystackIdx);
          }
        } else {
          _match = false;
          break;
        }
      }
    }
    return -1;
  }

  /**
   * @notice Check to see if two strings are exactly equal
   * @dev Supports strings of arbitrary length
   * @param input0 First string to compare
   * @param input1 Second string to compare
   * @return Returns true if strings are exactly equal, false if not
   */
  function stringsEqual(string memory input0, string memory input1)
    public
    pure
    returns (bool)
  {
    uint256 input0Length = bytes(input0).length;
    uint256 input1Length = bytes(input1).length;
    uint256 maxLength;
    if (input0Length > input1Length) {
      maxLength = input0Length;
    } else {
      maxLength = input1Length;
    }
    uint256 numberOfRowsToCompare = (maxLength / 32) + 1;
    bytes32 input0Bytes32;
    bytes32 input1Bytes32;
    for (uint256 rowIdx; rowIdx < numberOfRowsToCompare; rowIdx++) {
      uint256 offset = 0x20 * (rowIdx + 1);
      assembly {
        input0Bytes32 := mload(add(input0, offset))
        input1Bytes32 := mload(add(input1, offset))
      }
      if (input0Bytes32 != input1Bytes32) {
        return false;
      }
    }
    return true;
  }

  /**
   * @notice Convert ASCII to integer
   * @param input Integer as a string (ie. "345")
   * @param base Base to use for the conversion (10 for decimal)
   * @return output Returns uint256 representation of input string
   * @dev Based on GemERC721 utility but includes a fix
   */
  function atoi(string memory input, uint8 base)
    public
    pure
    returns (uint256 output)
  {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    bytes memory buf = bytes(input);
    for (uint256 idx = 0; idx < buf.length; idx++) {
      uint8 digit = uint8(buf[idx]) - 0x30;
      if (digit > 10) {
        digit -= 7;
      }
      require(digit < base);
      output *= base;
      output += digit;
    }
    return output;
  }

  /**
   * @notice Convert integer to ASCII
   * @param input Integer as a string (ie. "345")
   * @param base Base to use for the conversion (10 for decimal)
   * @return output Returns string representation of input integer
   * @dev Based on GemERC721 utility but includes a fix
   */
  function itoa(uint256 input, uint8 base)
    public
    pure
    returns (string memory output)
  {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    if (input == 0) {
      return "0";
    }
    bytes memory buf = new bytes(256);
    uint256 idx = 0;
    while (input > 0) {
      uint8 digit = uint8(input % base);
      uint8 ascii = digit + 0x30;
      if (digit > 9) {
        ascii += 7;
      }
      buf[idx++] = bytes1(ascii);
      input /= base;
    }
    uint256 length = idx;
    for (idx = 0; idx < length / 2; idx++) {
      buf[idx] ^= buf[length - 1 - idx];
      buf[length - 1 - idx] ^= buf[idx];
      buf[idx] ^= buf[length - 1 - idx];
    }
    output = string(buf);
  }
}

/**
 * @title Decode raw calldata and params
 * @author yearn.finance
 */

library AbiDecoder {
  /**
   * @notice Extract all params from calldata given a list of param types and raw calldata bytes
   * @param paramTypes An array of param types (ie. ["address", "bytes[]", "uint256"])
   * @param data Raw calldata (including 4byte method selector)
   * @return Returns an array of input param data
   */
  function getParamsFromCalldata(
    string[] memory paramTypes,
    bytes calldata data
  ) public pure returns (bytes[] memory) {
    uint256 numberOfParams = paramTypes.length;
    bytes[] memory results = new bytes[](numberOfParams);
    for (uint256 paramIdx = 0; paramIdx < numberOfParams; paramIdx++) {
      string memory paramType = paramTypes[paramIdx];
      bytes memory param = getParamFromCalldata(data, paramType, paramIdx);
      results[paramIdx] = param;
    }
    return results;
  }

  /**
   * @notice Extract param bytes given calldata, param type and param index
   * @param data Raw calldata (including 4byte method selector)
   * @param paramIdx The position of the param data to fetch (0 will fetch the first param)
   * @return Returns the raw data of the param at paramIdx index
   * @dev If the type is "bytes", "bytes[]", "string" or "string[]" the offset byte
   *      will be set to 0x20. The param is isolated in such a way that it can be passed as an
   *      input to another method selector using call or staticcall.
   */
  function getParamFromCalldata(
    bytes calldata data,
    string memory paramType,
    uint256 paramIdx
  ) public pure returns (bytes memory) {
    uint256 paramsStartIdx = 0x04; // Start after method selector
    uint256 paramOffset = 0x20 * paramIdx;
    bytes memory paramDescriptorValue = bytes(
      data[paramsStartIdx + paramOffset:paramsStartIdx + paramOffset + 0x20]
    );

    bool paramTypeIsStringOrBytes = Strings.stringsEqual(paramType, "bytes") ||
      Strings.stringsEqual(paramType, "string");
    bool paramTypeIsStringArrayOrBytesArray = Strings.stringsEqual(
      paramType,
      "bytes[]"
    ) || Strings.stringsEqual(paramType, "string[]");
    bool _paramTypeIsArray = paramTypeIsArray(paramType);

    uint256 paramStartIdx = uint256(bytes32(paramDescriptorValue)) + 0x04;
    if (paramTypeIsStringOrBytes) {
      return extractParamForBytesType(data, paramStartIdx);
    } else if (paramTypeIsStringArrayOrBytesArray) {
      return extractParamForBytesArrayType(data, paramStartIdx);
    } else if (_paramTypeIsArray) {
      return extractParamForSimpleArray(data, paramStartIdx);
    } else {
      return paramDescriptorValue;
    }
  }

  /**
   * @notice Extract param for "bytes" and "string" types given calldata and a param start index
   * @param data Raw calldata (including 4byte method selector)
   * @param paramStartIdx The offset the param starts at
   * @return Returns the raw data of the param at paramIdx index
   */
  function extractParamForBytesType(bytes calldata data, uint256 paramStartIdx)
    public
    pure
    returns (bytes memory)
  {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 bytesLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 bytesLength = uint256(bytesLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(bytesLengthBytes)
    );
    uint256 numberOfRowsOfBytes = (bytesLength / 32) + 1;
    for (uint256 rowIdx; rowIdx < numberOfRowsOfBytes; rowIdx++) {
      uint256 rowStartIdx = paramEndIdx + (0x20 * rowIdx);
      dataToAdd = abi.encodePacked(
        dataToAdd,
        data[rowStartIdx:rowStartIdx + 0x20]
      );
    }
    return dataToAdd;
  }

  /**
   * @notice Extract param for "bytes[]" and "string[]" types given calldata and a param start index
   * @param data Raw calldata (including 4byte method selector)
   * @param paramStartIdx The offset the param starts at
   * @return Returns the raw data of the param at paramIdx index
   */
  function extractParamForBytesArrayType(
    bytes calldata data,
    uint256 paramStartIdx
  ) public pure returns (bytes memory) {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 arrayLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 arrayLength = uint256(arrayLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(arrayLengthBytes)
    );
    uint256 lastOffsetStartIdx = paramEndIdx + (0x20 * arrayLength) - 0x20;
    uint256 lastOffset = uint256(
      bytes32(data[lastOffsetStartIdx:lastOffsetStartIdx + 0x20])
    );
    bytes32 lastElementBytesLengthBytes = bytes32(
      data[paramEndIdx + lastOffset:paramEndIdx + lastOffset + 0x20]
    );
    uint256 lastElementBytesLength = uint256(lastElementBytesLengthBytes);
    uint256 numberOfRowsOfBytesForLastElement = (lastElementBytesLength / 32) +
      1;
    uint256 dataEndIdx = paramEndIdx +
      lastOffset +
      0x20 +
      (0x20 * numberOfRowsOfBytesForLastElement);
    dataToAdd = abi.encodePacked(dataToAdd, data[paramEndIdx:dataEndIdx]);
    return dataToAdd;
  }

  /**
   * @notice Extract param for "*[]" types given calldata and a param start index, assuming each element is 32 bytes
   * @param data Raw calldata (including 4byte method selector)
   * @param paramStartIdx The offset the param starts at
   * @return Returns the raw data of the param at paramIdx index
   */
  function extractParamForSimpleArray(
    bytes calldata data,
    uint256 paramStartIdx
  ) public pure returns (bytes memory) {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 arrayLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 arrayLength = uint256(arrayLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(arrayLengthBytes)
    );
    for (uint256 rowIdx; rowIdx < arrayLength; rowIdx++) {
      uint256 rowStartIdx = paramEndIdx + (0x20 * rowIdx);
      dataToAdd = abi.encodePacked(
        dataToAdd,
        data[rowStartIdx:rowStartIdx + 0x20]
      );
    }
    return dataToAdd;
  }

  /**
   * @notice Check to see if the last two characters of a string are "[]"
   * @param paramType Param type as a string (ie. "uint256", "uint256[]")
   * @return Returns true if the paramType ends with "[]", false if not
   */
  function paramTypeIsArray(string memory paramType)
    internal
    pure
    returns (bool)
  {
    bytes32 lastTwoCharacters;
    assembly {
      let len := mload(paramType)
      lastTwoCharacters := mload(add(add(paramType, 0x20), sub(len, 2)))
    }
    return lastTwoCharacters == bytes32(bytes("[]"));
  }
}