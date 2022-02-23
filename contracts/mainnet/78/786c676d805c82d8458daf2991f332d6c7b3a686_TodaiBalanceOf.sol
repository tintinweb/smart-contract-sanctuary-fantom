/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

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


/// @notice Helper to get BalanceOf (ERC721).
/// @author Axxe, MetalMallard
contract TodaiBalanceOf is Auth {
    /*///////////////////////////////////////////////////////////////
                              STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Map of all NFT collections allowed   
    address[] public whitelistedCollections;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Authority _authority) Auth(msg.sender, _authority) {}

    struct CollectionBalances {
        address collectionAddress;
        uint256 balance;
    }

    /*///////////////////////////////////////////////////////////////
                                  LOGIC
    //////////////////////////////////////////////////////////////*/

    function getBalanceOf(address owner)
        external
        view
        returns (CollectionBalances[] memory balances)
    {
        balances = new CollectionBalances[](whitelistedCollections.length);
        uint256 whitelistedCollectionsLength = whitelistedCollections.length;
        for (uint256 i; i < whitelistedCollectionsLength; i++) {
            balances[i] = CollectionBalances(
                whitelistedCollections[i],
                IERC721(whitelistedCollections[i]).balanceOf(owner)
            );
        }
    }

    function isWhitelisted(address _collection)
        public
        view
        returns (bool isCollectionWhitelisted)
    {
        uint256 whitelistedCollectionsLength = whitelistedCollections.length;
        unchecked {
            for (uint256 i; i < whitelistedCollectionsLength; i++) {
                if (whitelistedCollections[i] == _collection) {
                    isCollectionWhitelisted = true;
                    break;
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a collection address to the whitelist to allow exchanges
    ///         with this collection.
    /// @param _collection The collection address to whitelist
    function addCollection(address _collection) external requiresAuth {
        whitelistedCollections.push(_collection);
    }

    /// @notice Remove a collection address from the whitelist
    /// @param _collection The collection address to remove
    function removeCollection(address _collection) external requiresAuth {
        uint256 index;
        uint256 whitelistedCollectionsLength = whitelistedCollections.length;
        unchecked {
            for (uint256 i; i < whitelistedCollectionsLength; i++) {
                if (whitelistedCollections[i] == _collection) {
                    index = i;
                    break;
                }
            }
        }
        whitelistedCollections[index] = whitelistedCollections[
            whitelistedCollectionsLength - 1
        ];
        whitelistedCollections.pop();
    }
}