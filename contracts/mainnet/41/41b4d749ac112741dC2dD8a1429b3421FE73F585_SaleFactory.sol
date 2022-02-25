/**
 *Submitted for verification at FtmScan.com on 2022-02-25
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
    event Initialised(uint256 indexed host, address indexed collection, uint256 indexed startTime);
    event MetaUpdated(string indexed twitterPost, string indexed infoLink, string indexed preview);
    event Finalised();
    event ClaimedRaised(uint256 indexed amount);

    function setMeta(string memory twitterPost, string memory infoLink, string memory preview) external;
    function claimRaised() external;
}

interface ISaleFactory {

    //  Event
    // ----------------------------------------------------------------------

    event Initialised(IInitOwnable[] indexed saleModels, address indexed treasury, uint256 indexed treasuryCut, uint256 commission);
    event SaleCreated(address indexed creator, address indexed clone, uint256 indexed saleId);

    event ModelAdded(IInitOwnable indexed saleModel);
    event ModelRemoved(uint256 indexed index);

    event HostAdded(address indexed creator, address indexed treasury, uint256 indexed commissionPerc);
    event HostChanged(uint256 indexed hostId, address indexed treasury, uint256 indexed commissionPerc);

    event NewTreasury(address indexed treasury);
    event NewTreasuryPerc(uint256 indexed treasuryPerc);

    //  Data Structures
    // ----------------------------------------------------------------------

    struct Host {
        address owner;
        address treasury;
        uint256 commissionPerc;
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

    function TREASURY() external view returns(address);
    function TREASURY_CUT() external view returns(uint256);

    function host(uint256 id) external view returns (Host memory);
    function host(address addr) external view returns (bool success, uint256 id);
    function hostList() external view returns(Host[] memory);
    function hostLength() external view returns(uint256);

    function sale(uint256 id) external view returns (Sale memory);
    function saleList() external view returns(Sale[] memory);
    function saleLength() external view returns(uint256);

    function model(uint256 id) external view returns (Model memory);
    function modelList() external view returns (Model[] memory);
    function modelLength() external view returns(uint256);

    function userSaleIds(address user) external view returns (uint256[] memory);
    function saleByAddress(IInitOwnable saleAddress) external view returns (bool success, uint256 id);
    function saleListByIds(uint256[] memory ids) external view returns (Sale[] memory);

    
    //  Interaction
    // ----------------------------------------------------------------------

    function createSale(uint256 modelId) external returns (address result);
    function addHost(address treasury, uint256 soldPerc) external;
    function adjustHost(uint256 hostId, address treasury, uint256 soldPerc) external;
}

// --------------------------------------------------------------------------------------
//
// (c) SaleFactory 03/02/2022 | SPDX-License-Identifier: AGPL-3.0-only
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract SaleFactory is ISaleFactory, Ownable, Pausable {

    /// @dev The address that receives the commission from a project's total raised.
    address public override TREASURY;

    /// @dev The % of the referral's commission % sent to the Theater Treasury.
    uint256 public override TREASURY_CUT;

    /// @dev List of protocols hosting a launchpad, allowing majority of profit for bringing users.
    /// -    e.g., A user deploys sale contract w/ SoulSwap's host referral.
    ///            SoulSwap get 90% cut, TheaterDAO gets 10%.
    /// -    Used to incentivise protocol integration.
    /// -    [0] == default (Theater's treasury address).
    Host[] private _hosts;
    mapping(address => uint256) private _host; 

    /// @dev All sales created.
    Sale[] private _sales;

    /// @dev All sale models available for cloning.
    Model[] private _models;

    /// @dev All sale ids created by user.
    mapping(address => uint256[]) private _userSaleIds;

    /// @dev Whether contract has been initialised or not.
    bool private initialised;

    /// @dev Must be initialised to use function.
    modifier onlyInit() {
        require(initialised, "NOT_INITIALISED");
        _;
    }

    //  Views
    // ----------------------------------------------------------------------

    function host(uint256 id) external view override returns (Host memory) {
        return _hosts[id];
    }

    function host(address addr) public view override returns (bool success, uint256 id) {
        Host[] memory mHosts = _hosts;
        for (uint256 i; i < mHosts.length; i++) {
            if (mHosts[i].treasury == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function hostList() external view override returns (Host[] memory) {
        return _hosts;
    }

    function hostLength() external view override returns (uint256) {
        return _hosts.length;
    }

    function sale(uint256 id) external view override returns (Sale memory) {
        return _sales[id];
    }

    function saleList() external view override returns(Sale[] memory) {
        return _sales;
    }

    function saleLength() external view override returns(uint256) {
        return _sales.length;
    }

    function model(uint256 id) external view override returns (Model memory) {
        return _models[id];
    }

    function modelList() external view override returns (Model[] memory) {
        return _models;
    }

    function modelLength() external view override returns (uint256) {
        return _models.length;
    }

    function userSaleIds(address user) external view override returns (uint256[] memory) {
        return _userSaleIds[user];
    }

    function saleByAddress(IInitOwnable saleAddress) external view override returns (bool success, uint256 id) {
        Sale[] memory sales = _sales;
        for (uint256 i; i < sales.length; i++) {
            if (saleAddress == sales[i].saleContract) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function saleListByIds(uint256[] memory ids) external view override returns (Sale[] memory) {
        Sale[] memory sales = _sales;
        Sale[] memory result = new Sale[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            result[i] = sales[ids[i]];
        }
        return result;
    }

    //  Owner
    // ----------------------------------------------------------------------

    /// @dev Deploys all initial models to be used.
    /// @param models           Addresses of the model contracts to reference.
    /// @param treasury         Fee receiver (i.e, DAO).
    /// @param treasuryCut      Fee % of total raised sent to fee receiver.
    function initFactory(
        IInitOwnable[] memory models,
        address treasury,
        uint256 treasuryCut,
        uint256 commission
    ) external onlyOwner {
        require(!initialised, "ALREADY_INITIALISED");

        for (uint256 i; i < models.length; i++) {
            _models.push(Model({ref: models[i], totalCreated: 0}));
        }

        TREASURY = treasury;
        TREASURY_CUT = treasuryCut;

        // Add TheaterDao as default host.
        _hosts.push(
            Host({
                owner: msg.sender,
                treasury: treasury,
                commissionPerc: commission
            })
        );

        initialised = true;

        emit Initialised(models, treasury, treasuryCut, commission);
    }

    /// @dev Deploy a new model to be used.
    /// @param ref    Address of the sale contract being referenced.
    function addModel(IInitOwnable ref) external onlyInit onlyOwner {
        _models.push(Model({ref: ref, totalCreated: 0}));
        emit ModelAdded(ref);
    }

    /// @dev Removes sale model from being available to use. 
    /// @param index    Element to remove
    function removeModel(uint256 index) external onlyInit onlyOwner {
        require(index < _models.length, "INDEX_NOT_FOUND");
        _models[index] = _models[_models.length - 1];
        _models.pop();
        emit ModelRemoved(index);
    }

    /// @dev Assigns new commissioner to receive commissioned funds.
    function newTreasury(address _treasury) external onlyOwner {
        TREASURY = _treasury;
        emit NewTreasury(_treasury);
    }

    /// @dev Assigns new commission percentage to all new deployed sale contracts.
    function newCommissionPerc(uint256 _treasuryCut) external onlyOwner {
        TREASURY_CUT = _treasuryCut;
        emit NewTreasuryPerc(_treasuryCut);
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
        require(modelId <= _models.length - 1, "MODEL_NOT_FOUND");

        // Convert model to address
        address cloning = address(_models[modelId].ref);
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

        _sales.push(
            Sale({
                modelUsed: _models[modelId].ref,
                saleContract: saleClone
            })
        );

        _models[modelId].totalCreated++;

        emit SaleCreated(msg.sender, cloneContract, _sales.length);

        return cloneContract;
    }

    /// @dev Adds a new host referral address to available hosts. 
    /// @param treasury           Address to send funds to.
    /// @param commissionPerc     Percentage of sale raised funds to referrer.
    function addHost(address treasury, uint256 commissionPerc)
        external
        override
        onlyInit
    {
        (bool success, ) = host(treasury);
        require(!success, "ACTIVE_TREASURY");
        require(commissionPerc <= 10000, "REACHED_MAX_COMMISSION_PERC");

        _hosts.push(
            Host({
                owner: msg.sender,
                treasury: treasury,
                commissionPerc: commissionPerc
            })
        );

        emit HostAdded(msg.sender, treasury, commissionPerc);
    }

    /// @dev Change the details of a host ID.
    /// @param hostId             Host details to target.
    /// @param treasury           Address to send funds to.
    /// @param commissionPerc     Percentage of sale raised funds to referrer.
    function adjustHost(
        uint256 hostId,
        address treasury,
        uint256 commissionPerc
    ) external override onlyInit {
        require(commissionPerc <= 10000, "REACHED_MAX_COMMISSION_PERC");
        Host memory mHost = _hosts[hostId];
        require(mHost.owner == msg.sender, "NOT_HOST_OWNER");

        _hosts[hostId].treasury = treasury;
        _hosts[hostId].commissionPerc = commissionPerc;

        emit HostChanged(hostId, treasury, commissionPerc);
    }
}