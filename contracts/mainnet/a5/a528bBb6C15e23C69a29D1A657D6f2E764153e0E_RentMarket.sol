// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC4907 is IERC721, IERC721Metadata {

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "../utils/IOwnableLink.sol";

interface IRentMarket is IOwnableLink {

    enum Types { 
    /* 0 */ ERC721,
    /* 1 */ ERC4907
    }

    struct Rent {
        uint id;
        uint tokenId;
        address collectionAddress;
        string tokenUri;
        address customer;
        uint lendId;
        uint timeUnitSeconds;
        uint timeUnitCount;
        uint startTimestamp;
        uint endTimestamp;
        bool closed; // true if customer closed rent
    }

    struct Lend {
        uint id;
        Types supprortedInterface;
        uint tokenId;
        address collectionAddress;
        string tokenUri;
        address owner;
        uint timeUnitSeconds;
        uint timeUnitPrice;
        uint timeUnitCount;
        uint startTimestamp;
        uint endTimestamp;
        uint deposit;
        bool claimed; // true if owner claimed lend
        uint[] rents;
    }

    function isApprovedOrOwner(
        address spender, 
        uint256 tokenId, 
        address collectionAddress
    )
        external view returns(bool);

    function getSupportedInterface(address collectionAddress)
        external view returns(Types supportedInterface);

    function getTokenPayment() 
        external view returns(address token);

    function getClosedRentStatus(uint lendId)
        external view returns(bool stealed);

    function getAvailableStatus(uint lendId) 
        external view returns(bool available);

    // list of all lends
    function getLends() 
        external view returns(Lend[] memory lends);

    function getLendsCount()
        external view returns(uint lendCount);

    function getLendById(uint lendId)
        external view returns(Lend memory lend);

    // list of all rents
    function getRents() 
        external view returns(Rent[] memory rents);

    function getRentsCount()
        external view returns(uint rentCount);

    function getRentById(uint rentId)
        external view returns(Rent memory rent);

    // lend page
    function getOwnerLends(address owner)
        external view returns(Lend[] memory lends);

    // rent page
    function getAvailableLends() 
        external view returns(Lend[] memory lends);

    function getCustomerRents(address customer) 
        external view returns(Rent[] memory rents);
    
    function getFinishedLends(address owner)
        external view returns(uint finishedLends);

    function setTokenPayment(address token) 
        external;

    function initLendERC721(
        uint tokenId,
        address collectionAddress,
        uint timeUnitSeconds,
        uint timeUnitPrice,
        uint timeUnitCount,
        uint deposit
    )
        external returns(uint256 lendId);

    function initLend(
        uint tokenId,
        address collectionAddress,
        uint timeUnitSeconds,
        uint timeUnitPrice,
        uint timeUnitCount
    )
        external returns(uint256 lendId);

    function closeLend(uint lendId)
        external;

    function claimLends()
        external;

    function initRent(uint lendId, uint timeUnitCount) 
        external returns(uint rentId);

    function closeRent(uint rentId) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../EIPs/IERC4907.sol";
import "../utils/OwnableLink.sol";
import "./IRentMarket.sol";

contract RentMarket is IRentMarket, OwnableLink {

    using Counters for Counters.Counter;
    
    constructor (address _owanble) {
        ownable = IOwnable(_owanble);
    }

    bytes4 INTERFACE_ERC4907 = type(IERC4907).interfaceId;
    bytes4 INTERFACE_ERC721 = type(IERC721).interfaceId;

    IERC20 _tokenPayment;

    Counters.Counter private _lends;
    Counters.Counter private _rents;
    mapping (address=>mapping (uint=>uint)) private _nftToLend;
    mapping (uint=>Lend) private _lendMap;
    mapping (uint=>Rent) private _rentMap;

    function isApprovedOrOwner(
        address spender, 
        uint256 tokenId, 
        address collectionAddress
    )
        public view override returns(bool)
    {
        IERC4907 collection = IERC4907(collectionAddress);
        address owner = collection.ownerOf(tokenId);
        return 
            spender == owner ||
            collection.isApprovedForAll(owner, spender) ||
            collection.getApproved(tokenId) == spender;
    }

    function getSupportedInterface(address collectionAddress)
        public view returns(Types supportedInterface) {
        IERC4907 nft = IERC4907(collectionAddress);
        if (nft.supportsInterface(INTERFACE_ERC4907)) {
            return Types.ERC4907;
        } else if (nft.supportsInterface(INTERFACE_ERC721)) {
            return Types.ERC721;
        } else {
            revert("Doesn't support ERC721 or ERC4907");
        }
    }

    function getTokenPayment() 
        public view override returns(address token) {
        token = address(_tokenPayment);
    }

    function getClosedRentStatus(uint lendId)
        public view returns(bool stealed /* or in use */) {
        Lend storage lend = _lendMap[lendId];
        for (uint i; i < lend.rents.length; i++) {
            Rent storage rent = _rentMap[lend.rents[i]];
            if (!rent.closed) {
                stealed = true;
            }
        }
    }

    function getAvailableStatus(uint lendId)
        public view override returns(bool available) {
        Lend storage lend = _lendMap[lendId];
        if (isApprovedOrOwner(
            address(this), 
            lend.tokenId, 
            lend.collectionAddress)) {
            if (lend.endTimestamp > block.timestamp) {
                return lend.rents.length == 0
                    ? true 
                    : _rentMap[
                        lend.rents[lend.rents.length-1]
                        ].endTimestamp < block.timestamp
                        ? false
                        : getClosedRentStatus(lend.id);
            }
        }
    }

    function getLends()
        public view override returns(Lend[] memory lends) {
        uint lendsCount = _lends.current();
        lends = new Lend[](lendsCount);
        for (uint256 i; i < lendsCount; i++) {
            lends[i] = _lendMap[i+1];
        }
    }

    function getLendsCount()
        public view override returns(uint lendCount) {
        lendCount = _lends.current();
    }

    function getLendById(uint lendId)
        public view override returns(Lend memory lend) {
        lend = _lendMap[lendId];
    }
    
    function getRents() 
        public view override returns(Rent[] memory rents) {
        uint rentsCount = _rents.current();
        rents = new Rent[](rentsCount);
        for (uint i; i < rentsCount; i++) {
            rents[i] = _rentMap[i+1];
        }
    }

    function getRentsCount()
        public view override returns(uint rentCount) {
        rentCount = _rents.current();
    }

    function getRentById(uint rentId)
        public view override returns(Rent memory rent) {
        rent = _rentMap[rentId];
    }


    function getOwnerLends(address owner) 
        public view override returns(Lend[] memory lends) {
        uint lendsCount = _lends.current();
        uint ownerLendCount;
        uint current;

        for (uint i; i < lendsCount; i++) {
            if (_lendMap[i+1].owner == owner) {
                if (!_lendMap[i+1].claimed) {
                // if (_lendMap[i+1].endTimestamp > block.timestamp) {
                    ownerLendCount++;
                }
            }
        }

        lends = new Lend[](ownerLendCount);

        for (uint i; i < lendsCount; i++) {
            if (_lendMap[i+1].owner == owner) {
                if (!_lendMap[i+1].claimed) {
                // if (_lendMap[i+1].endTimestamp > block.timestamp) { // to show all
                    lends[current] = _lendMap[i+1];
                    IERC4907 collection = IERC4907(
                        lends[current].collectionAddress
                    );
                    lends[current].tokenUri = collection.tokenURI(
                        lends[current].tokenId
                    );
                    current++;
                }
            }
        }
    }

    function getAvailableLends() 
        public view override returns(Lend[] memory lends) {
        uint lendsCount = _lends.current();
        uint availableRentCount;
        uint current;
        for (uint i; i < lendsCount; i++) {
            if (getAvailableStatus(i+1)) {
                if (_lendMap[i+1].endTimestamp > block.timestamp) {
                    availableRentCount++;
                }
            }
        }

        lends = new Lend[](availableRentCount);

        for (uint i; i < lendsCount; i++) {
            if (getAvailableStatus(i+1)) {
                if (_lendMap[i+1].endTimestamp > block.timestamp) {
                    lends[current] = _lendMap[i+1];
                    IERC4907 collection = IERC4907(
                        lends[current].collectionAddress
                    );
                    lends[current].tokenUri = collection.tokenURI(
                        lends[current].tokenId
                    );
                    current++;
                }
            }
        }
    }

    function getCustomerRents(address customer) 
        public view override returns(Rent[] memory rents) {
        uint rentsCount = _rents.current();
        uint customerRentCount;
        uint current;

        for (uint i; i < rentsCount; i++) {
            if (_rentMap[i+1].customer == customer) {
                if (_rentMap[i+1].endTimestamp > block.timestamp) {
                    customerRentCount++;
                }
            }
        }

        rents = new Rent[](customerRentCount);

        for (uint i; i < rentsCount; i++) {
            if (_rentMap[i+1].customer == customer) {
                if (_rentMap[i+1].endTimestamp > block.timestamp) {
                    rents[current] = _rentMap[i+1];
                    IERC4907 collection = IERC4907(
                        rents[current].collectionAddress
                    );
                    rents[current].tokenUri = collection.tokenURI(
                        rents[current].tokenId
                    );
                    current++;
                }
            }
        }
    }

    
    function getFinishedLends(address owner)
        public view override returns(uint finishedLends) {
        Lend[] memory lends = getOwnerLends(owner);
        for (uint i; i < lends.length; i++) {
            Lend storage lend = _lendMap[lends[i].id];
            if (lend.endTimestamp < block.timestamp) {
                if (!lend.claimed) {
                    finishedLends++;
                }
            }
        }
    }

    function setTokenPayment(address token)
        public override CheckPerms {
        _tokenPayment = IERC20(token);
    }

    function _initLend(
        Types supportedInterface,
        uint tokenId,
        address collectionAddress,
        uint timeUnitSeconds,
        uint timeUnitPrice,
        uint timeUnitCount,
        uint deposit
    )
        private returns(uint256 lendId) {
        IERC4907 collection = IERC4907(collectionAddress);
        address owner = collection.ownerOf(tokenId);

        require(
            collection.userOf(tokenId) == address(0) || 
            collection.userOf(tokenId) != collection.ownerOf(tokenId), 
            "this token already used");
        require(owner == msg.sender, "haven't this token id");

        _lends.increment();
        lendId = _lends.current();
        uint startTimestamp = block.timestamp;
        uint endTimestamp = startTimestamp + timeUnitCount * timeUnitSeconds;
        
        _nftToLend[collectionAddress][tokenId] = lendId;
        _lendMap[lendId] = Lend(
            lendId,
            supportedInterface,
            tokenId,
             collectionAddress,
            "",
            owner,
            timeUnitSeconds,
            timeUnitPrice,
            timeUnitCount,
            startTimestamp,
            endTimestamp,
            deposit,
            false,
            new uint[](0)
        );

    }

    function initLendERC721(
        uint tokenId,
        address collectionAddress,
        uint timeUnitSeconds,
        uint timeUnitPrice,
        uint timeUnitCount,
        uint deposit
    )
        public override returns(uint256 lendId) {
        require(
            getSupportedInterface(collectionAddress) == Types.ERC721 ||
            getSupportedInterface(collectionAddress) == Types.ERC4907,
            "Doesn't support ERC721");
        lendId = _initLend(
            Types.ERC721,
            tokenId,
            collectionAddress,
            timeUnitSeconds,
            timeUnitPrice,
            timeUnitCount,
            deposit
        );
    }

    function initLend(
        uint tokenId,
        address collectionAddress,
        uint timeUnitSeconds,
        uint timeUnitPrice,
        uint timeUnitCount
    ) 
        public override returns(uint256 lendId) {
        require(
            getSupportedInterface(collectionAddress) == Types.ERC4907,
            "Doesn't support ERC4907");
        lendId = _initLend(
            Types.ERC4907,
            tokenId,
            collectionAddress,
            timeUnitSeconds,
            timeUnitPrice,
            timeUnitCount,
            0
        );
    }

    function closeLend(uint lendId) 
        public override {
        Lend storage lend = _lendMap[lendId];
        require(!lend.claimed, "already claimed");
        require(lend.endTimestamp < block.timestamp, "its landing now");
        uint tokenAmount;
        
        if (lend.rents.length > 0) {
            for (uint i; i < lend.rents.length; i++) {
                tokenAmount += 
                    lend.timeUnitPrice * 
                    _rentMap[lend.rents[i]].timeUnitCount;
                if (lend.supprortedInterface == Types.ERC721) {
                    if (getClosedRentStatus(lendId)) {
                        tokenAmount += lend.deposit;
                    }
                }
            }

            _tokenPayment.transfer(lend.owner, tokenAmount);
        }

        lend.claimed = true;
    }

    function claimLends()
        public override {
        Lend[] memory lends = getOwnerLends(msg.sender);
        for (uint i; i < lends.length; i++) {
            Lend storage lend = _lendMap[lends[i].id];
            if (lend.endTimestamp < block.timestamp) {
                if (!lend.claimed) {
                    closeLend(lend.id);
                }
            }
        }
    }

    function initRent(
        uint lendId, 
        uint timeUnitCount
    ) 
        public override returns(uint rentId) {
        Lend storage lend = _lendMap[lendId];
        uint tokenAmount = lend.timeUnitPrice * timeUnitCount;
        if (lend.supprortedInterface == Types.ERC721) {
            require(_tokenPayment.allowance(msg.sender, address(this)) >= lend.deposit, "Haven't tokens to deposit");
            _tokenPayment.transferFrom(msg.sender, address(this), lend.deposit);
        }
        require(
            lend.endTimestamp >
            lend.timeUnitSeconds * timeUnitCount + block.timestamp, 
            "request time more then available");
        require(lend.owner != msg.sender, "you can't rent your token");
        require(getAvailableStatus(lendId), "lend is busy");
        require(_tokenPayment.allowance(
            msg.sender, 
            address(this)
            ) >= tokenAmount, "allowance is so low");
        
        _rents.increment();
        rentId = _rents.current();
        address customer = msg.sender;
        uint startTimestamp = block.timestamp;
        uint endTimestamp = startTimestamp + timeUnitCount * lend.timeUnitSeconds;
        IERC4907 collection = IERC4907(lend.collectionAddress);
        
        if (lend.supprortedInterface == Types.ERC4907) {
            collection.setUser(lend.tokenId, customer, uint64(endTimestamp));
        } else {
            collection.transferFrom(lend.owner, msg.sender, lend.tokenId);
        }
        _tokenPayment.transferFrom(msg.sender, address(this), tokenAmount);

        _rentMap[rentId] = Rent(
            rentId,
            lend.tokenId,
            lend.collectionAddress,
            "",
            customer,
            lendId,
            lend.timeUnitSeconds,
            timeUnitCount,
            startTimestamp,
            endTimestamp,
            false
        );
        _lendMap[lendId].rents.push(rentId);
    }

    function closeRent(uint rentId) 
        public override {
        // todo
        Rent storage rent = _rentMap[rentId];
        Lend storage lend = _lendMap[rent.lendId];
        IERC4907 collection = IERC4907(lend.collectionAddress);
        require(rent.endTimestamp < block.timestamp, "to late");
        require(lend.supprortedInterface == Types.ERC721, "doesn't need to close");
        require(isApprovedOrOwner(address(this), lend.tokenId, lend.collectionAddress), "doesn't approved");
        collection.transferFrom(msg.sender, address(this), lend.tokenId);
        _tokenPayment.transfer(msg.sender, lend.deposit);
        rent.closed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IOwnable {
    function checkPerms(address addr) external view returns(bool);
    function checkOwner(address addr) external view returns(bool);
    function owner() external view returns(address);
    function getWallet() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IOwnableLink {
    function setOwnable(address _ownable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./IOwnableLink.sol";
import "./IOwnable.sol";

contract OwnableLink is IOwnableLink {
    IOwnable ownable;

    function setOwnable(address _ownable) public override CheckPerms {
        ownable = IOwnable(_ownable);
    }

    modifier CheckPerms() {
        require(ownable.checkPerms(msg.sender) );
        _;
    }

    modifier CheckOwner() {
        require(ownable.checkOwner(msg.sender));
        _;
    }
}