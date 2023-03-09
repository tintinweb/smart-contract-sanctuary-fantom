// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Calendar.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract CalendarFactory {
  event CalendarAdded(address username, uint id);

  address public origin;
  Calendar[] public calendars;
  uint private cloneCount;

  constructor(address _origin) {
    origin = _origin;
  }

  function create() external {
    Calendar calendar = Calendar(Clones.clone(origin));
    cloneCount++;
    calendar.init(
      cloneCount,
      msg.sender
    );
    calendars.push(calendar);
    emit CalendarAdded(msg.sender, cloneCount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Calendar {
  event UpdateTitle(address username, uint calendarID, string title);
  event AddEvent(address username, uint eventID, string title);
  event UpdateEvent(address username, uint eventID, string eventTitle);
  event DeleteEvent(address username, uint eventID);

  uint public id;
  string public title;
  address public creator;

  function init(uint _id, address _creator) external {
    id = _id;
    creator = _creator;
  }

  function updateTitle(string memory _title) external {
    title = _title;
    emit UpdateTitle(msg.sender, id, title);
  }

  struct Event {
    uint id;
    address username;
    string title;
    uint startTime;
    uint endTime;
    bool isDeleted;
  }

  Event[] private events;

  mapping(uint => address) eventCreatorIndex;
  mapping(uint => mapping(uint => uint[])) monthEventsIndex;

  function addEvent(string memory eventTitle, uint startTime, uint endTime, uint year, uint month) external {
    uint eventID = events.length;
    events.push(Event(eventID, msg.sender, eventTitle, startTime, endTime, false));
    monthEventsIndex[year][month].push(eventID);
    eventCreatorIndex[eventID] = msg.sender;
    emit AddEvent(msg.sender, eventID, eventTitle);
  }

  function getAllEvents() external view returns (Event[] memory) {
    Event[] memory tmp = new Event[](events.length);

    uint counter = 0;
    for(uint i=0; i<events.length; i++) {
      if(!events[i].isDeleted) {
        tmp[counter] = events[i];
        counter++;
      }
    }

    Event[] memory result = new Event[](counter);

    for(uint i=0; i<counter; i++) {
      result[i] = tmp[i];
    }
    return result;
  }

  function getMyEvents() external view returns (Event[] memory) {
    Event[] memory tmp = new Event[](events.length);

    uint counter = 0;
    for(uint i=0; i<events.length; i++) {
      if(eventCreatorIndex[i] == msg.sender && !events[i].isDeleted) {
        tmp[counter] = events[i];
        counter++;
      }
    }

    Event[] memory result = new Event[](counter);

    for(uint i=0; i<counter; i++) {
      result[i] = tmp[i];
    }
    return result;
  }

  function updateEvent(uint eventID, string memory eventTitle) external {
    if(eventCreatorIndex[eventID] == msg.sender) {
      events[eventID].title = eventTitle;
      emit UpdateEvent(msg.sender, eventID, eventTitle);
    }
  }

  function deleteEvent(uint eventID) external {
    if(eventCreatorIndex[eventID] == msg.sender) {
      events[eventID].isDeleted = true;
      emit DeleteEvent(msg.sender, eventID);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}