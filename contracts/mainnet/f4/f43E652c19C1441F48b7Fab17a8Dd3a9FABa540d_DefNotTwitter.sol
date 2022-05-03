/***
 * ███████╗ ██████╗  ██████╗  ██████╗  ██████╗  ██████╗  ██████╗                           
 * ██╔════╝██╔═══██╗██╔═══██╗██╔═══██╗██╔═══██╗██╔═══██╗██╔═══██╗                          
 * ███████╗██║   ██║██║   ██║██║   ██║██║   ██║██║   ██║██║   ██║                          
 * ╚════██║██║   ██║██║   ██║██║   ██║██║   ██║██║   ██║██║   ██║                          
 * ███████║╚██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝                          
 * ╚══════╝ ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝                           
 *                                                                                         
 * ███╗   ██╗ ██████╗ ████████╗    ████████╗██╗    ██╗██╗████████╗████████╗███████╗██████╗ 
 * ████╗  ██║██╔═══██╗╚══██╔══╝    ╚══██╔══╝██║    ██║██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
 * ██╔██╗ ██║██║   ██║   ██║          ██║   ██║ █╗ ██║██║   ██║      ██║   █████╗  ██████╔╝
 * ██║╚██╗██║██║   ██║   ██║          ██║   ██║███╗██║██║   ██║      ██║   ██╔══╝  ██╔══██╗
 * ██║ ╚████║╚██████╔╝   ██║          ██║   ╚███╔███╔╝██║   ██║      ██║   ███████╗██║  ██║
 * ╚═╝  ╚═══╝ ╚═════╝    ╚═╝          ╚═╝    ╚══╝╚══╝ ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
 * @author: maxflowo2.eth
 * @purpose: FTM (chain ID 250) graffiti
 */

// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.0 <0.9.0;

import "./access/Player1.sol";
import "./access/Player2.sol";

contract DefNotTwitter is PlayerOne, PlayerTwo {
  string private baseOne;
  string private baseTwo;

  event NewMessageFromOne(string _new);
  event NewMessageFromTwo(string _new);

  function newMessageFromOne(string memory _pubInfo) external {
    baseOne = _pubInfo;
    emit NewMessageFromOne(baseOne);
  }

  function newMessageFromTwo(string memory _pubInfo) external {
    baseTwo = _pubInfo;
    emit NewMessageFromTwo(baseTwo);
  }

  function lastMessageFromOne() external view returns (string memory) {
    return baseOne;
  }

  function lastMessageFromTwo() external view returns (string memory) {
    return baseTwo;
  }
}

/***
 * This is a re-write of @openzeppelin/contracts/access/Ownable.sol
 * Rewritten by MaxFlowO2, Senior Player and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2
// Rewritten for pTwo modifier

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a Player) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the Player account will be the one that deploys the contract. This
 * can later be changed with {transferPlayer}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `pTwo`, which can be applied to your functions to restrict their use to
 * the Player.
 */
abstract contract PlayerTwo is Context {

    address private _Player;

    event PlayerTwoTransferred(address indexed previousPlayer, address indexed newPlayer);

    /**
     * @dev Initializes the contract setting the deployer as the initial Player.
     */
    constructor() {
        _transferPlayerTwo(_msgSender());
    }

    /**
     * @dev Returns the address of the current Player.
     */
    // Player() => 0xca4b208b
    function playerTwo() public view virtual returns (address) {
        return _Player;
    }

    /**
     * @dev Throws if called by any account other than the Player.
     */
    modifier pTwo() {
        require(playerTwo() == _msgSender(), "Player: caller is not the Player");
        _;
    }

    /**
     * @dev Leaves the contract without Player. It will not be possible to call
     * `pTwo` functions anymore. Can only be called by the current Player.
     *
     * NOTE: Renouncing Playership will leave the contract without an Player,
     * thereby removing any functionality that is only available to the Player.
     */
    // renouncePlayer() => 0xad6d9c17
    function renouncePlayerTwo() public virtual pTwo {
        _transferPlayerTwo(address(0));
    }

    /**
     * @dev Transfers Player of the contract to a new account (`newPlayer`).
     * Can only be called by the current Player.
     */
    // transferPlayer(address) => 0xb671f4ea
    function transferPlayerTwo(address newPlayer) public virtual pTwo {
        require(newPlayer != address(0), "Player: new Player is the zero address");
        _transferPlayerTwo(newPlayer);
    }

    /**
     * @dev Transfers Player of the contract to a new account (`newPlayer`).
     * Internal function without access restriction.
     */
    // _transferPlayer(address) => 0x82dd18b8
    function _transferPlayerTwo(address newPlayer) internal virtual {
        address oldPlayer = _Player;
        _Player = newPlayer;
        emit PlayerTwoTransferred(oldPlayer, newPlayer);
    }
}

/***
 * This is a re-write of @openzeppelin/contracts/access/Ownable.sol
 * Rewritten by MaxFlowO2, Senior Player and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2
// Rewritten for pOne modifier

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a Player) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the Player account will be the one that deploys the contract. This
 * can later be changed with {transferPlayer}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `pOne`, which can be applied to your functions to restrict their use to
 * the Player.
 */
abstract contract PlayerOne is Context {

    address private _Player;

    event PlayerOneTransferred(address indexed previousPlayer, address indexed newPlayer);

    /**
     * @dev Initializes the contract setting the deployer as the initial Player.
     */
    constructor() {
        _transferPlayerOne(_msgSender());
    }

    /**
     * @dev Returns the address of the current Player.
     */
    // Player() => 0xca4b208b
    function playerOne() public view virtual returns (address) {
        return _Player;
    }

    /**
     * @dev Throws if called by any account other than the Player.
     */
    modifier pOne() {
        require(playerOne() == _msgSender(), "Player: caller is not the Player");
        _;
    }

    /**
     * @dev Leaves the contract without Player. It will not be possible to call
     * `pOne` functions anymore. Can only be called by the current Player.
     *
     * NOTE: Renouncing Playership will leave the contract without an Player,
     * thereby removing any functionality that is only available to the Player.
     */
    // renouncePlayer() => 0xad6d9c17
    function renouncePlayerOne() public virtual pOne {
        _transferPlayerOne(address(0));
    }

    /**
     * @dev Transfers Player of the contract to a new account (`newPlayer`).
     * Can only be called by the current Player.
     */
    // transferPlayer(address) => 0xb671f4ea
    function transferPlayerOne(address newPlayer) public virtual pOne {
        require(newPlayer != address(0), "Player: new Player is the zero address");
        _transferPlayerOne(newPlayer);
    }

    /**
     * @dev Transfers Player of the contract to a new account (`newPlayer`).
     * Internal function without access restriction.
     */
    // _transferPlayerOne(address) => 0x82dd18b8
    function _transferPlayerOne(address newPlayer) internal virtual {
        address oldPlayer = _Player;
        _Player = newPlayer;
        emit PlayerOneTransferred(oldPlayer, newPlayer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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