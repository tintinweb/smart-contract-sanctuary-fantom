// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ForwarderStorage.sol";
import "./IForwarder.sol";

contract Forwarder is IForwarder, Ownable, ForwarderStorage{

  constructor() {}

  function metaTransfer(bytes memory signature, bytes memory data, uint256 nonce, uint256 validTill) override public {
      if (block.timestamp >= validTill) revert ExpiredSignatureError("Forwarder-metaTransfer: message signature expired!");
      address signer = getSigner(metaTransferHash(data), signature);
      if (signer == address(0)) revert InvalidAddressError("Signer address is invalid");
      if (nonce != replayNonce[signer]) revert InvalidNonceError("Nonce does not match replayNonce for signer");
      replayNonce[signer]++;
      bytes memory modifiedData = bytes.concat(data, abi.encode(signer));
      (bool success, bytes memory resData) = revenantStash.call(modifiedData);
      if (!success) revert TransactionFailedError("Transaction NSF.");
  }
  function setRevenantStash(address _revenantStash) override external{
    revenantStash=_revenantStash;
  }

  function metaTransferHash(bytes memory data) override public pure returns (bytes32) {
    return keccak256(abi.encodePacked(data));
  }

  function getSigner(bytes32 _hash, bytes memory _signature)  internal pure returns (address){
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (_signature.length != 65) {
        return address(0);
    }
    assembly {
        r := mload(add(_signature, 32))
        s := mload(add(_signature, 64))
        v := byte(0, mload(add(_signature, 96)))
    }
    if (v < 27) {
        v += 27;
    }
    if (v != 27 && v != 28) {
        return address(0);
    } else {
      return ecrecover(
        keccak256(
          abi.encodePacked(
              "\x19Ethereum Signed Message:\n32",
              _hash
          )
        ),
        v,
        r,
        s
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IForwarder{
    function metaTransfer(bytes memory signature, bytes memory data, uint256 nonce, uint256 validTill) external;
    function metaTransferHash(bytes memory data) external pure returns (bytes32);
    function setRevenantStash(address revenantStashAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ForwarderStorage{
  mapping (address => uint256) public replayNonce;
  address public revenantStash;
 
  error ExpiredSignatureError(string);
  error InvalidAddressError(string);
  error InvalidNonceError(string);
  error TransactionFailedError(string);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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