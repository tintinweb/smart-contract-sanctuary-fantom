// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { Ownable } from "./roles/Ownable.sol";
import { Contracts, IContractRegistry } from "./interfaces/IContractRegistry.sol";


contract ContractRegistry is IContractRegistry, Ownable
{
  using EnumerableSet for EnumerableSet.Bytes32Set;


  bytes32 private constant _ORACLE = keccak256("Oracle");
  bytes32 private constant _TOKEN_REG = keccak256("TokenRegistry");
  bytes32 private constant _VAULT = keccak256("Vault");
  bytes32 private constant _COORDINATOR = keccak256("Coordinator");
  bytes32 private constant _DEPOSIT_MGR = keccak256("DepositManager");
  bytes32 private constant _BORROW_MGR = keccak256("BorrowManager");
  bytes32 private constant _STAKING_MGR = keccak256("StakingManager");
  bytes32 private constant _FEE_MGR = keccak256("FeeManager");
  bytes32 private constant _COL_MGR = keccak256("CollateralizationManager");
  bytes32 private constant _REWARD_MGR = keccak256("RewardManager");


  struct Queued
  {
    uint32 registrableTimestamp;
    address implementation;
  }


  EnumerableSet.Bytes32Set private _queued;

  bool private _queuing;


  mapping(bytes32 => Queued) private _queue;
  mapping(bytes32 => address) private _implementation;


  event Queue(bytes32 key, address implementation);
  event Unqueue(bytes32 key, address implementation);

  event Register(bytes32 key, address implementation);


  function queuing () public view returns (bool)
  {
    return _queuing;
  }

  function activateQueue () external onlyOwner
  {
    require(!_queuing, "queuing");

    require(_implementation[_ORACLE] != address(0), "!set oracle");
    require(_implementation[_VAULT] != address(0), "!set vault");
    require(_implementation[_TOKEN_REG] != address(0), "!set token reg");
    require(_implementation[_COORDINATOR] != address(0), "!set coordinator");
    require(_implementation[_STAKING_MGR] != address(0), "!set staking mgr");
    require(_implementation[_DEPOSIT_MGR] != address(0), "!set deposit mgr");
    require(_implementation[_BORROW_MGR] != address(0), "!set borrow mgr");
    require(_implementation[_FEE_MGR] != address(0), "!set fee mgr");
    require(_implementation[_COL_MGR] != address(0), "!set col mgr");
    require(_implementation[_REWARD_MGR] != address(0), "!set reward mgr");


    _queuing = true;
  }


  function _isValidKey (bytes32 key) private pure
  {
    require(key != bytes32(0), "!valid key");
  }

  function _isQueued (bytes32 key, address implementation) private view
  {
    _isValidKey(key);
    require(_queuing, "!queuing");
    require(implementation != address(0), "!queued");
  }

  function _isNotQueued (bytes32 key, address implementation) private view
  {
    _isValidKey(key);
    require(_queuing, "!queuing");
    require(implementation == address(0), "queued");
  }

  function queue (bytes32 key, address implementation) external onlyOwner
  {
    _isNotQueued(key, _queue[key].implementation);
    require(implementation != address(0), "!valid impl");
    require(_implementation[key] != implementation, "reg'd");


    _queued.add(key);
    _queue[key] = Queued({ registrableTimestamp: uint32(block.timestamp + 1 days), implementation: implementation });


    emit Queue(key, implementation);
  }

  function _unqueue (bytes32 key, address implementation) private
  {
    _queued.remove(key);
    _queue[key] = Queued({ registrableTimestamp: 0, implementation: address(0) });


    emit Unqueue(key, implementation);
  }

  function unqueue (bytes32 key) external onlyOwner
  {
    Queued memory queued = _queue[key];

    _isQueued(key, queued.implementation);


    _unqueue(key, queued.implementation);
  }


  function _finishRegister (bytes32 key, address implementation) private
  {
    _implementation[key] = implementation;


    emit Register(key, implementation);
  }

  function registerQueued (bytes32 key) external onlyOwner
  {
    Queued memory queued = _queue[key];

    _isQueued(key, queued.implementation);
    require(queued.registrableTimestamp > 0 && block.timestamp > queued.registrableTimestamp, "queuing");


    _unqueue(key, queued.implementation);

    _finishRegister(key, queued.implementation);
  }

  function _register (bytes32 key, address implementation) private
  {
    _isValidKey(key);
    require(!_queuing, "queuing");
    require(implementation != address(0), "!valid impl");
    require(_implementation[key] != implementation, "reg'd");


    _finishRegister(key, implementation);
  }

  function register (bytes32 key, address implementation) external onlyOwner
  {
    _register(key, implementation);
  }

  function registerContracts (bytes32[] calldata keys, address[] calldata implementations) external onlyOwner
  {
    require(keys.length == implementations.length, "!=");


    for (uint256 i = 0; i < keys.length; i++)
    {
      _register(keys[i], implementations[i]);
    }
  }


  function exists (bytes32 key) external view returns (bool)
  {
    return _implementation[key] != address(0);
  }

  function getKey (string calldata name) external pure returns (bytes32)
  {
    return keccak256(bytes(name));
  }

  function getContract (bytes32 key) external view override returns (address)
  {
    address implementation = _implementation[key];

    require(implementation != address(0), "!exist impl");


    return implementation;
  }

  function getQueued () public view returns (bytes32[] memory)
  {
    return _queued.values();
  }

  function getQueuedOf (bytes32 key) public view returns (Queued memory)
  {
    return _queue[key];
  }


  function borrowContracts () external view override returns (Contracts memory)
  {
    return Contracts
    ({
      oracle: _implementation[_ORACLE],
      tokenRegistry: _implementation[_TOKEN_REG],
      coordinator: _implementation[_COORDINATOR],
      stakingManager: _implementation[_STAKING_MGR],
      feeManager: _implementation[_FEE_MGR],
      collateralizationManager: _implementation[_COL_MGR],
      rewardManager: _implementation[_REWARD_MGR]
    });
  }


  function oracle () external view override returns (address)
  {
    return _implementation[_ORACLE];
  }

  function tokenRegistry () external view override returns (address)
  {
    return _implementation[_TOKEN_REG];
  }

  function vault () external view override returns (address)
  {
    return _implementation[_VAULT];
  }

  function coordinator () external view override returns (address)
  {
    return _implementation[_COORDINATOR];
  }

  function depositManager () external view override returns (address)
  {
    return _implementation[_DEPOSIT_MGR];
  }

  function borrowManager () external view override returns (address)
  {
    return _implementation[_BORROW_MGR];
  }

  function stakingManager () external view override returns (address)
  {
    return _implementation[_STAKING_MGR];
  }

  function feeManager () external view override returns (address)
  {
    return _implementation[_FEE_MGR];
  }

  function collateralizationManager () external view override returns (address)
  {
    return _implementation[_COL_MGR];
  }

  function rewardManager () external view override returns (address)
  {
    return _implementation[_REWARD_MGR];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


contract Ownable
{
  bool private _delaying;

  address private _owner;
  address private _newOwner;

  uint256 private _transferableTimestamp;


  event InitiateTransfer(address indexed currentOwner, address indexed newOwner, uint256 transferableTimestamp);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event CancelTransfer();


  modifier onlyOwner ()
  {
    require(msg.sender == _owner, "!owner");
    _;
  }

  constructor ()
  {
    _owner = msg.sender;


    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner () public view returns (address)
  {
    return _owner;
  }

  function transferInfo () public view returns (bool, address, uint256)
  {
    return (_delaying, _newOwner, _transferableTimestamp);
  }


  function renounceOwnership () public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));


    _owner = address(0);
  }


  function activateDelay () public onlyOwner
  {
    require(!_delaying, "delaying");


    _delaying = true;
  }

  function initiateTransfer (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");
    require(_transferableTimestamp == 0, "transferring");


    _newOwner = newOwner;
    _transferableTimestamp = block.timestamp + 2 days;


    emit InitiateTransfer(msg.sender, newOwner, _transferableTimestamp);
  }

  function cancelTransfer () public onlyOwner
  {
    require(_transferableTimestamp != 0, "!transferring");


    _transferableTimestamp = 0;
    _newOwner = address(0);


    emit CancelTransfer();
  }

  function transferOwnership (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");


    if (_delaying)
    {
      require(newOwner == _newOwner, "!=");
      require(_transferableTimestamp > 0 && block.timestamp > _transferableTimestamp, "!transferable");


      _transferableTimestamp = 0;
      _newOwner = address(0);
    }


    emit OwnershipTransferred(_owner, newOwner);


    _owner = newOwner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


struct Contracts
{
  address oracle;
  address tokenRegistry;
  address coordinator;
  address stakingManager;
  address feeManager;
  address collateralizationManager;
  address rewardManager;
}


interface IContractRegistry
{
  function getContract (bytes32 key) external view returns (address);


  function borrowContracts () external view returns (Contracts memory);


  function oracle () external view returns (address);

  function tokenRegistry () external view returns (address);

  function vault () external view returns (address);

  function coordinator () external view returns (address);

  function depositManager () external view returns (address);

  function borrowManager () external view returns (address);

  function stakingManager () external view returns (address);

  function feeManager () external view returns (address);

  function collateralizationManager () external view returns (address);

  function rewardManager () external view returns (address);
}