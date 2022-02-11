/**
 *Submitted for verification at FtmScan.com on 2022-02-04
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

// --------------------------------------------------------------------------------------
//
// (c) ISaleModel 29/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleModel is IInitOwnable {
    event Initiated(address indexed collection, uint256 indexed startTime);
    event MetaUpdated(string indexed twitterPost, string indexed infoLink, string indexed preview);
    event Finalised();
    event ClaimedRaised(uint256 indexed amount);

    function setMeta(string memory twitterPost, string memory infoLink, string memory preview) external;
    function claimRaised() external;
}

// --------------------------------------------------------------------------------------
//
// (c) ISaleFactory 28/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleFactory {

    //  Event
    // ----------------------------------------------------------------------

    event Initiated(ISaleModel[] indexed saleModels, address indexed treasury, uint256 indexed treasuryCut, uint256 commission);
    event SaleCreated(address indexed creator, ISaleModel indexed saleModel);

    event ModelAdded(ISaleModel indexed saleModel);
    event ModelRemoved(uint256 indexed index);

    event HostAdded(address indexed creator, address indexed treasury, uint256 indexed commissionPerc);
    event HostChanged(uint256 indexed hostId, address indexed treasury, uint256 indexed commissionPerc);

    event NewTreasury(address indexed treasury);
    event NewTreasuryPerc(uint256 indexed treasuryPerc);

    //  Data Structures
    // ----------------------------------------------------------------------

    struct Model {
        ISaleModel ref;
        uint256 totalCreated;
    }

    struct Host {
        address owner;
        address treasury;
        uint256 commissionPerc;
    }

     struct Sale {
        // Sale model cloning.
        ISaleModel modelUsed;
        // Clone sale contract the artist is using.
        ISaleModel saleContract;
    }

    //  Views
    // ----------------------------------------------------------------------

    function TREASURY() external view returns(address);
    function TREASURY_CUT() external view returns(uint256);

    function host(uint256 id) external view returns (Host memory);
    function hostList() external view returns(Host[] memory);
    function hostLength() external view returns(uint256);

    function sale(uint256 id) external view returns (Sale memory);
    function saleList() external view returns(Sale[] memory);
    function saleLength() external view returns(uint256);

    function model(uint256 id) external view returns (Model memory);
    function modelList() external view returns (Model[] memory);
    function modelLength() external view returns(uint256);

    
    //  Interaction
    // ----------------------------------------------------------------------

    function createSale(uint256 modelId) external returns (address result);
    function addHost(address treasury, uint256 soldPerc) external;
    function adjustHost(uint256 hostId, address treasury, uint256 soldPerc) external;
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
// (c) BuyoutFixed 03/02/2022 | SPDX-License-Identifier: AGPL-3.0-only
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract BuyoutFixed is ISaleModel, InitOwnable {
    
    event Buyout(address indexed buyer, uint256 indexed amount, uint256 bonusAmount, uint256 indexed cost);

    ISaleFactory constant public SALE_FACTORY = ISaleFactory(0x155821427d5e6BEac8c1dCa5A3e940f73B5fed0B);
    IERC20 constant public WETH = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

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

        // Whitelist merkle tree root.
        // -    If no whitelist, merkle root == `0x0...`.
        bytes32 merkleRoot;

        // Host commission percentage.
        uint256 hostCommissionPerc;
        // Host ID assigned to this sale.
        uint8 host;

        // Whether sale has ended.
        bool finalised;
        // Whether contract has given mint access or not.
        bool mintAccess;
        // Address that made the sale.
        address creator;
        // Token contract to mint ids from.
        // -    Must be able to give permission to this contract to mint.
        ICollection collection;
        // Amount raised from sale.
        uint256 raised;
        // Amount not claimed from raised.
        uint256 unclaimed;
    }
    Info private _info;

    struct Sale {
        // Price per token.
        uint256 price;
        // Timestamp of when sale ends.
        uint256 startTime;
        // Timestamp of when sale ends.
        uint256 endTime;
        // Total ids to sell/mint.
        uint256 totalSupply;
        // Total ids sold.
        uint256 totalSold;
    }
    Sale private _sale;

    struct BulkBonus {
        // Amount of NFTs being bought.
        uint256 buyingAmount;
        // Amount of NFTs given for free.
        uint256 freeAmount;
    }
    // The more bought, the more given for free.
    BulkBonus[] private _bulkBonuses;

    bool private initialised;

    /// @dev Must be initialised to use function.
    modifier onlyInit() {
        require(initialised, "NOT_INITIALISED");
        _;
    }  

    //  Owner
    // ----------------------------------------------------------------------

    /// @dev Initiate the sale contract.
    /// @param _host                Index of SALE_FACTORY's referrals that referred you.
    /// @param _collection          NftCollection integrated NFT contract being sold.
    /// @param _startDelay          Amount of seconds to add to block.timestamp to begin the sale.
    /// @param _duration            Amount of seconds each internal auction lasts for.
    /// @param _price               Price per token.
    /// @param _totalSupply         Amount of tokens being sold.
    /// @param _merkleRoot          Optional: merkle root from tree of whitelisted addresses.
    /// @param _bonuses             Optional: bulk incentives.
    function init(
        uint8 _host,
        ICollection _collection,
        uint24 _startDelay,
        uint24 _duration,
        uint256 _price,
        uint256 _totalSupply,
        bytes32 _merkleRoot,
        BulkBonus[] memory _bonuses
    ) public onlyOwner {
        require(!initialised, "ALREADY_INITIALISED");
        if (_host > 0) {
            require(_host <= SALE_FACTORY.hostLength(), "REFERRAL_NOT_FOUND");
        }
        require(_collection.totalMinted() + _totalSupply <= _collection.totalSupply(), "EXCEEDS_TOTAL_SUPPLY");
        require(_collection.approvedMinting(address(this)) >= _totalSupply, "UNDERFLOW_MINT_ALLOWANCE");

        initialised = true;

        ISaleFactory.Host memory host = SALE_FACTORY.host(_host);
        _info.host = _host;
        _info.hostCommissionPerc = host.commissionPerc;

        _info.collection = _collection;
        _info.merkleRoot = _merkleRoot;
        _info.creator = msg.sender;
        _info.mintAccess = true;

        _sale.startTime = block.timestamp + _startDelay;
        _sale.endTime = block.timestamp + _startDelay + _duration;

        _sale.price = _price;
        _sale.totalSupply = _totalSupply;

        if (_bonuses.length > 0) {
            for (uint256 i; i < _bonuses.length; i++) {
                _bulkBonuses.push(_bonuses[i]);
            }
        }

        emit Initiated(address(_collection), block.timestamp);
    }

    /// @dev Sets metadata used for verification.
    /// @param twitterPost          Link to twitter post w/ this contract's address on it, verifying it's you.
    /// @param infoLink             Link to a website that explains more about your project.
    /// @param preview              Link to metadata image/gif, used as preview on FE (e.g., IPFS link).
    function setMeta(
        string memory twitterPost,
        string memory infoLink,
        string memory preview
    ) external override onlyOwner {
        _info.twitterPost = twitterPost;
        _info.infoLink = infoLink;
        _info.preview = preview;

        Info memory mInfo = _info;
        emit MetaUpdated(mInfo.twitterPost, infoLink, mInfo.preview);
    }

    //  Interaction
    // ----------------------------------------------------------------------

    /// @dev Creator receives unclaimed raised funds.
    function claimRaised() external override onlyInit {
        Info memory mInfo = _info;
        require(mInfo.unclaimed > 0, "ZERO_UNCLAIMED");

        ISaleFactory.Host memory host = SALE_FACTORY.host(mInfo.host);

        // Calculate commission amount.
        uint256 commission = (mInfo.unclaimed * host.commissionPerc) / 10000;

        // Reset unclaimed.
        _info.unclaimed = 0;
        
        // If referral isn't factory creator, calculate referral cut.
        if (commission > 0) {
            address theaterTreasury = SALE_FACTORY.TREASURY();

            if (host.treasury != theaterTreasury) {
                uint256 theaterCut = SALE_FACTORY.TREASURY_CUT();
                uint256 cut = (commission * theaterCut) / 10000;
                
                WETH.transfer(host.treasury, commission - cut);
                WETH.transfer(theaterTreasury, cut);
            } else {
                // otherwise, give total commission to factory creator.
                WETH.transfer(host.treasury, commission);
            }
        }

        // Transfer raised (minus commission) to sale creator.
        WETH.transfer(mInfo.creator, mInfo.unclaimed - commission);

        emit ClaimedRaised(mInfo.unclaimed);

        // Check if sale has finalised.
        _finalise();
    }

    /// @dev Buyout current bundle.
    /// @param merkleProof  Hashes used to reach the merkle root w/ address.
    /// @param amount       Amount of ids to buy.
    function buyout(bytes32[] calldata merkleProof, uint256 amount)
        external
        onlyInit
    {
        Info memory mInfo = _info;
        require(amount > 0, "ZERO_AMOUNT");
        require(!mInfo.finalised, "SALE_FINALISED");

        // Check if the user is whitelisted.
        require(_isWhitelisted(merkleProof), "NOT_WHITELISTED");

        Sale memory mSale = _sale;
        
        // Check if sale has started or ended.
        require(block.timestamp >= mSale.startTime, "AWAITING_SALE_START");
        require(block.timestamp < mSale.endTime, "SALE_ENDED");

        // Gets how many bonus NFTs are given.
        uint256 bonus = getBulkBonus(amount);
        uint256 tally = amount + bonus;

        // Checks total amount being minted doesnt exceed totalSupply.
        uint256 newTotalSold = mSale.totalSold + tally;
        require(newTotalSold <= mSale.totalSupply, "OVERFLOW_AMOUNT");

        uint256 cost = mSale.price * amount;

        // Send payment + update stats.
        WETH.transferFrom(msg.sender, address(this), cost);

        _info.raised += cost;
        _info.unclaimed += cost;
        _sale.totalSold += tally;

        // Mint bought token(s)
        mInfo.collection.mint(msg.sender, tally);

        emit Buyout(msg.sender, amount, bonus, cost);

        // Finalise if sold out OR current time > endTime
        _finalise();
    }

    //  Internals
    // ----------------------------------------------------------------------

    /// @dev Finalises the sale if the requirements are met.
    function _finalise() internal {
        Sale memory mSale = _sale;
        // If sold out OR current time has passed endTime.
        if (mSale.totalSold == mSale.totalSupply || block.timestamp >= mSale.endTime)  {
            Info memory mInfo = _info;
            if (!mInfo.finalised) {
                _info.finalised = true;
                emit Finalised();
            }
        }
    }

    /// @dev Checks if user is whitelisted for sale participation.
    /// @param _merkleProof     Hashes used to reach the merkle root w/ address.
    function _isWhitelisted(bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        Info memory mInfo = _info;
        bytes32 nullBytes;
        // If no merkle root, no whitelist.
        if (mInfo.merkleRoot != nullBytes) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            return MerkleProof.verify(_merkleProof, mInfo.merkleRoot, leaf);
        } else return true;
    }

    //  Views
    // ----------------------------------------------------------------------

    /// @dev Calculates how many free NFTs are given based off the buying `amount`.
    /// @param amount     Amount of ids to buy.
    function getBulkBonus(uint256 amount) public view returns (uint256) {
        BulkBonus[] memory mBB = _bulkBonuses;
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

    /// @dev Returns all stats to do w/ the sale.
    function getSaleDetails() external view returns (bool isInitialised, Info memory info, Sale memory sale, BulkBonus[] memory) {
        return (initialised, _info, _sale, _bulkBonuses);
    }
}