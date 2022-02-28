// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./lib/Base64.sol";
import "./CryptoBitsTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Crypto Bit Renderer
contract CryptoBitsRenderer is Ownable {
  /* solhint-disable quotes */

  /* -------------------------------------------------------------------------- */
  /*                              Description State                             */
  /* -------------------------------------------------------------------------- */

  /// @notice Metadata description.
  string public description;

  /* -------------------------------------------------------------------------- */
  /*                                Layers State                                */
  /* -------------------------------------------------------------------------- */

  /// @notice item index => layer index => layer name.
  mapping(uint256 => string)[6] internal _layerNames;

  /// @notice item index => layer index => layer image.
  mapping(uint256 => string)[6] internal _layerImages;

  /// @dev Initialize with the new description.
  constructor(string memory newDescription) {
    description = newDescription;
  }

  /* -------------------------------------------------------------------------- */
  /*                                Layers Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Add/Set new layers into the contract.
  function addLayers(LayerInput[] calldata inputs) external onlyOwner {
    for (uint256 i = 0; i < inputs.length; i++) {
      _layerNames[inputs[i].itemIndex][inputs[i].layerIndex] = inputs[i].name;
      _layerImages[inputs[i].itemIndex][inputs[i].layerIndex] = inputs[i].image;
    }
  }

  /// @notice Get a layer from `itemIndex` and `layerIndex`.
  function getLayer(uint8 itemIndex, uint8 layerIndex) external view returns (Layer memory) {
    return Layer(_layerNames[itemIndex][layerIndex], _layerImages[itemIndex][layerIndex]);
  }

  /// @notice Generate a character based on `id` and environment variables.
  function generateCharacter(uint256 id) external view returns (CryptoBit memory character) {
    uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, block.coinbase, id)));
    character.background = uint8((seed <<= 42) % 30); // 30 backgrounds
    character.clothes = uint8((seed <<= 42) % 22); // 22 clothes
    character.face = uint8((seed <<= 42) % 11); // 11 faces
    character.head = uint8((seed <<= 42) % 9); // 9 heads
    character.hat = uint8((seed <<= 42) % 19); // 19 hats
    character.accessory = uint8((seed <<= 42) % 9); // 9 accessories
  }

  /* -------------------------------------------------------------------------- */
  /*                              Description Logic                             */
  /* -------------------------------------------------------------------------- */

  /// @notice Set `description` to `newDescription`.
  function setDescription(string calldata newDescription) external onlyOwner {
    description = newDescription;
  }

  /* -------------------------------------------------------------------------- */
  /*                               Renderer Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Get a valid token uri for `id` and character `character`.
  function tokenURI(uint256 id, CryptoBit memory character) external view returns (string memory) {
    bytes memory output = abi.encodePacked(
      '{"name":"Crypto Bit #',
      Strings.toString(id),
      '","description":"',
      description,
      '", "attributes": [',
      _buildAttribute(character),
      '], "image": "',
      tokenSVG(character),
      '"}'
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(output)));
  }

  /// @notice Generate an SVG for `character`.
  function tokenSVG(CryptoBit memory character) public view returns (string memory) {
    string memory output = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="character" width="100%" height="100%" version="1.1" viewBox="0 0 16 16">',
        _buildImage(_layerImages[0][character.background]),
        _buildImage(_layerImages[1][character.clothes]),
        _buildImage(_layerImages[2][character.face]),
        _buildImage(_layerImages[3][character.head]),
        _buildImage(_layerImages[4][character.hat]),
        _buildImage(_layerImages[5][character.accessory]),
        "<style>#character{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
      )
    );

    return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(output))));
  }

  /// @notice Generate an svg <image> element based on `image` png.
  function _buildImage(string memory image) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<image x="0" y="0" width="16" height="16" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
        image,
        '"/>'
      );
  }

  /// @notice Generate valid metadata attributes for `character`.
  function _buildAttribute(CryptoBit memory character) internal view returns (bytes memory) {
    return
      abi.encodePacked(
        '{"trait_type": "Background", "value": "',
        _layerNames[0][character.background],
        '"},'
        '{"trait_type": "Clothes", "value": "',
        _layerNames[1][character.clothes],
        '"},',
        '{"trait_type": "Face", "value": "',
        _layerNames[2][character.face],
        '"},',
        '{"trait_type": "Head", "value": "',
        _layerNames[3][character.head],
        '"},',
        '{"trait_type": "Hat", "value": "',
        _layerNames[4][character.hat],
        '"},',
        '{"trait_type": "Hat", "value": "',
        _layerNames[5][character.accessory],
        '"}'
      );
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Base64 {
  string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct CryptoBit {
  uint8 background;
  uint8 clothes;
  uint8 face;
  uint8 head;
  uint8 hat;
  uint8 accessory;
}

struct Layer {
  string name;
  string image;
}

struct LayerInput {
  string name;
  string image;
  uint8 itemIndex;
  uint8 layerIndex;
}

interface RendererLike {
  function tokenURI(uint256 id, CryptoBit memory cb) external view returns (string memory);

  function generateCharacter(uint256 id) external view returns (CryptoBit memory character);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}