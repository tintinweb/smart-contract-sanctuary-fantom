/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/// @notice Create NFT offers with NFTs (ERC721).
/// @author Axxe, MetalMallard
contract NFTExchange is Auth {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OfferCreated(Offer offer);
    event OfferCanceled(Offer offer);
    event OfferAccepted(Offer offer);

    /*///////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev An offer for an NFT
    /// @param bidder The one that offers
    /// @param targetCollection Targeted NFT collection address
    /// @param offerCollection Offered NFT collection address
    /// @param targetID Targeted NFT id
    /// @param offerID Offered NFT id
    /// @param end Expiration date (timestamp)
    struct Offer {
        address bidder;
        IERC721 targetCollection;
        IERC721 offerCollection;
        uint256 targetID;
        uint256 offerID;
        uint256 end;
    }

    /*///////////////////////////////////////////////////////////////
                              STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Map of active offers
    /// Note: An offer can be expired (date) and inside the map.
    mapping(bytes32 => bool) public offers;

    /// @dev Map of all NFT collections allowed to be exchanged
    ///      (targeted or offered)
    mapping(address => bool) public whitelistedCollection;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Authority _authority) Auth(msg.sender, _authority) {}

    /*///////////////////////////////////////////////////////////////
                                  LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create an offer to exchange an ERC721 for an ERC721.
    ///         The sender is the owner of the offered ERC721.
    /// @param offer The struct offer to create (with all the details)
    function createOffer(Offer calldata offer) external payable {
        require(!offers[keccak256(abi.encode(offer))], "ALREADY_EXISTS");
        require(offer.bidder == msg.sender, "NOT_BIDDER");
        require(msg.value == 1 ether, "FTM sent is not correct");
        require(
            offer.offerCollection.ownerOf(offer.offerID) == msg.sender,
            "NOT_OFFER_OWNER"
        );
        require(
            offer.offerCollection.getApproved(offer.offerID) == address(this),
            "UNAPPROVED"
        );
        require(
            whitelistedCollection[address(offer.offerCollection)] &&
                whitelistedCollection[address(offer.targetCollection)],
            "NOT_WHITELISTED"
        );

        offers[keccak256(abi.encode(offer))] = true;
        emit OfferCreated(offer);
    }

    /// @notice Cancel an offer. The owner of the offered ERC721 or
    ///         the targeted ERC721 can cancel the offer.
    /// @param offer The struct offer to cancel (with all the details).
    function cancelOffer(Offer calldata offer) external {
        require(offers[keccak256(abi.encode(offer))], "NONEXISTENT");
        require(
            msg.sender == offer.targetCollection.ownerOf(offer.targetID) ||
                msg.sender == offer.offerCollection.ownerOf(offer.offerID),
            "UNAUTHORIZED"
        );

        offers[keccak256(abi.encode(offer))] = false;
        emit OfferCanceled(offer);
    }

    /// @notice Accept an offer and transfer the NFTs between the two parties.
    /// @param offer The struct offer to accept (with all the details).
    function acceptOffer(Offer calldata offer) external {
        require(offers[keccak256(abi.encode(offer))], "NONEXISTENT");
        require(
            msg.sender == offer.targetCollection.ownerOf(offer.targetID),
            "UNAUTHORIZED"
        );
        require(
            offer.targetCollection.getApproved(offer.targetID) == address(this),
            "UNAPPROVED"
        );
        require(block.timestamp <= offer.end, "EXPIRED");

        offer.targetCollection.safeTransferFrom(
            msg.sender,
            offer.bidder,
            offer.targetID
        );
        offer.offerCollection.safeTransferFrom(
            offer.bidder,
            msg.sender,
            offer.offerID
        );

        offers[keccak256(abi.encode(offer))] = false;
        emit OfferAccepted(offer);
    }

    /*///////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a collection address to the whitelist to allow exchanges
    ///         with this collection.
    /// @param _collection The collection address to whitelist
    function addCollection(address _collection) external requiresAuth {
        whitelistedCollection[_collection] = true;
    }

    /// @notice Remove a collection address from the whitelist
    /// @param _collection The collection address to remove
    function removeCollection(address _collection) external requiresAuth {
        whitelistedCollection[_collection] = false;
    }

    /// @notice Send funds from sales to the team
    function withdrawAll() public {
        uint256 amount = address(this).balance;
        require(
            payable(0x89B07Ba2d3c04A55632060AA9ea372E1408e3d7B).send(amount)
        );
    }
}