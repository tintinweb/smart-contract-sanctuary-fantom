/**
 *Submitted for verification at FtmScan.com on 2022-03-08
*/

pragma solidity ^0.8.9;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface ICollection {    
    function totalSupply() external view returns(uint256);
    function totalMinted() external view returns(uint256);
    function needMintAllowance() external view returns(bool);
    function approvedMinting(address minter) external view returns(uint256);
    function mint(address to, uint256 amount) external;
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
abstract contract InitOwnable is IInitOwnable {
    bool private _init;
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initOwner(address initialOwner) external override {
        require(!_init, "shoo");
        _init = true;
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// --------------------------------------------------------------------------------------
//
// (c) BuyoutBondingCurve 27/12/2021 | SPDX-License-Identifier: AGPL-3.0-only
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

error NotInitialised();
error IsInitialised();
error HostNotFound(uint256 input, uint256 total);
error ZeroStartPrice();
error TotalSupplyZero();
error TotalSupplyOverflow();
error MintingUnapproved();
error SaleFinalised();
error SaleHasntStarted(uint256 currentTime, uint256 startTime);
error SaleEnded(uint256 currentTime, uint256 endTime);
error NotWhitelisted();
error ZeroAmount();
error MintOverflow(uint256 minting, uint256 limitAfterMint, uint256 mintingLimit);
error ZeroClaimable();

contract BuyoutBondingCurve is ISaleModel, InitOwnable {

    event Buyout(address indexed buyer, uint256 indexed amount, uint256 bonusAmount, uint256 indexed cost);

    ISaleFactory public constant SALE_FACTORY = ISaleFactory(0xC0Ebb15a7cDc185B8641cbF426B107fdd98D594f);
    IERC20 public constant WETH = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    bool public initialised;
    
    struct Info {
        // Link to tweet that includes details of sale.
        // -    Used to let community know this isn't an imposter sale.
        // -    Tweet includes: deployer address + contract address since anyone can copy everything but these.
        string twitterPost;
        // Link to external link that has more information on the project.
        string infoLink;
        // Link to off-chain metadata (image/gif).
        // -    Used to display preview of collection being sold.
        string preview;

        // Whitelist merkle tree root
        // -    If no whitelist, merkle root == `0x0...`
        bytes32 merkleRoot;

        // Host ID assigned to this sale.
        uint256 host;
        // Theater commission percentage.
        uint16 baseFeePerc;
        // Host cut of commission percentage.
        uint16 hostFeePerc;

        // Whether sale has ended
        bool finalised;
        // Address that made the sale
        address creator;
        // Token contract to mint ids from
        // -    Must be able to give permission to this contract to mint
        ICollection collection;
        // Amount raised from sale
        uint256 raised;
        // Amount not claimed from raised
        uint256 unclaimed;
    }
    Info public info;

    struct Sale {
        // Each token sold increases `lastPrice` by this amount
        // -    i.e, 500 (500 / 10,000 = 0.05)
        uint256 multiplier;
        // Last sale price
        uint256 lastPrice;
        // Timestamp of when sale ends
        uint256 startTime;
        // Timestamp of when sale ends
        uint256 endTime;
        // Total ids to sell/mint
        uint256 totalSupply;
        // Total ids sold
        uint256 totalSold;
    }
    Sale public sale;

    struct BulkBonus {
        // Amount of NFTs being bought.
        uint256 buyingAmount;
        // Amount of NFTs given for free.
        uint256 freeAmount; 
    }
    // The more bought, the more given for free
    BulkBonus[] public bulkBonuses;

    /// @dev Must be initialised to use function.
    modifier onlyInit() {
        if (!initialised) revert NotInitialised();
        _;
    }
    
    //  Creation
    // ----------------------------------------------------------------------

    /// @dev Initiate the sale contract.
    /// @param _host Index of SALE_FACTORY's referrals that referred you.
    /// @param _collection NftCollection integrated NFT contract being sold.
    /// @param _startDelay Amount of seconds to add to block.timestamp to begin the sale.
    /// @param _duration Amount of seeconds the sale lasts for once it starts.
    /// @param _startPrice Price for the first token sold.
    /// @param _multiplier The % of the last price to increase per token sold.
    /// @param _totalSupply Amount of tokens being sold.
    /// @param _merkleRoot Optional: merkle root from tree of whitelisted addresses.
    /// @param _bulkBonuses Optional: the more bought, the more given for free.
    function init(
        uint256 _host,
        ICollection _collection,
        uint24 _startDelay,
        uint24 _duration,
        uint256 _startPrice,
        uint256 _multiplier,
        uint256 _totalSupply,
        bytes32 _merkleRoot,
        BulkBonus[] memory _bulkBonuses
    ) public onlyOwner {
        if (initialised) revert IsInitialised();
        if (_totalSupply < 1) revert TotalSupplyZero();
        if (_startPrice < 1) revert ZeroStartPrice();
        if (_collection.totalMinted() + _totalSupply > _collection.totalSupply()) revert TotalSupplyOverflow();
        if (_collection.approvedMinting(address(this)) < _totalSupply) revert MintingUnapproved();

        setFactoryLink(_host);

        info.collection = _collection;
        info.merkleRoot = _merkleRoot;
        info.creator = msg.sender;

        sale.lastPrice = _startPrice;
        sale.multiplier = _multiplier;
        sale.totalSupply = _totalSupply;
        
        uint256 startTime = block.timestamp + _startDelay;
        sale.startTime = startTime;
        sale.endTime = startTime + _duration;
        
        for (uint256 i; i < _bulkBonuses.length; i++) {
            bulkBonuses.push(_bulkBonuses[i]);
        }

        initialised = true;

        emit Initialised(_host, address(_collection));
    }

    /// @dev Set factory details.
    function setFactoryLink(uint256 _host) internal {
        if (_host > 0) {
            uint256 hostLength = SALE_FACTORY.hostLength() - 1;
            if (_host > hostLength) revert HostNotFound(_host, hostLength);
            info.hostFeePerc = SALE_FACTORY.baseFeePerc();
        }
        info.host = _host;
        info.baseFeePerc = SALE_FACTORY.baseFeePerc();
    }
    
    /// @dev Sets metadata used for verification.
    /// @param twitterPost Link to twitter post w/ this contract's address on it, verifying it's you.
    /// @param infoLink Link to a website that explains more about your project.
    /// @param preview Link to metadata image/gif, used as preview on FE (e.g., IPFS link).
    function setMeta(
        string memory twitterPost,
        string memory infoLink,
        string memory preview
    ) external override onlyOwner {
        info.twitterPost = twitterPost;
        info.infoLink = infoLink;
        info.preview = preview;

        Info memory mInfo = info;
        emit MetaUpdated(mInfo.twitterPost, infoLink, mInfo.preview);
    }

    //  Interaction
    // ----------------------------------------------------------------------

    /// @dev Creator receives unclaimed raised funds.
    function claimRaised() external override onlyInit {
        Info memory mInfo = info;
        if (mInfo.unclaimed < 1) revert ZeroClaimable();

        info.unclaimed = 0;
        uint256 commission = (mInfo.unclaimed * mInfo.baseFeePerc) / 10_000;

        if (commission > 0) {
            address theaterTreasury = SALE_FACTORY.treasury();
            if (mInfo.host > 0) {
                ISaleFactory.Host memory host = SALE_FACTORY.host(mInfo.host);
                uint256 cut = (commission * mInfo.hostFeePerc) / 10_000;
                WETH.transfer(host.treasury, cut);
                WETH.transfer(theaterTreasury, commission - cut);
            } else {
                WETH.transfer(theaterTreasury, commission);
            }
        }

        WETH.transfer(mInfo.creator, mInfo.unclaimed - commission);

        emit ClaimedRaised(mInfo.unclaimed);

        _finalise();
    }

    /// @dev Buyout current bundle.
    /// @param merkleProof Hashes used to reach the merkle root w/ address.
    /// @param amount Amount of ids to buy.
    function buyout(bytes32[] calldata merkleProof, uint256 amount) external onlyInit {
        Info memory mInfo = info;
        if (amount < 1) revert ZeroAmount();
        if (mInfo.finalised) revert SaleFinalised();
        if (!_isWhitelisted(merkleProof)) revert NotWhitelisted();

        Sale memory mSale = sale;        
        if (block.timestamp < mSale.startTime) revert SaleHasntStarted(block.timestamp, mSale.startTime);
        if (block.timestamp >= mSale.endTime) revert SaleEnded(block.timestamp, mSale.endTime);

        (uint256 cost, uint256 bonus, uint256 newPrice) = buyingResults(amount);
        uint256 tally = amount + bonus;
        uint256 newTotalSold = mSale.totalSold + tally;
        if (newTotalSold > mSale.totalSupply) revert MintOverflow(tally, newTotalSold, mSale.totalSupply);

        WETH.transferFrom(msg.sender, address(this), cost);

        sale.lastPrice = newPrice;
        info.raised += cost;
        info.unclaimed += cost;
        sale.totalSold += tally;

        mInfo.collection.mint(msg.sender, tally);

        emit Buyout(msg.sender, amount, bonus, cost);

        _finalise();
    }

    //  Internals
    // ----------------------------------------------------------------------

    /// @dev Finalises the sale if the requirements are met.
    function _finalise() internal {
        Sale memory mSale = sale;
        if (mSale.totalSold == mSale.totalSupply || block.timestamp >= mSale.endTime)  {
            Info memory mInfo = info;
            if (!mInfo.finalised) {
                info.finalised = true;
                emit Finalised();
            }
        }
    }

    /// @dev Checks if user is whitelisted for sale participation.
    /// @param _merkleProof Hashes used to reach the merkle root w/ address.
    function _isWhitelisted(bytes32[] calldata _merkleProof) internal view returns(bool) {
        bytes32 nullRoot;
        Info memory mInfo = info;
        // If no merkle root, no whitelist.
        if (mInfo.merkleRoot != nullRoot) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            return MerkleProof.verify(_merkleProof, mInfo.merkleRoot, leaf);
        } else return true;
    }

    //  Views
    // ----------------------------------------------------------------------

    /// @dev Calculates how many free NFTs are given based off the buying `amount`.
    /// @param amount Amount of ids to buy.
    function getBulkBonus(uint256 amount) public view returns(uint256) {
        BulkBonus[] memory mBB = bulkBonuses;
        uint256 bulkIndex;
        if (mBB.length > 0) {
            for (uint256 i; i < mBB.length; i++) {
                if (amount >= mBB[i].buyingAmount) {
                    bulkIndex = i;
                }
            }
            return mBB[bulkIndex].freeAmount;
        } else {
            return 0;
        }
    }

    /// @dev Calculates the total cost for the amount of nfts being bought.
    /// @param amount Amount of ids to buy.
    function buyingResults(uint256 amount) public view returns (uint256 cost, uint256 bonus, uint256 lastPrice) {
        Sale memory mSale = sale;

        uint256 adding;
        lastPrice = mSale.lastPrice;
        bonus = getBulkBonus(amount);

        // Calculate cost
        for (uint256 i; i < amount + bonus; i++) {
            // Amount being added onto last price.
            // E.g.,     ($100 * 500) / 1,000,000 = $0.05
            adding = (lastPrice * mSale.multiplier) / 1000000;
            // E.g.,     $100 + $0.05 = $100.05
            lastPrice += adding;

            if (i < amount) {
                // Add token price to cost
                cost += lastPrice;
            }
        } 
    }

    /// @dev Returns all stats to do w/ the sale.
    function getSaleDetails() external view returns (
        bool isInitialised, 
        Info memory, 
        Sale memory, 
        BulkBonus[] memory
    ) {
        return (
            initialised, 
            info, 
            sale, 
            bulkBonuses
        );
    }
}