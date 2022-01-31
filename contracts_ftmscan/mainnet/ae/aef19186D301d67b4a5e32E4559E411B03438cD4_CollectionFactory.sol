/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

pragma solidity ^0.8.9;

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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IInitOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    
    function initOwner(address initialOwner) external;
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external; 
}

// --------------------------------------------------------------------------------------
//
// (c) CollectionFactory 13/01/2022 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract CollectionFactory is Ownable, Pausable {
    event Initiated(address[] indexed models);
    event ModelAdded(address indexed ref);
    event ModelRemoved(uint256 indexed ref);
    event CollectionCreated(address indexed clone, address indexed creator);

    struct Model {
        // Contract reference used to clone.
        address ref;
        // Amount of clones created of `ref`.
        uint256 totalCreated;
    }

    // Whether contract has initialised or not.
    bool public initialised;

    // Amount of collections created.
    uint256 public totalCreated;
    // ID => contract address
    mapping(uint256 => address) public created;

    // All available models for use.
    Model[] public models;

    /**
        @dev Must be initialised to use function.
     */
    modifier onlyInit() {
        require(initialised, "not initialised");
        _;
    }


    //  Owner
    // ----------------------------------------------------------------------
    
    function modelsLength() external view returns(uint256) {
        return models.length;
    }

    function modelsList() external view returns(Model[] memory) {
        return models;
    }


    //  Owner
    // ----------------------------------------------------------------------

    /**
        @dev Deploys all initial models to be used.
        @param _models          Addresses of the model contracts to reference.
     */
    function initFactory(address[] memory _models) external onlyOwner {
        require(!initialised, "already initialised");

        for (uint256 i; i < _models.length; i++) {
            models.push(Model({ref: _models[i], totalCreated: 0}));
        }

        initialised = true;

        emit Initiated(_models);
    }

    /**
        @dev Deploy a new model to be used.
        @param ref    Address of the sale contract being referenced.
     */
    function addModel(address ref) external onlyInit onlyOwner {
        models.push(Model({ref: ref, totalCreated: 0}));
        emit ModelAdded(ref);
    }

    /**
        @dev Removes sale model from being available to use. 
        @param index    Element to remove
     */
    function removeModel(uint256 index) external onlyInit onlyOwner {
        require(index <= models.length, "index not found");
        models[index] = models[models.length - 1];
        models.pop();
        emit ModelRemoved(index);
    }

    //  Collection Creation
    // ----------------------------------------------------------------------

    function cloneModel(uint16 _model) external onlyInit whenNotPaused returns (address result) {
        require(models.length >= _model, "model not found");

        // Convert model to address
        address cloning = address(models[_model].ref);
        bytes20 targetBytes = bytes20(cloning);

        address cloneContract;

        // Clone model contract
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneContract := create(0, clone, 0x37)
        }

        // Transfer sale contract ownership to caller
        IInitOwnable(cloneContract).initOwner(msg.sender);

        // SSTORE sale details
        Model storage sModel = models[_model];
        sModel.totalCreated++;
        
        totalCreated++;

        emit CollectionCreated(cloneContract, msg.sender);

        return cloneContract;
    }
}