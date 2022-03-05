/**
 *Submitted for verification at FtmScan.com on 2022-03-05
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

interface IInitOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    
    function initOwner(address initialOwner) external;
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external; 
}

interface ISaleModel is IInitOwnable {
    event Initialised(uint256 indexed host, address indexed collection);
    event MetaUpdated(string indexed twitterPost, string indexed infoLink, string indexed preview);
    event Finalised();
    event ClaimedRaised(uint256 indexed amount);

    function setMeta(string memory twitterPost, string memory infoLink, string memory preview) external;
    function claimRaised() external;
}

interface ISaleFactory {

    //  Event
    // ----------------------------------------------------------------------
    event Initialised(IInitOwnable[] indexed saleModels, address indexed treasury, uint256 indexed baseFee, uint256 hostFee);
    event NewOwnerControl(bool indexed ownerControl);
    event SaleCreated(address indexed creator, address indexed clone, uint256 indexed saleId);
    event StatsUpdated(uint256 indexed totalRaised, uint256 indexed theaterFee, uint256 indexed hostFee);

    event ModelsAdded(IInitOwnable[] indexed saleModel);
    event ModelRemoved(uint256 indexed index);

    event HostAdded(address indexed creator, address indexed treasury);
    event HostChanged(uint256 indexed hostId, address indexed treasury);

    event NewTreasury(address indexed treasury);
    event NewBaseFeePerc(uint16 indexed baseFeePerc);
    event NewHostFeePerc(uint16 indexed hostFeePerc);

    //  Data Structures
    // ----------------------------------------------------------------------
    struct Host {
        address owner;
        address treasury;
    }

    struct Sale {
        // Sale model cloning.
        IInitOwnable modelUsed;
        // Clone sale contract the artist is using.
        IInitOwnable saleContract;
    }

    struct Model {
        IInitOwnable ref;
        uint256 totalCreated;
    }

    //  Views
    // ----------------------------------------------------------------------
    function initialised() external view returns(bool);
    function ownerControl() external view returns(bool);

    function treasury() external view returns(address);
    function baseFeePerc() external view returns(uint16);
    function hostFeePerc() external view returns(uint16);

    function host(uint256 id) external view returns (Host memory);
    function model(uint256 id) external view returns (Model memory);
    function sale(uint256 id) external view returns (Sale memory);
    
    function hostList() external view returns(Host[] memory);
    function modelList() external view returns (Model[] memory);
    function saleList() external view returns(Sale[] memory);

    function hostLength() external view returns(uint256);
    function modelLength() external view returns(uint256);
    function saleLength() external view returns(uint256);

    function hostByAddr(address addr) external view returns (bool success, uint256 id);
    
    //  Interaction
    // ----------------------------------------------------------------------
    function createSale(uint256 modelId) external returns (address result);
    function addHost(address treasury) external;
    function changeHostTreasury(uint256 hostId, address treasury) external;
}

// --------------------------------------------------------------------------------------
//
// (c) SaleFactory 03/02/2022 | SPDX-License-Identifier: AGPL-3.0-only
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

error NotInitialised();
error IsInitialised();
error IndexNotFound(uint256 input, uint256 max);
error NoUpdateAccess();
error TreasuryInUse();
error NotHostOwner(address caller, address owner);
error NotOwner(address input, address owner);

contract SaleFactory is ISaleFactory, Ownable, Pausable {
    
    /// @dev Whether contract has been initialised or not.
    bool public override initialised;
    /// @dev Whether `addHost()` can only be used by owner.
    bool public override ownerControl;

    /// @dev The address that receives the commission from a project's total raised.
    address public override treasury;
    /// @dev The % of the referral's commission % sent to the Theater Treasury.
    // -    e.g, 50,000 = 5% 
    uint16 public override baseFeePerc;
    /// @dev The % of the `baseFeePerc` to be split between Theater + a Host.
    // -    e.g, 5,000 = 50% 
    uint16 public override hostFeePerc;

    /// @dev List of protocols hosting a launchpad, allowing majority of profit for bringing users.
    /// -    e.g., A user deploys sale contract w/ SoulSwap's host referral.
    ///            SoulSwap get 90% cut, TheaterDAO gets 10%.
    /// -    Used to incentivise protocol integration.
    /// -    [0] == default (Theater's treasury address).
    Host[] private hosts;
    /// @dev All sale models available for cloning.
    Model[] private models;
    /// @dev All sales created.
    Sale[] private sales;

    /// @dev Must be initialised to use function.
    modifier onlyInit() {
        if (!initialised) revert NotInitialised();
        _;
    }

    //  Views
    // ----------------------------------------------------------------------
    
    function host(uint256 id) external view override returns (Host memory) {
        return hosts[id];
    }

    function model(uint256 id) external view override returns (Model memory) {
        return models[id];
    }

    function sale(uint256 id) external view override returns (Sale memory) {
        return sales[id];
    }

    function hostList() external view override returns (Host[] memory) {
        return hosts;
    }

    function modelList() external view override returns (Model[] memory) {
        return models;
    }

    function saleList() external view override returns (Sale[] memory) {
        return sales;
    }

    function hostLength() external view override returns (uint256) {
        return hosts.length;
    }

    function modelLength() external view override returns (uint256) {
        return models.length;
    }

    function saleLength() external view override returns (uint256) {
        return sales.length;
    }

    function hostByAddr(address addr) public view override returns (bool success, uint256 id) {
        Host[] memory mHosts = hosts;
        for (uint256 i; i < mHosts.length; i++) {
            if (mHosts[i].treasury == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    //  Sale Creation
    // ----------------------------------------------------------------------

    /// @dev Clone model `modelId`.
    function createSale(uint256 modelId)
        external
        override
        onlyInit
        whenNotPaused
        returns (address result)
    {
        if (modelId > models.length - 1) revert IndexNotFound(modelId, models.length - 1);

        // Convert model to address
        address cloning = address(models[modelId].ref);
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

        // Converted address memory ref
        IInitOwnable saleClone = IInitOwnable(cloneContract);

        // Transfer sale contract ownership to caller
        saleClone.initOwner(msg.sender);

        sales.push(
            Sale({
                modelUsed: models[modelId].ref,
                saleContract: saleClone
            })
        );

        models[modelId].totalCreated++;

        emit SaleCreated(msg.sender, cloneContract, sales.length);

        return cloneContract;
    }

    /// @dev Adds a new host referral address to available hosts.
    /// @param _treasury Address to send funds to.
    function addHost(address _treasury) external override onlyInit {
        if (ownerControl) {
            address _owner = owner();
            if (msg.sender != _owner) revert NotOwner(msg.sender, _owner);
        }
        (bool success, ) = hostByAddr(_treasury);
        if (success) revert TreasuryInUse();
        hosts.push(Host({owner: msg.sender, treasury: _treasury}));
        emit HostAdded(msg.sender, _treasury);
    }

    /// @dev Change the treasury of a host ID.
    /// @param _hostId Host details to target.
    /// @param _treasury Address to send funds to.
    function changeHostTreasury(uint256 _hostId, address _treasury) external override onlyInit {
        Host memory mHost = hosts[_hostId];
        if (mHost.owner != msg.sender) revert NotHostOwner(msg.sender, mHost.owner);
        hosts[_hostId].treasury = _treasury;
        emit HostChanged(_hostId, _treasury);
    }

    function switchOwnerControl(bool _ownerControl) external onlyOwner {
        ownerControl = _ownerControl;
        emit NewOwnerControl(_ownerControl);
    }

    //  Owner
    // ----------------------------------------------------------------------

    /// @dev Deploys all initial models to be used.
    /// @param _models Addresses of the model contracts to reference.
    /// @param _treasury Address of the Theater treasury.
    /// @param _baseFeePerc Fee receiver (i.e, DAO).
    /// @param _hostFeePerc Fee % of total raised sent to fee receiver.
    function initFactory(
        IInitOwnable[] memory _models,
        address _treasury,
        uint16 _baseFeePerc,
        uint16 _hostFeePerc
    ) external onlyOwner {
        if (initialised) revert IsInitialised();

        for (uint256 i; i < _models.length; i++) {
            models.push(Model({ref: _models[i], totalCreated: 0}));
        }

        treasury = _treasury;
        baseFeePerc = _baseFeePerc;
        hostFeePerc = _hostFeePerc;

        // Add TheaterDao as default host.
        hosts.push(Host({owner: msg.sender, treasury: treasury}));

        initialised = true;

        emit Initialised(_models, _treasury, baseFeePerc, hostFeePerc);
    }

    /// @dev Deploy a new model to be used.
    /// @param ref Address of the sale contract being referenced.
    function addModel(IInitOwnable[] memory ref) external onlyInit onlyOwner {
        for (uint256 i; i < ref.length; i++) {
            models.push(Model({ref: ref[i], totalCreated: 0}));
        }
        emit ModelsAdded(ref);
    }

    /// @dev Removes sale model from being available to use.
    /// @param index Element to remove
    function removeModel(uint256 index) external onlyInit onlyOwner {
        if (index > models.length) revert IndexNotFound(index, models.length);
        models[index] = models[models.length - 1];
        models.pop();
        emit ModelRemoved(index);
    }

    /// @dev Assigns new commissioner to receive commissioned funds.
    function newTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit NewTreasury(_treasury);
    }

    /// @dev Assigns new base commission fee percentage.
    function newBaseFeePerc(uint16 _baseFeePerc) external onlyOwner {
        baseFeePerc = _baseFeePerc;
        emit NewBaseFeePerc(_baseFeePerc);
    }

    /// @dev Assigns new commission fee percentage of `baseFeePerc` for hosts.
    function newHostFeePerc(uint16 _hostFeePerc) external onlyOwner {
        hostFeePerc = _hostFeePerc;
        emit NewHostFeePerc(_hostFeePerc);
    }
}