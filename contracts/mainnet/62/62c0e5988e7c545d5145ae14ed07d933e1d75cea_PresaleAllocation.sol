pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./include/IVault.sol";
import "./include/IPresaleAllocation.sol";

/************
 * Tracks allocations from presale and allows redemption.
 * The number of tokens redeemed is the allocation * a factor to be determined later.
 * The factor is expressed in 1e9, so 150% would be 1,500,000,000 (15e8) and 75% would be 750,000,000 (75e7)
 *
 * Requires
 *     Withdrawal Role for Token Vault
 */
contract PresaleAllocation is IPresaleAllocation, Pausable, AccessControl {
    /***************************
     * Data
     */

    // Who can pause this contract - only affects redeem()
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Who can allocate tokens to an address
    bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");

    // Redemption Factor
    uint256 public constant REDEMPTION_FACTOR_MAGNITUDE = 1e9;

    // The token this contract will issue
    address public tokenAddress;
    IERC20 private token;

    //  Redemption factor. allocations * redemptionFactor = Ooze Tokens
    uint256 public redemptionFactor = 0;

    // Where tokens are stored
    address public tokenVaultAddress;
    IVault private tokenVault;

    // Launch time
    uint256 private notBefore;

    // Per-wallet allocations or pre-sale units, which are scaled
    // for each sale and normalized. Redemption will apply a factor to this to arrive at the
    // correct # of tokens per the presale rules.
    mapping(address => uint256) public allocated;

    /************************************************
     * Events
     */

    event AllocationIncreased(address indexed address_, uint256 increase, uint256 allocated);
    event AllocationDecreased(address indexed address_, uint256 decrease, uint256 allocated);
    event Redeemed(address indexed address_, uint256 redeemed, uint256 tokensTransferred);

    /************************************************
     * Constructor
     */

    /**
     * @notice Set the owner, Token and TokenVault for redemption. 
     * @param owner The Multi-Sig which controls this contract
     */
    constructor(address owner) {
        // Control assigned immediately to multi-sig
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        // ALLOCATOR_ROLE is not set. Multi-sig must set this role on Presale and Pre-mint Contracts after deployment

        _pause();

    }

    /***************************
     * Admin Methods
     */

    /**
     * @notice Set the opening time for redemption
     * @dev redeem() is still subject to pause
     * @param _notBefore Timestamp before which redemption is disallowed
     */
    function setRedemptionTime(uint256 _notBefore) external onlyRole(DEFAULT_ADMIN_ROLE) {
        notBefore = _notBefore;
    }

    /**
     * @notice Set the redemption factor.
     * @dev Example: 1.5 tokens per unit, set this to 1,500,000,000
     * @param _factor - this is the conversion of allocation units to tokens, x 1e9
     */
    function setRedemptionFactor(uint256 _factor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_factor > 0, "Redemption factor cannot be 0");
        redemptionFactor = _factor;
    }

    /**
     * @notice Set the Token and TokenVault for redemption. 
     * @param _tokenAddress The Address of the token. These are the tokens that are delivered by the redeem() function
     * @param _vaultAddress The Address of the Vault holding the tokens to distribute
     */
    function setToken(address _tokenAddress, address _vaultAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_vaultAddress != address(0) && _tokenAddress != address(0), "Invalid values");
        tokenVaultAddress = _vaultAddress;
        tokenVault = IVault(_vaultAddress);

        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }

    /***************************
     * Allocation Methods
     */

    /**
     * @dev Increase the allocation for a specified address.
     *      This is intended to be called by another contract which is assigned the ALLOCATOR_ROLE.
     *      That contract, based on its own rules, determines the magnitude of the increase in allocation.
     * @param _address Wallet to credit
     * @param increase Number of units to add
     * @return Total Allocated Units
     */
    function increaseAllocation(address _address, uint256 increase) external onlyRole(ALLOCATOR_ROLE) returns (uint256) {
        require(_address != address(0), "Invalid address");
        require(increase > 0, "Increase cannot be 0");

        // Resulting total allocation.
        uint256 totalAllocated = allocated[_address] + increase;
        allocated[_address] = totalAllocated;

        // Emit Events
        emit AllocationIncreased(_address, increase, totalAllocated);

        // Return result
        return totalAllocated;
    }

    /**
     * @dev Decrease the allocation for a specified address
     *      This is intended to be called by another contract which is assigned the ALLOCATOR_ROLE.
     *      That contract, based on its own rules, determines the magnitude of the decrease in allocation.
     *      The use-case for this is the NFT pre-minter. Before the token is launched, players can pre-mint
     *      an NFT and assign Ooze tokens to its deposit, before the Ooze token is launched. Since Ooze tokens
     *      are delivered from the Vault on redemption, and returned to the vault on deposit,
     *      this function need not transfer the tokens, as long as the allocation is properly accounted for.
     * @param _address Wallet to credit
     * @param decrease Number of units to remove
     * @return Total Allocated Units
     */
    function decreaseAllocation(address _address, uint256 decrease) public onlyRole(ALLOCATOR_ROLE) returns (uint256) {
        require(_address != address(0), "Invalid address");
        require(decrease > 0, "Decrease cannot be 0");

        uint256 currentAllocation = allocated[_address];
        // revert on invalid value/potential underflow
        require(decrease <= currentAllocation, "Decrease exceeds allocation");
        // Resulting total allocation
        uint256 totalAllocated = currentAllocation - decrease;
        allocated[_address] = totalAllocated;

        // Emit Events
        emit AllocationDecreased(_address, decrease, totalAllocated);

        // return result
        return totalAllocated;
    }

    /**
     * @dev Decrease the allocation for a specified address by tokens.
     *     Convert the tokens to allocation units per the redemption factor. Ensure that the resulting units 
     *     are within the limits of the users allocation.
     *     Perform the de-allocation, and return the number of allocation units remaining and the number of tokens issued.
     *     This is a convenience wrapper around decreaseAllocation() which uses Tokens instead of allocation units.
     *     See the comment for decreaseAllocation() for the use-case for this function.
     * @param _address Wallet to credit
     * @param tokens Number of tokens to remove
     * @return remaining Total Remaining Allocated Units
     * @return tokensIssued Actual number of tokens issued
     */
    function decreaseAllocationByTokens(address _address, uint256 tokens) external onlyRole(ALLOCATOR_ROLE) returns (uint256 remaining, uint256 tokensIssued) {
        require(_address != address(0), "Invalid address");
        require(tokens > 0, "Decrease cannot be 0");
        require(redemptionFactor != 0, "Redemption factor not set");

        uint256 units = tokensToAllocation(tokens);
        if (units > allocated[_address]) {
            units = allocated[_address];
        }
        tokensIssued = allocationToTokens(units);

        remaining = decreaseAllocation(_address, units);
    }

    /***************************
     * User Methods
     */

    // Convert allocation to tokens - 0 when factor not set
    function allocationToTokens(uint256 allocation) public view returns (uint256) {
        return (allocation * redemptionFactor) / REDEMPTION_FACTOR_MAGNITUDE;
    }

    // Convert token to allocation units per redemption factor.
    function tokensToAllocation(uint256 tokens) public view returns (uint256) {
        // Returns 0 when redemption factor is not set.
        if (redemptionFactor == 0) {
            return 0;
        }
        return (REDEMPTION_FACTOR_MAGNITUDE * tokens) / redemptionFactor;
    }

    // Allocated tokens for a wallet
    function allocatedTokens(address _address) public view returns (uint256) {
        return allocationToTokens(allocated[_address]);
    }

    /**
     * @dev Redeem a user's allocation and issue tokens.
     */
    function redeem() public whenNotPaused {
        // The values must be initialized: token, vault, redemption factor.
        require(tokenAddress != address(0) && tokenVaultAddress != address(0), "Token Setup Incomplete");
        require(redemptionFactor != 0, "Redemption factor not set");
        
        // Redemption is active when not paused and the timestamp is greater than notBefore
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= notBefore, "Pre-sale redemption has not started.");

        uint256 allocation = allocated[msg.sender];
        require(allocation > 0, "No Allocation to Redeem");

        // Calculate the number of tokens to deliver, consuming the entire allocation.
        uint256 tokensToTransfer = allocationToTokens(allocation);

        // Tokens are transferred from the token vault. Ensure the supply is adequate.
        // The transfer function does this check also
        uint256 tokenReserve = token.balanceOf(tokenVaultAddress);
        require(tokenReserve >= tokensToTransfer, "Insufficient supply");

        // Effect - reset the users allocation to 0
        allocated[msg.sender] = 0;

        // Send tokens from vault. sendTokens() reverts on failure
        tokenVault.sendTokens(tokenAddress, tokensToTransfer, msg.sender);

        // Emit Events
        emit AllocationDecreased(msg.sender, allocation, 0);
        emit Redeemed(msg.sender, allocation, tokensToTransfer);
    }

    /*******************************
     * Pausable Implementation     *
     *******************************/

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        _checkRole(role, _msgSender());
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

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



interface IVault {
    function withdrawTokens(address tokenAddress, uint256 amount) external;
    function sendTokens(address tokenAddress, uint256 amount, address destination) external;
}

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



interface IPresaleAllocation {

    
    /// @dev return allocation for the given address
    function allocated(address _address) external view returns (uint256 allocation);

    /// @dev increase the allocation for the given address
    function increaseAllocation(address _address, uint256 increase) external returns (uint256);

    /// @dev decrease the allocation for the given address
    function decreaseAllocation(address _address, uint256 decrease) external returns (uint256);

    /// @dev redeem the total allocation for tokens
    function redeem() external;

    /// @dev decrease allocation by number of tokens
    function decreaseAllocationByTokens(address _address, uint256 tokens) external returns (uint256 remaining, uint256 tokensIssued);

    /// @dev convert allocation units to tokens
    function allocationToTokens(uint256 allocation) external view returns (uint256);

    /// @dev convert tokens to allocation units
    function tokensToAllocation(uint256 tokens) external view returns (uint256);

    /// @dev return allocated tokens for address. 0 if redemption factor not set
    function allocatedTokens(address _address) external view returns (uint256);

    function redemptionFactor() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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