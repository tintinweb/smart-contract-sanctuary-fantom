/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT

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


pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
pragma solidity ^0.8.0;

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

    function mint(address to, uint256 amount) external;

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


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;


    function wear(
        uint256 tokenId
    ) external;
}

interface WCBackpack {
  function usePotion(address user, uint256 slot) external;
}

contract WCGameServer is ERC721Holder, ERC1155Holder, AccessControl {
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    address public Treasury = 0x39cBFC3377Ba379Bb3681A31A3c94e5B0D6028bA;

    address public server = 0xcE824b1dADaa23F76006315e18f596009De1bA63;

    address public _itemAddress;

    address public _backpackAddress;

    IERC20 public constant _WARToken = IERC20(0x7434ff4E38D0e7F207BaCC2c6170a32211A13e37);

    IERC721 public constant _WC = IERC721(0x340B62591a489CDe3906690e59a3b4D154024B32);

    uint256 public _matchesCount = 0;
    uint256 public currentPlayers = 0;
    bool public serverStatus = false;
    uint256 public serverFee = 100000000000000000;

    uint256 public emissionRate = 300000000000000000000;
    uint256 public winnerEmission = 100000000000000000000;
    uint256 public loserEmission = 50000000000000000000;

    mapping(address => uint256) public currentDuels;
    mapping(uint256 => MatchInfo) public _matchInfo;
    //day => tokenId => earnings that day
    mapping(uint256 => mapping (uint256 => uint256)) public dayAllowance;

    mapping(address => Record) public walletRecord;
    mapping(uint256 => Record) public cardRecord;

    mapping(uint256 => mapping (uint256 => QueueStruct)) public _queue;
    mapping(uint256 => Glossary) public queueGlossary;

    struct Record {
        uint256 wins;
        uint256 losses;
        uint256 elo;
        string name;
        string victoryLine;
    }

    struct QueueStruct {
        uint256[] TokenID;
        address Address;
        uint256 Weapon;
    }

    struct Glossary{
        uint256 price;
        address currency;
        bool enabled;
    }

    struct MatchInfo{
        uint256[] a;
        uint256[] b;
        uint256 itemA;
        uint256 itemB;
        address addressA;
        address addressB;
        uint256 matchType;
    }

    event QueueUp(address addressAddress, string addressName, uint256 queueType, uint256 matchSize); //Event for queue up
    event DuelStarted(MatchInfo info, string addressAName, string addressBName); //Event for Start of Duel
    event DuelEnded(MatchInfo info, string addressAName, string addressBName, uint8 winner); //Event for End of Duel


    constructor() {
        grantGodMode(msg.sender);
    }

    function grantGodMode(address god) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, god);
        _grantRole(DEV_ROLE, god);
    }

    function changeHeadAdmin(address newHeadAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantGodMode(newHeadAdmin);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addDev(address newDev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEV_ROLE, newDev);
    }

    function removeDev(address dev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEV_ROLE, dev);
    }

    function setItemAddress(address itemContract) public onlyRole(DEV_ROLE) {
        _itemAddress = itemContract;
    }

    function setBackpackAddress(address backpackAddress) public onlyRole(DEV_ROLE) {
        _backpackAddress = backpackAddress;
    }

    function Queue(uint256[] memory tokenID, uint256 weaponChoice, uint256 queueType) payable public{
        require(serverStatus == true, "Server is under maintenance");
        require(queueGlossary[queueType].enabled == true, "This queueType is not enabled");
        require(tokenID.length <= 3, "Max of 3 WC allowed");
        for (uint i = 0; i < tokenID.length; i++) {
            require(msg.sender == _WC.ownerOf(tokenID[i]), "WC is not yours");
        }
        require(currentDuels[msg.sender] == 0, "Only one duel at a time per address");
        require(weaponChoice == 0 || weaponChoice == 1, "weaponChoice has to be left or right hand (0 or 1)");

        if(queueGlossary[queueType].currency != address(0)){
            bool transferComplete = IERC20(queueGlossary[queueType].currency).transferFrom(msg.sender, address(this), queueGlossary[queueType].price*tokenID.length);
            if(transferComplete == false){
                revert("Something bad happened with the ERC20");
            }
            if(serverFee*tokenID.length != msg.value){
                revert("Incorrect amount sent for this duel type");
            }
        }else{
            if((queueGlossary[queueType].price*tokenID.length)+(serverFee*tokenID.length) != msg.value){
                revert("Incorrect amount sent for this duel type");
            }
        }

        for (uint i = 0; i < tokenID.length; i++) {
            _WC.safeTransferFrom(msg.sender, address(this), tokenID[i]);
        }
        currentPlayers++;

        if(_queue[queueType][tokenID.length].TokenID[0] == 0){
            _queue[queueType][tokenID.length].TokenID = tokenID;
            _queue[queueType][tokenID.length].Address = msg.sender;
            _queue[queueType][tokenID.length].Weapon = weaponChoice;
            currentDuels[msg.sender] = 1;

            //Event
            emit QueueUp(msg.sender, walletRecord[msg.sender].name, queueType, tokenID.length);

        }else{
            uint256[] memory aTokenID = _queue[queueType][tokenID.length].TokenID;
            uint256[] memory bTokenID = tokenID;

            _matchesCount++;
            currentDuels[msg.sender] = _matchesCount + 2;
            currentDuels[_queue[queueType][tokenID.length].Address] = _matchesCount + 2;

            MatchInfo memory matchInfo;

            matchInfo.a = aTokenID;
            matchInfo.b = bTokenID;
            matchInfo.addressA = _queue[queueType][tokenID.length].Address;
            matchInfo.addressB = msg.sender;
            matchInfo.matchType = queueType;

            _matchInfo[_matchesCount] = matchInfo;

            // Remove WC from queue
            _queue[queueType][tokenID.length].TokenID[0] = 0;

            //Fee so server can end duel later
            payable(server).transfer(serverFee*2*tokenID.length);

            //Event
            emit DuelStarted(_matchInfo[_matchesCount], walletRecord[_queue[queueType][tokenID.length].Address].name, walletRecord[msg.sender].name);
        }
    }

    function removeFromQueue(uint256 queueType, uint256 matchSize) public{
        require(currentDuels[msg.sender] == 1, "Your WC isn't in queue");
        require(msg.sender == _queue[queueType][matchSize].Address, "Not your WC");

        currentDuels[msg.sender] = 0;
        currentPlayers--;
        for (uint i = 0; i < matchSize; i++) {
            _WC.safeTransferFrom(address(this), msg.sender, _queue[queueType][matchSize].TokenID[i]);
        }
        _queue[queueType][matchSize].TokenID[0] = 0;
        if(queueGlossary[queueType].currency != address(0)){
            bool transferComplete = IERC20(queueGlossary[queueType].currency).transfer(msg.sender, queueGlossary[queueType].price*matchSize);
            if(transferComplete == false){
                revert("Something bad happened with the ERC20");
            }
            payable(msg.sender).transfer(serverFee*matchSize);
        }else{
            payable(msg.sender).transfer((queueGlossary[queueType].price*matchSize)+(serverFee*matchSize));
        }
    }

    function getQueuedTokens(uint256 queueType, uint256 matchSize) public view returns(uint256[] memory){
        uint256[] memory result = new uint256[](matchSize);
        for (uint i = 0; i < matchSize; i++) {
                result[i] =  _queue[queueType][matchSize].TokenID[i];
        }
        return result;
    }

    function nameWallet(string memory newName) public{
        require(bytes(newName).length <= 42, "Address name has to be less than 42 characters");
        walletRecord[msg.sender].name = newName;
    }

    function setVictoryLine(string memory newVictoryLine) public{
        require(bytes(newVictoryLine).length <= 280, "Victory line has to be less than 280 characters");
        walletRecord[msg.sender].victoryLine = newVictoryLine;
    }

    function nameCard(string memory newName, uint256 tokenID) public{
        require(msg.sender == _WC.ownerOf(tokenID), "WC is not yours");
        require(bytes(newName).length <= 32, "Card name has to be less than 32 characters");
        cardRecord[tokenID].name = newName;
    }

    function addGlossaryPrice(uint256 _price, uint256 index) public onlyRole(DEV_ROLE) {
        queueGlossary[index].price = _price;
        queueGlossary[index].enabled = false;
    }

    function addGlossaryCurrency(address _currency, uint256 index) public onlyRole(DEV_ROLE) {
        queueGlossary[index].currency = _currency;
        queueGlossary[index].enabled = false;
    }

    function enableGlossary(uint256 index) public onlyRole(DEV_ROLE) {
        if(_queue[index][1].TokenID.length == 0){
            for (uint i = 1; i <= 3; i++) {
                _queue[index][i].TokenID = [0];
            }
        }
        queueGlossary[index].enabled = true;
    }

    function changeTreasury(address newOwner) public onlyRole(DEV_ROLE) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        Treasury = newOwner;
    }

    function changeServerAddress(address newServer) public onlyRole(DEV_ROLE) {
        require(newServer != address(0), "Ownable: new owner is the zero address");
        server = newServer;
    }

    function changeServerFee(uint256 newServerFee) public onlyRole(DEV_ROLE) {
        serverFee = newServerFee;
    }

    function changeEmissionRate(uint256 newEmissionRate) public onlyRole(DEV_ROLE) {
        emissionRate = newEmissionRate;
    }

    function changeWinnerEmission(uint256 newWinnerEmission) public onlyRole(DEV_ROLE) {
        winnerEmission = newWinnerEmission;
    }

    function changeLoserEmission(uint256 newLoserEmission) public onlyRole(DEV_ROLE) {
        loserEmission = newLoserEmission;
    }

    function changeServerStatus() public onlyRole(DEV_ROLE) {
        if(serverStatus == false){
            serverStatus = true;
        }else{
            serverStatus = false;
        }
    }

    //A winner == 0, B winner == 1
    function endDuel(uint256 matchIndex, uint8 winner, uint256[] calldata elo, uint256[] calldata usedPots) public onlyRole(DEV_ROLE) {
        endLogic(matchIndex, winner, elo);

        //Burn Potions that were used
        if(usedPots[0] < 100){
            WCBackpack(_backpackAddress).usePotion(_matchInfo[matchIndex].addressA, usedPots[0]);
        }
        if(usedPots[1] < 100){
            WCBackpack(_backpackAddress).usePotion(_matchInfo[matchIndex].addressB, usedPots[1]);
        }


        //Reset Variables
        currentDuels[_matchInfo[matchIndex].addressA] = 0;
        currentDuels[_matchInfo[matchIndex].addressB] = 0;

        currentPlayers = currentPlayers -2;

        //Event
        emit DuelEnded(_matchInfo[matchIndex], walletRecord[_matchInfo[matchIndex].addressA].name, walletRecord[_matchInfo[matchIndex].addressB].name, winner);
    }

    function endLogic(uint256 matchIndex, uint8 winner, uint256[] calldata elo) internal {
        address ownerA = _matchInfo[matchIndex].addressA;
        address ownerB = _matchInfo[matchIndex].addressB;

        address[] memory Owner = new address[](2);

        uint256[] memory WARAllowance = new uint256[](2);

        if(winner == 0){
            Owner[0] = ownerA;
            Owner[1] = ownerB;
        }else{
            Owner[0] = ownerB;
            Owner[1] = ownerA;
        }

        //Wallet wins/losses
        walletRecord[Owner[0]].wins++;
        walletRecord[Owner[1]].losses++;

        walletRecord[Owner[0]].elo = elo[0];
        walletRecord[Owner[1]].elo = elo[1];

        //Card wins/losses & WAR Emissions
        if(Owner[0] == _matchInfo[matchIndex].addressA){
            for (uint256 i = 0; i < _matchInfo[matchIndex].a.length; i++) {
                cardRecord[_matchInfo[matchIndex].a[i]].wins++;
                cardRecord[_matchInfo[matchIndex].b[i]].losses++;

                //Winner War Tokens
                if(dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] <= emissionRate){
                    if(emissionRate - dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] >= winnerEmission){
                        WARAllowance[0] += winnerEmission;
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] += winnerEmission;
                    }else{
                        WARAllowance[0] += (emissionRate-dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]]);
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] = emissionRate;
                    }
                }

                //Loser War Tokens
                if(dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] < emissionRate){
                    if(emissionRate - dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] >= loserEmission){
                        WARAllowance[1] += loserEmission;
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] += loserEmission;
                    }else{
                        WARAllowance[1] += (emissionRate-dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]]);
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] = emissionRate;
                    }
                }
            }
        }else{
            for (uint256 i = 0; i < _matchInfo[matchIndex].a.length; i++) {
                cardRecord[_matchInfo[matchIndex].b[i]].wins++;
                cardRecord[_matchInfo[matchIndex].a[i]].losses++;

                //Winner War Tokens
                if(dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] <= emissionRate){
                    if(emissionRate - dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] >= winnerEmission){
                        WARAllowance[0] += winnerEmission;
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] += winnerEmission;
                    }else{
                        WARAllowance[0] += (emissionRate-dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]]);
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].b[i]] = emissionRate;
                    }
                }

                //Loser War Tokens
                if(dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] < emissionRate){
                    if(emissionRate - dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] >= loserEmission){
                        WARAllowance[1] += loserEmission;
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] += loserEmission;
                    }else{
                        WARAllowance[1] += (emissionRate-dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]]);
                        dayAllowance[(block.timestamp - 1655424000) / 86400][_matchInfo[matchIndex].a[i]] = emissionRate;
                    }
                }
            }
        }

        //Transfer NFTs back and apply wear to equipment
        for (uint i = 0; i < _matchInfo[matchIndex].a.length; i++) {
            _WC.safeTransferFrom(address(this), ownerA, _matchInfo[matchIndex].a[i]);
            _WC.safeTransferFrom(address(this), ownerB, _matchInfo[matchIndex].b[i]);

            IERC1155(_itemAddress).wear(_matchInfo[matchIndex].a[i]);
            IERC1155(_itemAddress).wear(_matchInfo[matchIndex].b[i]);
        }

        //Send prize
        uint256 prize = ((queueGlossary[_matchInfo[matchIndex].matchType].price)*(_matchInfo[matchIndex].a.length)*2)/10;
        if(queueGlossary[_matchInfo[matchIndex].matchType].currency != address(0)){
            bool transferCompleteWinner = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(Owner[0]), prize*9);
            bool transferCompleteTreasury = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(Treasury), prize);
            if(transferCompleteWinner == false || transferCompleteTreasury == false){
                revert("Something bad happened with the ERC20");
            }
        }else{
            payable(Owner[0]).transfer(prize*9);
            payable(Treasury).transfer(prize);
        }

        //Send WAR Tokens
        _WARToken.mint(Owner[0], WARAllowance[0]);
        _WARToken.mint(Owner[1], WARAllowance[1]);

    }

    //Manual ending of duel
    function endDuelDraw(uint256 matchIndex) public onlyRole(DEV_ROLE) {
        address ownerA = _matchInfo[matchIndex].addressA;
        address ownerB = _matchInfo[matchIndex].addressB;

        //Transfer NFTs
        for (uint i = 0; i < _matchInfo[matchIndex].a.length; i++) {
            _WC.safeTransferFrom(address(this), ownerA, _matchInfo[matchIndex].a[i]);
            _WC.safeTransferFrom(address(this), ownerB, _matchInfo[matchIndex].b[i]);
        }

        //Send prize
        uint256 prize = ((queueGlossary[_matchInfo[matchIndex].matchType].price)*(_matchInfo[matchIndex].a.length)*2)/10;
        if(queueGlossary[_matchInfo[matchIndex].matchType].currency != address(0)){
            bool transferCompleteA = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(ownerA), prize*5);
            bool transferCompleteB = IERC20(queueGlossary[_matchInfo[matchIndex].matchType].currency).transfer(address(ownerB), prize*5);
            if(transferCompleteA == false || transferCompleteB == false){
                revert("Something bad happened with the ERC20");
            }
        }else{
            payable(ownerA).transfer(prize*5);
            payable(ownerB).transfer(prize*5);
        }

        //Send WAR Tokens
        _WARToken.mint(ownerA, 100000000000000000000);
        _WARToken.mint(ownerB, 100000000000000000000);

        //reset variables
        currentDuels[ownerA] = 0;
        currentDuels[ownerB] = 0;

        currentPlayers = currentPlayers -2;

        //Event
        emit DuelEnded(_matchInfo[matchIndex], walletRecord[ownerA].name, walletRecord[ownerB].name, 2);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}