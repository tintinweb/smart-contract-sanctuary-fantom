/**
 *Submitted for verification at FtmScan.com on 2022-05-23
*/

// File: contracts\ContextMixin.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\access\Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts\MetaFoxesBase.sol

pragma solidity ^0.8.0;
/// @title Base contract for MetaFoxes. Holds all common structs, events and base variables.
contract MetaFoxesBase is Ownable {

    address public metaFoxesProxyAddress;
	string public metaUrl = "https://metafoxes.io/metadata/";
	
	////////////////////////////////
    // EVENTS  
    ////////////////////////////////

	/// @dev The Birth event is triggered whenever a new fox is created. This obviously includes
	/// any time a fox is created using the giveBirth method, but it is also called
	///	when a new gen0 fox is created.
    event Birth(address owner, uint256 foxId, uint256 motherId, uint256 fatherId, uint256 genes);

	////////////////////////////////
    // DATA TYPES  
    ////////////////////////////////

    /// @dev The main Fox struct. Every fox in MetaFoxes is represented by a copy
    ///  of this structure.
    struct Fox {
        // The Fox's genetic code is packed into these 256-bits, the format is
        // sooper-sekret! A fox's genes never change.
        uint256 genes;

        // The timestamp from the block when this fox came into existence.
        uint64 birthTime;

		// The minimum amount of time after which this fox can breed again. The same amount of time is used for the pregnancy timer (for the mother)
		// and also for the cooldown for the father.
        uint64 cooldownEndBlock;

        // The ID of the parents of this Fox, set to 0 for gen0 foxes.
        uint32 motherId;
        uint32 fatherId;

		// Set the fox's sire ID for the pregnant mother, otherwise zero. 
		// A non-zero value is how we know the fox is pregnant. 
		// Used to obtain genetic material for new foxes when it is time for them to be born.
		uint32 breedingWithId;

		// Set to an index in the cooldown array (see below) that represents
		// the current chill duration for this Fox. It starts at zero for generation 0 foxes
		// and is initialized to floor (generation / 2) for the rest. Increases by one for 
		// each successful breeding action regardless of whether this fox acts as a mother or a father.
        uint16 cooldownIndex;

		// The "generation number" of this fox. Foxes minted by the CK contract
		// are called "gen0" and have a generation number of 0. The generation number
		// of all other foxes is the greater of the two generation numbers of their parents plus one.
        // (i.e. max(mother.generation, father.generation) + 1)
        uint16 generation;
    }

	////////////////////////////////
    // CONSTANTS  
    ////////////////////////////////

	/// @dev An array with the recovery time after any successful breeding action, called "pregnancy time" 
	/// for the mother and "cooldown time" for the father. Designed so that the recovery time roughly doubles
	/// each time a fox is bred, which encourages owners not to breed the same fox over and over again.
	/// The maximum number of times is one week (a fox can breed an unlimited number of times
	/// and the maximum recovery time is always seven days).
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];
	
	// An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 1;

	////////////////////////////////
    // STORAGE  
    ////////////////////////////////

    /// @dev An array containing the Fox struct for all Foxes in existence. The ID
    ///  of each fox is actually an index into this array.
    Fox[] foxes;

	/// @dev A mapping from FoxIDs to an address that has been approved for this Fox 
	/// to use to create progeny through breedWith(). Each Fox can only have one approved
	/// paternity address at any one time. A value of zero means there is no approval.
    mapping (uint256 => address) public breedingAllowedToAddress;
	
	////////////////////////////////
    // PRIVATE FUNCTIONS    
    ////////////////////////////////

    /// @dev An internal method that creates a new Fox and stores it. 
	/// This method does not perform any checks and should only be called
	/// when the input data is known to be valid. But since it's an expensive call (for storage),
	/// we should make sure that our data structures are always valid.
	/// Both a birth event and a transfer event will be generated.
    /// @param _motherId The Fox ID of the mother of this fox (zero for gen0)
    /// @param _fatherId The Fox ID of the father of this fox (zero for gen0)
    /// @param _generation The generation number of this fox, must be computed by caller.
    /// @param _genes The Fox's genetic code.
    /// @param _owner The inital owner of this fox, must be non-zero (except for the unFox, ID 0)
    function _createFox(
        uint256 _motherId,
        uint256 _fatherId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_motherId == uint256(uint32(_motherId)), "MetaFoxes: Mother id is too big");
        require(_fatherId == uint256(uint32(_fatherId)), "MetaFoxes: Father id is too big");
        require(_generation == uint256(uint16(_generation)), "MetaFoxes: Generation id is too big");

        // New Fox starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Fox memory _fox = Fox({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            cooldownEndBlock: 0,
            motherId: uint32(_motherId),
            fatherId: uint32(_fatherId),
            breedingWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });
		foxes.push(_fox);
        uint256 newFoxId = foxes.length - 1;

        // It's worth making sure there is no overflow
        require(newFoxId == uint256(uint32(newFoxId)), "MetaFoxes: NewFoxId id is too big");

        // emit the birth event
        emit Birth(
            _owner,
            newFoxId,
            uint256(_fox.motherId),
            uint256(_fox.fatherId),
            _fox.genes
        );

        return newFoxId;
    }
	
	////////////////////////////////
    // ADMIN FUNCTIONS    
    ////////////////////////////////
	
	// Set how many seconds per blocks are currently observed.
	function setSecondsPerBlock(uint256 secs) external onlyOwner {
        require(secs < cooldowns[0], "MetaFoxes: Cooldown must be less than 1 minute");
        secondsPerBlock = secs;
    }

}

// File: contracts\MetaFoxesGeneticLabInterface.sol

pragma solidity ^0.8.0;

interface MetaFoxesGeneticLabInterface {

	/// @dev A boolean to indicate this is the contract we expect to be
    function isFoxGeneticLab() external view returns (bool);

    /// @dev given genes of fox 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mother
    /// @param genes2 genes of father
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint genes1, uint genes2, uint targetBlock) external returns (uint);
	
	/// @return A random combination of genes to be assigned to a new parentless fox.
	function getRandomGenes(uint seed) external returns (uint);

}

// File: contracts\MetaFoxesBreeder.sol

pragma solidity ^0.8.0;
contract MetaFoxesBreeder is MetaFoxesBase {

	////////////////////////////////
    // EVENTS  
    ////////////////////////////////
	
	/// @dev The Pregnant event is fired when two foxes successfully breed and the pregnancy
    ///  timer begins for the mother.
    event Pregnant(address owner, uint256 motherId, uint256 fatherId, uint256 cooldownEndBlock);
	
	////////////////////////////////
    // FIELDS  
    ////////////////////////////////
    
    // Keeps track of number of pregnant foxes.
    uint256 public pregnantFoxes;
	
	/// @dev The address of the sibling contract that is used to implement the
    /// genetic algorithm.
    MetaFoxesGeneticLabInterface public geneticLab;
    
    ////////////////////////////////
    // PUBLIC FUNCTIONS    
    ////////////////////////////////

	
	/// @notice Checks that a fox is able to breed (i.e. it is not pregnant or
    ///  in the middle of a breeding cooldown).
    /// @param _foxId reference the id of the fox, any user can inquire about it
    function isReadyToBreed(uint256 _foxId) public view returns (bool)
    {
        require(_foxId > 0, "MetaFoxes: Fox id must be bigger than zero");
        Fox storage fox = foxes[_foxId];
        return _isReadyToBreed(fox);
    }
	
	/// @dev Checks whether a fox is currently pregnant.
    /// @param _foxId reference the id of the fox, any user can inquire about it
    function isPregnant(uint256 _foxId) public view returns (bool) {
        require(_foxId > 0, "MetaFoxes: Fox id must be bigger than zero");
        return foxes[_foxId].breedingWithId != 0;
    }

    
    ////////////////////////////////
    // ADMIN FUNCTIONS    
    ////////////////////////////////
    
    function setAllowedProxyAddress(address _address) public onlyOwner {
        metaFoxesProxyAddress = _address;
    }
	
	function setMetaUrl(string memory _url) public onlyOwner {
        metaUrl = _url;
    }
	
	/// @dev Update the address of the genetic contract, can only be called by the owner.
    /// @param _address An address of a FoxGeneticLab contract instance to be used from this point forward.
    function setFoxGeneticLabAddress(address _address) external onlyOwner {
        MetaFoxesGeneticLabInterface tmpContract = MetaFoxesGeneticLabInterface(_address);

        //verify that a contract is what we expect
        require(tmpContract.isFoxGeneticLab(), "MetaFoxes: It's possible to set only genetic lab here.");

        // Set the new contract address
        geneticLab = tmpContract;
    }
    
    ////////////////////////////////
    // PRIVATE FUNCTIONS    
    ////////////////////////////////
	
    /// @dev Checks that a given fox is able to breed. Requires that the
    ///  current cooldown is finished (for father) and also checks that there is
    ///  no pending pregnancy.
    function _isReadyToBreed(Fox memory _fox) internal view returns (bool) {
        return (_fox.breedingWithId == 0) && (_fox.cooldownEndBlock <= uint64(block.number));
    }

    /// @dev Check if a father has authorized breeding with this mother. True if both have the same owner,
	/// or if the father has given breeding permission to the mother's owner (via approveBreeding()).
    function _isBreedingPermitted(address _motherOwner, uint256 _fatherId, address _fatherOwner) internal view returns (bool) {
        // Breeding is possible if they have same owner, or if the mother's owner was given
        // permission to breed with this father.
        return (_motherOwner == _fatherOwner || breedingAllowedToAddress[_fatherId] == _motherOwner);
    }

    /// @dev Set the cooldownEndTime for the given fox, based on its current cooldownIndex.
    ///  Also increments the cooldownIndex.
    /// @param _fox A reference to the Fox in storage which needs its timer started.
    function _triggerCooldown(Fox storage _fox) internal {
        // Compute an estimation of the cooldown time in blocks (based on current cooldownIndex).
        _fox.cooldownEndBlock = uint64((cooldowns[_fox.cooldownIndex]/secondsPerBlock) + block.number);

        // Increment the breeding count, clamping it at 13, which is the length of the
        // cooldowns array.
        if (_fox.cooldownIndex < 13) {
            _fox.cooldownIndex += 1;
        }
    }

    /// @dev Checks to see if a Fox is pregnant and (if so) if the gestation
    ///  period has passed.
    function _isReadyToGiveBirth(Fox memory _mother) private view returns (bool) {
        return (_mother.breedingWithId != 0) && (_mother.cooldownEndBlock <= uint64(block.number));
    }
	
	/// @dev Internal check to see if a given mother and father are a valid breeding pair. 
    /// @param _mother A reference to the Fox struct of the potential mother.
    /// @param _motherId The mother's ID.
    /// @param _father A reference to the Fox struct of the potential father.
    /// @param _fatherId The father's ID
    function _isValidBreedingPair(Fox storage _mother, uint256 _motherId, Fox storage _father, uint256 _fatherId) internal view returns(bool) {
        // A Fox can't breed with itself!
        if (_motherId == _fatherId) {
            return false;
        }

        // Foxes can't breed with their parents.
        if (_mother.motherId == _fatherId || _mother.fatherId == _fatherId) {
            return false;
        }
        if (_father.motherId == _motherId || _father.fatherId == _motherId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either fox is
        // gen zero (has a mother ID of zero).
        if (_father.motherId == 0 || _mother.motherId == 0) {
            return true;
        }

        // Foxes can't breed with full or half siblings.
        if (_father.motherId == _mother.motherId || _father.motherId == _mother.fatherId) {
            return false;
        }
        if (_father.fatherId == _mother.motherId || _father.fatherId == _mother.fatherId) {
            return false;
        }

        return true;
    }
	
	/// @notice Have a pregnant Fox give birth!
    /// @param _motherId A Fox ready to give birth.
	/// @param _owner A Fox's owner .
    /// @return The Fox ID of the new fox.
    /// @dev Looks at a given Fox and, if pregnant and if the gestation period has passed,
    ///  combines the genes of the two parents to create a new fox. The new Fox is assigned
    ///  to the current owner of the mother. Upon successful completion, both the mother and the
    ///  new fox will be ready to breed again. Note that anyone can call this function (if they
    ///  are willing to pay the gas!), but the new fox always goes to the mother's owner.
    function _giveBirth(uint256 _motherId, address _owner) internal returns(uint256)
    {
        // Grab a reference to the mother in storage.
        Fox storage mother = foxes[_motherId];

        // Check that the mother is a valid fox.
        require(mother.birthTime != 0, "The mother id isn't valid");

        // Check that the mother is pregnant, and that its time has come!
        require(_isReadyToGiveBirth(mother), "The mother is not yet ready to give birth");

        // Grab a reference to the father in storage.
        uint256 fatherId = mother.breedingWithId;
        Fox storage father = foxes[fatherId];

        // Determine the higher generation number of the two parents
        uint16 parentGen = mother.generation;
        if (father.generation > mother.generation) {
            parentGen = father.generation;
        }

        // Call the sooper-sekret gene mixing operation.
        uint256 childGenes = geneticLab.mixGenes(mother.genes, father.genes, mother.cooldownEndBlock - 1);

        // Create the new fox
        uint256 foxId = _createFox(_motherId, mother.breedingWithId, parentGen + 1, childGenes, _owner);

        // Clear the reference to father from the mother (REQUIRED! Having breedingWithId
        // set is what marks a mother as being pregnant.)
        delete mother.breedingWithId;

        // Every time a Fox gives birth counter is decremented.
        pregnantFoxes--;

        // return the new fox's ID
        return foxId;
    }
	
	/// @dev Internal utility function to initiate breeding, assumes that all breeding
    /// requirements have been checked.
    function _breedWith(uint256 _motherId, address _motherOwner, uint256 _fatherId) internal {
        // Grab a reference to the Foxes from storage.
        Fox storage father = foxes[_fatherId];
        Fox storage mother = foxes[_motherId];

        // Mark the mother as pregnant, keeping track of who the father is.
        mother.breedingWithId = uint32(_fatherId);

        // Trigger the cooldown for both parents.
        _triggerCooldown(father);
        _triggerCooldown(mother);

        // Clear breeding permission for both parents.
        delete breedingAllowedToAddress[_motherId];
        delete breedingAllowedToAddress[_fatherId];

        // Every time a fox gets pregnant, counter is incremented.
        pregnantFoxes++;

        // Emit the pregnancy event.
        emit Pregnant(_motherOwner, _motherId, _fatherId, mother.cooldownEndBlock);
    }
	
}

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin\contracts\token\ERC721\extensions\IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin\contracts\utils\Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin\contracts\utils\Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin\contracts\utils\introspection\ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin\contracts\token\ERC721\ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin\contracts\token\ERC721\extensions\IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin\contracts\token\ERC721\extensions\ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts\MetaFoxes.sol

pragma solidity ^0.8.0;
contract MetaFoxes is ERC721Enumerable, MetaFoxesBreeder, ContextMixin {
    
    uint16 private constant _paidTokensLimit = 10000;
	uint16 private constant _promoTokensLimit = 3000;

    uint16 private _currentPaidTokenCount;
	uint16 private _currentPromoTokenCount;
	
    constructor (address _metaFoxesProxyAddress) ERC721("MetaFoxes", "MF") {
        metaFoxesProxyAddress = _metaFoxesProxyAddress;
		// we start with the mythical fox 0 - so we don't have generation-0 parent issues
        _createFox(0, 0, 0, 0, address(0));
		_safeMint(msg.sender, uint256(0));
		_burn(0);
    }
	
    ////////////////////////////////
    // PUBLIC FUNCTIONS    
    ////////////////////////////////
	
	function canMintPaidToken() public view returns (bool) {
        return _currentPaidTokenCount < _paidTokensLimit;
    }
	
	function canMintPromoToken() public view returns (bool) {
		return _currentPromoTokenCount < _promoTokensLimit;
    }
    
    function createPaidFox(address _owner) public {
        require(_isAllowedMinter(_msgSender()), "MetaFoxes: mint caller is not allowed minter");
            		
		uint256 newFoxGenes = geneticLab.getRandomGenes(uint256(uint160(_owner)));
		
		_currentPaidTokenCount++;
		uint256 newFoxId = _createFox(0, 0, 0, newFoxGenes, _owner);
		// This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _safeMint(_owner, newFoxId);
    }
	
	/// @dev we can create promo foxes, up to a limit. Only callable by owner
    /// @param _genes the encoded genes of the fox to be created, any value is accepted
    /// @param _owner the future owner of the created fox. Default to owner contract
    function createPromoFox(uint256 _genes, address _owner) public {
	    require(_isAllowedMinter(_msgSender()), "MetaFoxes: mint caller is not allowed minter");

        _currentPromoTokenCount++;
        uint256 newFoxId = _createFox(0, 0, 0, _genes, _owner);
		// This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _safeMint(_owner, newFoxId);
    }
	
	/// @notice Breed a Fox you own (as mother) with a father that you own.
    /// @param _motherId The ID of the Fox acting as mother (will end up pregnant if successful)
    /// @param _fatherId The ID of the Fox acting as father (will begin its breeding cooldown if successful)
	function breedWith(uint256 _motherId, uint256 _fatherId) public {
		require(_isAllowedMinter(_msgSender()), "MetaFoxes: breeding caller is not allowed minter");
        _breedWith(_motherId, ownerOf(_motherId), _fatherId);
    }
	
	/// @notice Checks to see if two foxes can breed together, including checks for
    /// ownership and breeding approvals.
    /// @param _motherId The ID of the proposed mother.
    /// @param _fatherId The ID of the proposed father.
    function isValidBreedingPair(uint256 _motherId, uint256 _fatherId) public view returns(bool)
    {
		require(_isAllowedMinter(_msgSender()), "MetaFoxes: Validator caller is not allowed minter");
        require(_motherId > 0, "MetaFoxes: Mother id must be bigger than zero");
        require(_fatherId > 0, "MetaFoxes: Father id must be bigger than zero");
        Fox storage mother = foxes[_motherId];
        Fox storage father = foxes[_fatherId];
		address motherOwner = ownerOf(_motherId);
		address fatherOwner = ownerOf(_fatherId);
        return _isValidBreedingPair(mother, _motherId, father, _fatherId) && _isBreedingPermitted(motherOwner, _fatherId, fatherOwner);
    }
	
	////////////////////////////////
    // EXTERNAL FUNCTIONS    
    ////////////////////////////////
    
	
	/// @notice Returns all the relevant information about a specific fox.
    /// @param _id The ID of the fox of interest.
    function getFox(uint256 _id) external view returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 breedingWithId,
        uint256 birthTime,
        uint256 motherId,
        uint256 fatherId,
        uint256 generation,
        uint256 genes
    ) {
        Fox storage fox = foxes[_id];
        isGestating = (fox.breedingWithId != 0);
        isReady = (fox.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(fox.cooldownIndex);
        nextActionAt = uint256(fox.cooldownEndBlock);
        breedingWithId = uint256(fox.breedingWithId);
        birthTime = uint256(fox.birthTime);
        motherId = uint256(fox.motherId);
        fatherId = uint256(fox.fatherId);
        generation = uint256(fox.generation);
        genes = fox.genes;
    }
	
	/// @notice Grants approval to another user to breed with one of your foxes.
    /// @param _addr The address that will be able to breed with your fox. Set to
    ///  address(0) to clear all breeding approvals for this fox.
    /// @param _fatherId A Fox that you own that _addr will now be able to breed with.
    function approveBreeding(address _addr, uint256 _fatherId) external {
        require(msg.sender == ownerOf(_fatherId), "MetaFoxes: Only father owner is able to approve breeding");
        breedingAllowedToAddress[_fatherId] = _addr;
    }
	
	/// @notice Have a pregnant Fox give birth!
	function giveBirth(uint256 _motherId) external returns(uint256){
		address owner = ownerOf(_motherId);
		uint256 newFoxId = _giveBirth(_motherId, owner);
		// This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _safeMint(owner, newFoxId);
		return newFoxId;
	}
    
    ////////////////////////////////
    // OVERRIDDEN INTERNAL FUNCTIONS    
    ////////////////////////////////
    
    function _baseURI() internal override view returns (string memory) {
        return metaUrl;
    }
    
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }
    
    ////////////////////////////////
    // PRIVATE FUNCTIONS    
    ////////////////////////////////
    
    function _isAllowedMinter(address _minter) private view returns (bool) {
        return _minter == metaFoxesProxyAddress;
    }
    
}