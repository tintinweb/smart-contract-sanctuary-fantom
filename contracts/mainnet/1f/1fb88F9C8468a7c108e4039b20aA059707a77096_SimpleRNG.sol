/**
 *Submitted for verification at FtmScan.com on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File @openzeppelin/contracts/access/IOwnable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

interface IOwnable {
    function owner() external view returns (address);

    function pushOwnership(address newOwner) external;

    function pullOwnership() external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

// File @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;
    address private _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
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
     * @dev Sets up a push of the ownership of the contract to the specified
     * address which must subsequently pull the ownership to accept it.
     */
    function pushOwnership(address newOwner) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts the push of ownership of the contract. Must be called by
     * the new owner.
     */
    function pullOwnership() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/interfaces/ISimpleRNG.sol

interface ISimpleRNG {
    function getEntropy() external view returns (bytes32);

    function getRandom() external view returns (bytes32);

    function getRandom(uint256 seed) external view returns (bytes32);
}

// File contracts/SimpleRNG/SimpleRNG.sol

interface IFeed {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint8 answeredInRound
        );
}

contract SimpleRNG is ISimpleRNG, Ownable {
    address[] private feeds;

    function addFeed(address feed) public onlyOwner {
        (, int256 answer, , , ) = IFeed(feed).latestRoundData();
        require(answer != 0, "Invalid feed");
        feeds.push(feed);
    }

    function getEntropy() public view returns (bytes32) {
        bytes32[] memory tmp = new bytes32[](feeds.length);

        for (uint8 i = 0; i < feeds.length; i++) {
            try IFeed(feeds[i]).latestRoundData() returns (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint8 answeredInRound
            ) {
                tmp[i] = keccak256(
                    abi.encodePacked(
                        roundId,
                        answer,
                        startedAt,
                        updatedAt,
                        answeredInRound
                    )
                );
            } catch {
                tmp[i] = keccak256(
                    abi.encodePacked(type(int256).max, feeds[i])
                );
            }
        }

        return keccak256(abi.encodePacked(address(this), tmp));
    }

    function getRandom() public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    getEntropy(),
                    block.number,
                    block.timestamp,
                    msg.sender,
                    block.difficulty
                )
            );
    }

    function getRandom(uint256 seed) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    getEntropy(),
                    block.number,
                    block.timestamp,
                    msg.sender,
                    block.difficulty,
                    seed
                )
            );
    }
}