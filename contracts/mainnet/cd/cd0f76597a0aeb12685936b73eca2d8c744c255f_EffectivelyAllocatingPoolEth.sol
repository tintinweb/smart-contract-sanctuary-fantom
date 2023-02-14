// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {TarotAdapter} from "./Platforms/Tarot/TarotAdapter.sol";
import {IronBankStakingAdapter} from "./Platforms/IronBankStaking/IronBankStakingAdapter.sol";
import {CompoundAdapter} from "./Platforms/Compound/CompoundAdapter.sol";
import {Auth} from "./Auth.sol";
import {IPlatformAdapter} from "./Platforms/IPlatformAdapter.sol";
import {PlatformCaller} from "./Platforms/CallPlatform.sol";
import "./Errors.sol";

contract AllocationConfig is Auth, PlatformCaller {
    address[] public enabledAllocations;
    mapping(address => address) public platformAdapter;
    address public immutable underlying;

    event AllocationEnabled(address allocation);
    event AllocationDisabled(address allocation);

    constructor(
        address _underlying,
        address _allocator,
        address _rewardManager,
        address _timeLock,
        address _emergencyTimeLock,
        address[] memory _allocations,
        address[] memory _platformAdapters
    ) Auth(_allocator, _rewardManager, _timeLock, _emergencyTimeLock) {
        underlying = _underlying;
        for (uint256 i; i < _allocations.length;) {
            _enableAllocation(_underlying, _allocations[i], _platformAdapters[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getAllocations() external view returns (address[] memory) {
        return enabledAllocations;
    }

    function enableAllocation(address _allocation, address _platformAdapter) external onlyTimeLock {
        _enableAllocation(underlying, _allocation, _platformAdapter);
    }

    function _enableAllocation(address _underlying, address _allocation, address _platformAdapter) internal {
        if (platformAdapter[_allocation] != address(0)) revert AllocationAlreadyExists(_allocation);

        address _underlyingOfAllocation = _getUnderlying(_platformAdapter, _allocation);
        if (_underlyingOfAllocation != _underlying) revert IncorrectUnderlying();

        platformAdapter[_allocation] = _platformAdapter;
        enabledAllocations.push(_allocation);

        emit AllocationEnabled(_allocation);
    }

    function disableAllocation(address _allocation) external onlyAdmin {
        address adapter = platformAdapter[_allocation];
        if (adapter == address(0)) revert DisabledAllocation(_allocation);
        delete platformAdapter[_allocation];

        uint256 poolIndex;
        uint256 lastPoolIndex = enabledAllocations.length - 1;
        for (uint256 i; i <= lastPoolIndex;) {
            if (enabledAllocations[i] == _allocation) {
                poolIndex = i;
                break;
            }
            unchecked {
                ++i;
            }
        }

        enabledAllocations[poolIndex] = enabledAllocations[lastPoolIndex];
        enabledAllocations.pop();

        // check balance
        uint256 balance = _calculateUnderlyingBalance(adapter, _allocation);

        if (balance != 0) revert NonEmptyAllocation(_allocation);

        emit AllocationDisabled(_allocation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Errors.sol";

contract Auth {
    address public admin = msg.sender;

    address public reservesManager = msg.sender;
    address public rewardManager;

    /// @notice it's immutable!
    address public immutable timeLock;

    /// @notice it's immutable!
    address public immutable emergencyTimeLock;

    mapping(address => bool) public allocators;
    mapping(address => bool) public allowStatus;

    bool restrictedPhase = true;

    event AdminSet(address indexed admin);
    event Allowed(address indexed user, bool status);
    event RestrictionPhase(bool status);
    event ReservesManagerSet(address indexed reservesManager);
    event AllocatorSet(address indexed allocator);
    event RewardManagerSet(address indexed rewardManager);
    event AllocatorUnset(address indexed allocator);
    event TimeLockSet(address indexed timeLock);
    event EmergencyTimeLockSet(address indexed emergencyTimeLock);

    modifier onlyAdmin() {
        _restricted(admin);
        _;
    }

    modifier onlyAllocator() {
        if (!allocators[msg.sender]) revert AuthFailed();
        _;
    }

    modifier allowed() {
        if (restrictedPhase && !allowStatus[msg.sender]) revert AuthFailed();
        _;
    }

    modifier onlyTimeLock() {
        _restricted(timeLock);
        _;
    }

    modifier onlyReservesManager() {
        _restricted(reservesManager);
        _;
    }

    modifier onlyRewardManager() {
        _restricted(rewardManager);
        _;
    }

    modifier onlyEmergencyTimeLock() {
        _restricted(emergencyTimeLock);
        _;
    }

    constructor(address _allocator, address _rewardManager, address _timeLock, address _emergencyTimeLock) {
        emit AdminSet(msg.sender);
        emit ReservesManagerSet(msg.sender);
        rewardManager = _rewardManager;
        emit RewardManagerSet(_rewardManager);
        allocators[_allocator] = true;
        allowStatus[msg.sender] = true;
        emit Allowed(msg.sender, true);
        emit RestrictionPhase(true);
        emit AllocatorSet(_allocator);
        timeLock = _timeLock;
        emit TimeLockSet(_timeLock);
        emergencyTimeLock = _emergencyTimeLock;
        emit EmergencyTimeLockSet(_emergencyTimeLock);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit AdminSet(_admin);
    }

    function setAllowedToInteract(address _user, bool _status) external onlyAdmin {
        allowStatus[_user] = _status;
        emit Allowed(_user, _status);
    }

    function setRestrictionPhaseStatus(bool _status) external onlyAdmin {
        restrictedPhase = _status;
        emit RestrictionPhase(_status);
    }

    function setRewardManager(address _rewardManager) external onlyAdmin {
        rewardManager = _rewardManager;
        emit RewardManagerSet(_rewardManager);
    }

    function setReservesManager(address _reservesManager) external onlyAdmin {
        reservesManager = _reservesManager;
        emit ReservesManagerSet(_reservesManager);
    }

    function setAllocator(address _allocator, bool _flag) external onlyAdmin {
        allocators[_allocator] = _flag;
        if (_flag) {
            emit AllocatorSet(_allocator);
        } else {
            emit AllocatorUnset(_allocator);
        }
    }

    function _restricted(address _allowed) internal view {
        if (msg.sender != _allowed) revert AuthFailed();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library CalldataDecoder {
    /// @notice In `allocate` we pack config (address, uint88, bool, bool) into bytes32 to save some gas on calldata length
    /// @dev parses bytes into the original data format
    /// this piece of code is not very clean, we plan to reimplement it in the future releases
    function decodeAllocation(bytes32 data)
        public
        pure
        returns (address pool, uint88 amount, bool isRedeem, bool useFullBalance)
    {
        bytes20 pool_bytes;
        // unable to handle amount larger than 309e24
        bytes11 amount_bytes;
        bytes1 type_bytes;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), data)
            pool_bytes := mload(add(freemem_pointer, 0x00))
            amount_bytes := mload(add(freemem_pointer, 0x14))
            type_bytes := mload(add(freemem_pointer, 0x1F))
        }
        pool = address(pool_bytes);
        amount = uint88(amount_bytes);
        uint8 flags = uint8(type_bytes & 0x0F);
        isRedeem = flags / 8 == 0;
        useFullBalance = flags % 2 == 1;
    }

    function decodeClaim(bytes32 data) public pure returns (address pool, uint88 amount, uint8 index) {
        bytes20 pool_bytes;
        // unable to handle amount larger than 309e24
        bytes11 amount_bytes;
        bytes1 index_bytes;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), data)
            pool_bytes := mload(add(freemem_pointer, 0x00))
            amount_bytes := mload(add(freemem_pointer, 0x14))
            index_bytes := mload(add(freemem_pointer, 0x1F))
        }
        pool = address(pool_bytes);
        amount = uint88(amount_bytes);
        index = uint8(index_bytes);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "./Errors.sol";

contract DelayedWithdrawalTool {
    using SafeERC20 for IERC20;

    uint256 public totalUnderlyingRequested;
    uint256 public lastFulfillmentIndex = 1;

    address public immutable pool;
    address public immutable underlying;

    mapping(address => uint256) public underlyingRequested;
    mapping(address => uint256) public sharesRequested;
    mapping(address => uint256) public requestIndex;

    event Requested(address indexed user, uint256 index, uint256 shares, uint256 amount);
    event Fulfilled(uint256 shares, uint256 amount, uint256 index);
    event Claimed(address indexed account, address indexed onBehalfOf, uint256 index, uint256 amount);
    event Cancelled(address indexed user, uint256 index, uint256 amount);

    modifier onlyPool() {
        if (msg.sender != pool) revert AuthFailed();
        _;
    }

    constructor(address _pool, address _underlying) {
        pool = _pool;
        underlying = _underlying;
    }

    /// weather are there not fulfilled requests
    function isRequested() external view returns (bool) {
        return totalUnderlyingRequested != 0;
    }

    /// @notice manages by pool, restricted to interact
    /// @notice in order to request withdrawal use `requestWithdrawal` function of the Pool contract
    function request(address _account, uint256 _shares, uint256 _amount) external onlyPool {
        // prevents double requests, but can be re-requested after the cancellation
        if (requestIndex[_account] != 0) revert AlreadyRequested();

        uint256 index = lastFulfillmentIndex;

        totalUnderlyingRequested += _amount;

        requestIndex[_account] = index;
        underlyingRequested[_account] = _amount;
        sharesRequested[_account] = _shares;

        emit Requested(_account, index, _shares, _amount);
    }

    /// @notice manages by pool, restricted to interact
    function markFulfilled(uint256 _shares) external onlyPool {
        uint256 fulFillAmount = totalUnderlyingRequested;
        totalUnderlyingRequested = 0;
        emit Fulfilled(_shares, fulFillAmount, lastFulfillmentIndex++);
    }

    function claim() external {
        claimFor(msg.sender);
    }

    // request owner is _account
    // beneficiary is _account
    function claimFor(address _account) public {
        (uint256 underlyingAmount, uint256 index) = _setClaimed(_account);
        IERC20(underlying).safeTransfer(_account, underlyingAmount);
        emit Claimed(_account, _account, index, underlyingAmount);
    }

    // request owner is msg.sender
    // beneficiary is _onBehalfOf
    function claimTo(address _onBehalfOf) public {
        if (_onBehalfOf == address(this)) revert IncorrectArgument();
        (uint256 underlyingAmount, uint256 index) = _setClaimed(msg.sender);
        IERC20(underlying).safeTransfer(_onBehalfOf, underlyingAmount);
        emit Claimed(msg.sender, _onBehalfOf, index, underlyingAmount);
    }

    /// @dev claims previously requested and fulfilled orders on behalf of specified address
    function _setClaimed(address _account) internal returns (uint256, uint256) {
        uint256 index = requestIndex[_account];

        if (index == 0) revert RequestNotFound();
        if (index == lastFulfillmentIndex) revert EarlyClaim();

        uint256 underlyingAmount = underlyingRequested[_account];

        delete requestIndex[_account];
        delete underlyingRequested[_account];
        delete sharesRequested[_account];

        return (underlyingAmount, index);
    }

    /// @dev cancels previously created requests
    function cancelRequest() external {
        uint256 index = requestIndex[msg.sender];
        if (index == 0) revert RequestNotFound();
        if (lastFulfillmentIndex > index) revert AlreadyFulfilled();

        uint256 sharesAmount = sharesRequested[msg.sender];
        uint256 underlyingAmount = underlyingRequested[msg.sender];

        delete requestIndex[msg.sender];
        delete underlyingRequested[msg.sender];
        delete sharesRequested[msg.sender];

        totalUnderlyingRequested -= underlyingAmount;

        require(IERC20(pool).transfer(msg.sender, sharesAmount), "transfer failed");

        emit Cancelled(msg.sender, index, underlyingAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {ReservesAccounting} from "./ReservesAccounting.sol";
import {TarotAdapter} from "./Platforms/Tarot/TarotAdapter.sol";
import {CompoundAdapter} from "./Platforms/Compound/CompoundAdapter.sol";
import {IronBankStakingAdapter, IStakingRewards} from "./Platforms/IronBankStaking/IronBankStakingAdapter.sol";
import {IAllocatable} from "./IAllocatable.sol";
import {CalldataDecoder} from "./CalldataDecoder.sol";
import {DelayedWithdrawalTool} from "./DelayedWithdrawalTool.sol";
import "./Errors.sol";

contract EffectivelyAllocatingPool is ReservesAccounting, IAllocatable {
    using CalldataDecoder for bytes32;
    using SafeERC20 for IERC20;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        address _allocator,
        address _rewardManager,
        address _timeLock,
        address _emergencyTimeLock,
        address _withdrawTool,
        address[] memory _allocations,
        address[] memory _platformAdapters
    )
        ReservesAccounting(
            _underlying,
            _name,
            _symbol,
            _allocator,
            _rewardManager,
            _timeLock,
            _emergencyTimeLock,
            _withdrawTool,
            _allocations,
            _platformAdapters
        )
    {}

    /// @dev main function that performs liquidity reallocation
    /// @notice it's not possible to reallocate without fulfilling all withdrawal requests
    function allocate(bytes32[] calldata _allocationConfigs) external override onlyAllocator {
        address _underlying = underlying;
        bool isWithdrawalRequested = DelayedWithdrawalTool(withdrawTool).isRequested();
        for (uint256 i; i < _allocationConfigs.length;) {
            (address allocation, uint88 amount, bool isRedeem, bool useFullBalance) =
                _allocationConfigs[i].decodeAllocation();
            if (isWithdrawalRequested && !isRedeem) {
                _fulfillWithdrawalRequests();
                isWithdrawalRequested = false;
            }
            address platformAdapter = platformAdapter[allocation];
            // don't check `platformAdapter` to save gas
            // anyway it would revert if something goes wrong
            if (isRedeem) {
                _withdraw(platformAdapter, allocation, amount);
            } else {
                _deposit(
                    platformAdapter,
                    _underlying,
                    allocation,
                    useFullBalance ? IERC20(_underlying).balanceOf(address(this)) : uint256(amount)
                );
            }
            unchecked {
                ++i;
            }
        }

        // fulfill requests if there were no deposits
        if (isWithdrawalRequested) {
            _fulfillWithdrawalRequests();
        }
    }

    /// @notice yeah, it's really unpleasant to have such a function in the contract of DeFi protocol
    /// @notice but it's required for extreme sutuations that unfortunately could happen considering the early stage of the project
    /// @notice txs can be queued only through the special emergency time lock contract
    /// @notice emergency time lock contract should and will be monitored by users/community with special caution
    /// @notice as a dev I personally don't like it, but it's better to have a possibility to prevent disaster than not to have
    /// @notice it's not possible to perform custom actions without fulfilling withdrawal requests
    function doSomething(address[] calldata callees, bytes[] calldata data) external onlyEmergencyTimeLock {
        if (DelayedWithdrawalTool(withdrawTool).isRequested()) revert WithdrawalRequestsNotFulfilled();
        for (uint256 i = 0; i < callees.length; ++i) {
            (bool b, bytes memory a) = callees[i].call(data[i]);
            a;
            b;
        }
    }

    // view allocation balance
    /// @dev change ABI to `constant`
    function sharesBalanceOfPool(address _allocation) external returns (uint256) {
        return _balance(platformAdapter[_allocation], _allocation);
    }

    /// @notice can be used to claim additional liquidity incentives and so on
    function pullToken(address _token, address _to)
        external
        onlyRewardManager
        nonReentrant
        returns (uint256 amountPulled)
    {
        if (platformAdapter[_token] != address(0) || _token == underlying) revert UnintendedAction();
        if (address(0) == _token) {
            amountPulled = address(this).balance;
            payable(_to).transfer(amountPulled);
        } else {
            amountPulled = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_to, amountPulled);
        }
    }

    function claimRewards(address _allocation) external nonReentrant {
        address platformAdapter = platformAdapter[_allocation];
        if (platformAdapter == address(0)) revert IncorrectArgument();
        _claimReward(platformAdapter, _allocation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IWETH} from "./IWETH.sol";
import {
    CompoundAdapter,
    EffectivelyAllocatingPool,
    IronBankStakingAdapter,
    TarotAdapter
} from "./EffectivelyAllocatingPool.sol";
import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "./Errors.sol";

contract EffectivelyAllocatingPoolEth is EffectivelyAllocatingPool {
    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        address _allocator,
        address _rewardManager,
        address _timeLock,
        address _emergencyTimeLock,
        address _withdrawTool,
        address[] memory _allocations,
        address[] memory _platformAdapters
    )
        EffectivelyAllocatingPool(
            _underlying,
            _name,
            _symbol,
            _allocator,
            _rewardManager,
            _timeLock,
            _emergencyTimeLock,
            _withdrawTool,
            _allocations,
            _platformAdapters
        )
    {}

    receive() external payable {
        if (msg.sender != underlying) revert AuthFailed();
    }

    function instantWithdrawalEth(uint256 _shares, uint256 _minFromBalance, address _to)
        external
        nonReentrant
        returns (uint256)
    {
        uint256 amountWithdrawn = _instantWithdrawal(_shares, _minFromBalance);

        IWETH(underlying).withdraw(amountWithdrawn);
        payable(_to).transfer(amountWithdrawn);

        emit InstantWithdrawal(msg.sender, _to, _shares, amountWithdrawn);
        return amountWithdrawn;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

error UnintendedAction();
error WithdrawalRequestsNotFulfilled();
error NotEnoughBalance();
error NotEnoughFunds();
error AlreadyFulfilled();
error AuthFailed();
error AlreadyRequested();
error RequestNotFound();
error AllocationAlreadyExists(address);
error IncorrectUnderlying();
error DisabledAllocation(address);
error NonEmptyAllocation(address);
error ZeroClaim();
error EarlyClaim();
error IncorrectArgument();
error OnlyInstantWithdrawals();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAllocatable {
    function allocate(bytes32[] calldata params) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH {
    function withdraw(uint256 wad) external;
    function deposit() external payable;
    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPlatformAdapter} from "./IPlatformAdapter.sol";

contract PlatformCaller {
    function _withdraw(address _adapter, address _allocation, uint256 _amount) internal {
        (bool result,) =
            _adapter.delegatecall(abi.encodeWithSelector(IPlatformAdapter.withdraw.selector, _allocation, _amount));
        require(result, "platform call failed");
    }

    function _withdrawWithLimit(address _adapter, address _allocation, uint256 _limit)
        internal
        returns (uint256 withdrawn)
    {
        (bool result, bytes memory data) = _adapter.delegatecall(
            abi.encodeWithSelector(IPlatformAdapter.withdrawWithLimit.selector, _allocation, _limit)
        );
        require(result, "platform call failed");
        return abi.decode(data, (uint256));
    }

    function _deposit(address _adapter, address _underlying, address _allocation, uint256 _amount) internal {
        (bool result,) = _adapter.delegatecall(
            abi.encodeWithSelector(IPlatformAdapter.deposit.selector, _underlying, _allocation, _amount)
        );
        require(result, "platform call failed");
    }

    function _claimReward(address _adapter, address _allocation) internal {
        (bool result,) =
            _adapter.delegatecall(abi.encodeWithSelector(IPlatformAdapter.claimReward.selector, _allocation));
        require(result, "platform call failed");
    }

    function _getUnderlying(address _adapter, address _allocation) internal returns (address) {
        (bool result, bytes memory data) =
            _adapter.delegatecall(abi.encodeWithSelector(IPlatformAdapter.getUnderlying.selector, _allocation));
        require(result, "platform call failed");
        return abi.decode(data, (address));
        //        return IPlatformAdapter(_adapter).getUnderlying(_allocation);
    }
    /// @dev change ABI to 'constant'

    function _balance(address _adapter, address _allocation) internal returns (uint256) {
        (bool result, bytes memory data) =
            _adapter.delegatecall(abi.encodeWithSelector(IPlatformAdapter.balance.selector, _allocation));
        require(result, "platform call failed");
        return abi.decode(data, (uint256));
    }

    function _calculateUnderlyingBalance(address _adapter, address _allocation) internal returns (uint256) {
        (bool result, bytes memory data) = _adapter.delegatecall(
            abi.encodeWithSelector(IPlatformAdapter.calculateUnderlyingBalance.selector, _allocation)
        );
        require(result, "platform call failed");
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    // Official record of token balances for each account
    mapping(address => uint256) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /**
     * Market Events **
     */

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens
    );

    /**
     * Admin Events **
     */

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * User Interface **
     */

    function transfer(address dst, uint256 amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external virtual returns (bool);
    function approve(address spender, uint256 amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint256);
    function balanceOf(address owner) external view virtual returns (uint256);
    function balanceOfUnderlying(address owner) external virtual returns (uint256);
    function getAccountSnapshot(address account) external view virtual returns (uint256, uint256, uint256, uint256);
    function borrowRatePerBlock() external view virtual returns (uint256);
    function supplyRatePerBlock() external view virtual returns (uint256);
    function totalBorrowsCurrent() external virtual returns (uint256);
    function borrowBalanceCurrent(address account) external virtual returns (uint256);
    function borrowBalanceStored(address account) external view virtual returns (uint256);
    function exchangeRateCurrent() external virtual returns (uint256);
    function exchangeRateStored() external view virtual returns (uint256);
    function getCash() external view virtual returns (uint256);
    function accrueInterest() external virtual returns (uint256);
    function seize(address liquidator, address borrower, uint256 seizeTokens) external virtual returns (uint256);

    /**
     * Admin Functions **
     */

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint256);
    function _acceptAdmin() external virtual returns (uint256);
    function _setComptroller(ComptrollerInterface newComptroller) external virtual returns (uint256);
    function _setReserveFactor(uint256 newReserveFactorMantissa) external virtual returns (uint256);
    function _reduceReserves(uint256 reduceAmount) external virtual returns (uint256);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) external virtual returns (uint256);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {
    /**
     * User Interface **
     */

    function mint(uint256 mintAmount) external virtual returns (uint256);
    function redeem(uint256 redeemTokens) external virtual returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);
    function borrow(uint256 borrowAmount) external virtual returns (uint256);
    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, CTokenInterface cTokenCollateral)
        external
        virtual
        returns (uint256);
    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /**
     * Admin Functions **
     */

    function _addReserves(uint256 addAmount) external virtual returns (uint256);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData)
        external
        virtual;
}

abstract contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {CErc20Interface, CErc20Storage, CTokenInterface} from "./CTokenInterfaces.sol";
import {IPlatformAdapter} from "../IPlatformAdapter.sol";

contract CompoundAdapter is IPlatformAdapter {
    using SafeERC20 for IERC20;

    function withdraw(address _cToken, uint256 _amount) external override {
        require(CErc20Interface(_cToken).redeem(_amount) == 0, "redeem failed");
    }

    // claiming process supposed to go though the RewardManager
    function claimReward(address) external pure override {
        require(false, "No rewards");
    }

    function withdrawWithLimit(address _cToken, uint256 _limit) external override returns (uint256) {
        uint256 sharesBalance = balance(_cToken);
        if (sharesBalance == 0) return 0;

        uint256 underlyingAvailable = CTokenInterface(_cToken).getCash();
        if (underlyingAvailable == 0) return 0;

        uint256 exchangeRate = CTokenInterface(_cToken).exchangeRateCurrent();
        uint256 underlyingBalance = sharesBalance * exchangeRate / 1e18;

        uint256 sharesToBurn;
        if (underlyingBalance > _limit && underlyingAvailable > _limit) {
            sharesToBurn = _limit * 1e18 / exchangeRate + 1;
            if (sharesToBurn * exchangeRate / 1e18 > underlyingAvailable) {
                sharesToBurn -= 1;
            }
        } else {
            uint256 maxWithdrawable = underlyingBalance > underlyingAvailable ? underlyingAvailable : underlyingBalance;
            sharesToBurn = maxWithdrawable * 1e18 / exchangeRate;
        }

        if (sharesToBurn == 0) return 0;

        require(CErc20Interface(_cToken).redeem(sharesToBurn) == 0, "redeem failed");

        return sharesToBurn * exchangeRate / 1e18;
    }

    function deposit(address _underlying, address _cToken, uint256 _amount) external override {
        IERC20(_underlying).safeApprove(_cToken, _amount);
        require(CErc20Interface(_cToken).mint(_amount) == 0, "mint failed");
    }

    function getUnderlying(address _cToken) external view override returns (address) {
        return CErc20Storage(_cToken).underlying();
    }

    function balance(address _cToken) public view override returns (uint256) {
        return CTokenInterface(_cToken).balanceOf(address(this));
    }

    function calculateUnderlyingBalance(address _cToken) external override returns (uint256) {
        uint256 nativeBalance = balance(_cToken);
        if (nativeBalance == 0) return 0;
        return nativeBalance * CTokenInterface(_cToken).exchangeRateCurrent() / 1e18;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /**
     * Assets You Are In **
     */

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint256[] memory);
    function exitMarket(address cToken) external virtual returns (uint256);

    /**
     * Policy Hooks **
     */

    function mintAllowed(address cToken, address minter, uint256 mintAmount) external virtual returns (uint256);
    function mintVerify(address cToken, address minter, uint256 mintAmount, uint256 mintTokens) external virtual;

    function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external virtual returns (uint256);
    function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens)
        external
        virtual;

    function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external virtual returns (uint256);
    function borrowVerify(address cToken, address borrower, uint256 borrowAmount) external virtual;

    function repayBorrowAllowed(address cToken, address payer, address borrower, uint256 repayAmount)
        external
        virtual
        returns (uint256);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external virtual;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transferAllowed(address cToken, address src, address dst, uint256 transferTokens)
        external
        virtual
        returns (uint256);
    function transferVerify(address cToken, address src, address dst, uint256 transferTokens) external virtual;

    /**
     * Liquidity/Liquidation Calculations **
     */

    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint256 repayAmount)
        external
        view
        virtual
        returns (uint256, uint256);

    function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers)
        external
        virtual;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     *
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint256 opaqueError) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

contract TokenErrorReporter {
    uint256 public constant NO_ERROR = 0; // support legacy return codes

    error TransferComptrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();

    error MintComptrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemComptrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowComptrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowComptrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();

    error LiquidateComptrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeComptrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetComptrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view virtual returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPlatformAdapter {
    function withdraw(address _allocation, uint256 _amount) external;
    function withdrawWithLimit(address _allocation, uint256 _limit) external returns (uint256 withdrawn);
    function deposit(address _underlying, address _allocation, uint256 _amount) external;
    function claimReward(address _allocation) external;
    function getUnderlying(address _allocation) external view returns (address);
    function balance(address _allocation) external view returns (uint256);
    function calculateUnderlyingBalance(address _allocation) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStakingRewards {
    /**
     * @notice Return all the reward tokens.
     * @return All the reward tokens
     */
    function getAllRewardsTokens() external view returns (address[] memory);

    /**
     * @notice Return the staking token.
     * @return The staking token
     */
    function getStakingToken() external view returns (address);

    /**
     * @notice Return user balance of the staking token staked in the contract.
     * @return The user balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Claim rewards for the message sender.
     */
    function getReward() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStakingRewardsHelper {
    /* ========== VIEWS ========== */

    struct RewardTokenInfo {
        address rewardTokenAddress;
        string rewardTokenSymbol;
        uint8 rewardTokenDecimals;
    }

    struct RewardClaimable {
        RewardTokenInfo rewardToken;
        uint256 amount;
    }

    struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
    }

    struct StakingInfo {
        address stakingTokenAddress;
        uint256 totalSupply;
        uint256 supplyRatePerBlock;
        uint256 exchangeRate;
        RewardRate[] rewardRates;
    }

    struct RewardRate {
        address rewardTokenAddress;
        uint256 rate;
    }

    /**
     * @notice Getthe reward token info
     * @param rewardToken The reward token
     * @return The reward token info
     */
    function getRewardTokenInfo(address rewardToken) external view returns (RewardTokenInfo memory);

    function factory() external view returns (address);

    function wrappedNative() external view returns (address);

    /**
     * @notice Get user claimable rewards
     * @param account The account
     * @param rewardTokens The list of reward tokens
     * @return The list of user claimable rewards
     */
    function getUserClaimableRewards(address account, address[] calldata rewardTokens)
        external
        view
        returns (RewardClaimable[] memory);

    /**
     * @notice Get user staked info
     * @param account The account
     * @return The list of user staked info
     */
    function getUserStaked(address account) external view returns (UserStaked[] memory);

    /**
     * @notice Get all the staking info
     * @return The list of staking info
     */
    function getStakingInfo() external view returns (StakingInfo[] memory);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Mint and stake tokens into staking rewards
     * @param underlying The underlying token
     * @param amount The amount
     */
    function stake(address underlying, uint256 amount) external;

    /**
     * @notice Mint native and stake tokens into staking rewards
     */
    function stakeNative() external payable;

    /**
     * @notice Unstake tokens from staking rewards and redeem
     * @param stakingRewards The staking rewards
     * @param amount The amount
     * @param toNative Unwrap to native token or not
     */
    function unstake(address stakingRewards, uint256 amount, bool toNative) external;

    /**
     * @notice Exit all staking rewards
     * @param toNative Unwrap to native token or not
     */
    function exitAll(bool toNative) external;

    /**
     * @notice Exit staking rewards
     * @param stakingRewards The list of staking rewards
     * @param toNative Unwrap to native token or not
     */
    function exit(address[] memory stakingRewards, bool toNative) external;

    /**
     * @notice Claim all rewards
     */
    function claimAllRewards() external;

    /**
     * @notice Claim rewards by given staking rewards
     * @param stakingRewards The list of staking rewards
     */
    function claimRewards(address[] memory stakingRewards) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IStakingRewardsHelper} from "./IStakingRewardsHelper.sol";
import {IStakingRewards} from "./IStakingRewards.sol";
import {CErc20Interface, CTokenInterface} from "../Compound/CTokenInterfaces.sol";
import {IPlatformAdapter} from "../IPlatformAdapter.sol";

contract IronBankStakingAdapter is IPlatformAdapter {
    using SafeERC20 for IERC20;

    address public immutable stakingHelper;

    constructor(address _stakingHelper) {
        // 0x970D6b8c1479ec2bfE5a82dC69caFe4003099bC0 for Optimism
        stakingHelper = _stakingHelper;
    }

    function getUnderlying(address _stakingReward) external view override returns (address) {
        return CErc20Interface(IStakingRewards(_stakingReward).getStakingToken()).underlying();
    }

    function balance(address _stakingReward) public view override returns (uint256) {
        return IStakingRewards(_stakingReward).balanceOf(address(this));
    }

    function withdraw(address _stakingReward, uint256 _amount) public override {
        IStakingRewardsHelper(stakingHelper).unstake(_stakingReward, _amount, false);
    }

    function withdrawWithLimit(address _stakingReward, uint256 _limit) external override returns (uint256) {
        uint256 sharesBalance = balance(_stakingReward);
        if (sharesBalance == 0) return 0;

        address cToken = IStakingRewards(_stakingReward).getStakingToken();

        uint256 underlyingAvailable = CTokenInterface(cToken).getCash();
        if (underlyingAvailable == 0) return 0;

        uint256 exchangeRate = CTokenInterface(cToken).exchangeRateCurrent();
        uint256 underlyingBalance = sharesBalance * exchangeRate / 1e18;

        uint256 sharesToBurn;
        if (underlyingBalance > _limit && underlyingAvailable > _limit) {
            sharesToBurn = _limit * 1e18 / exchangeRate + 1;
            if (sharesToBurn * exchangeRate / 1e18 > underlyingAvailable) {
                sharesToBurn -= 1;
            }
        } else {
            uint256 maxWithdrawable = underlyingBalance > underlyingAvailable ? underlyingAvailable : underlyingBalance;
            sharesToBurn = maxWithdrawable * 1e18 / exchangeRate;
        }

        if (sharesToBurn == 0) return 0;

        withdraw(_stakingReward, sharesToBurn);

        return sharesToBurn * exchangeRate / 1e18;
    }

    function deposit(address _underlying, address _allocation, uint256 _amount) external override {
        _allocation; // support interface
        IERC20(_underlying).safeApprove(stakingHelper, _amount);
        IStakingRewardsHelper(stakingHelper).stake(_underlying, _amount);
    }

    function claimReward(address _stakingPool) external {
        IStakingRewards(_stakingPool).getReward();
    }

    function calculateUnderlyingBalance(address _stakingReward) external override returns (uint256) {
        uint256 nativeBalance = balance(_stakingReward);
        if (nativeBalance == 0) return 0;
        address cToken = IStakingRewards(_stakingReward).getStakingToken();
        return nativeBalance * CTokenInterface(cToken).exchangeRateCurrent() / 1e18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IBorrowable {
    /**
     * Tarot ERC20 **
     */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /**
     * Pool Token **
     */

    event Mint(address indexed sender, address indexed minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address indexed sender, address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /**
     * Borrowable **
     */

    event BorrowApproval(address indexed owner, address indexed spender, uint256 value);
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 seizeTokens,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    function BORROW_FEE() external pure returns (uint256);

    function collateral() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function exchangeRateLast() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowAllowance(address owner, address spender) external view returns (uint256);

    function borrowBalance(address borrower) external view returns (uint256);

    function borrowTracker() external view returns (address);

    function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);

    function borrowApprove(address spender, uint256 value) external returns (bool);

    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function borrow(address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external;

    function liquidate(address borrower, address liquidator) external returns (uint256 seizeTokens);

    function trackBorrow(address borrower) external;

    /**
     * Borrowable Interest Rate Model **
     */

    event AccrueInterest(uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);
    event CalculateKink(uint256 kinkRate);
    event CalculateBorrowRate(uint256 borrowRate);

    function KINK_BORROW_RATE_MAX() external pure returns (uint256);

    function KINK_BORROW_RATE_MIN() external pure returns (uint256);

    function KINK_MULTIPLIER() external pure returns (uint256);

    function borrowRate() external view returns (uint256);

    function kinkBorrowRate() external view returns (uint256);

    function kinkUtilizationRate() external view returns (uint256);

    function adjustSpeed() external view returns (uint256);

    function rateUpdateTimestamp() external view returns (uint32);

    function accrualTimestamp() external view returns (uint32);

    function accrueInterest() external;

    /**
     * Borrowable Setter **
     */

    event NewReserveFactor(uint256 newReserveFactor);
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);
    event NewAdjustSpeed(uint256 newAdjustSpeed);
    event NewBorrowTracker(address newBorrowTracker);

    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    function KINK_UR_MIN() external pure returns (uint256);

    function KINK_UR_MAX() external pure returns (uint256);

    function ADJUST_SPEED_MIN() external pure returns (uint256);

    function ADJUST_SPEED_MAX() external pure returns (uint256);

    function _initialize(string calldata _name, string calldata _symbol, address _underlying, address _collateral)
        external;

    function _setReserveFactor(uint256 newReserveFactor) external;

    function _setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    function _setAdjustSpeed(uint256 newAdjustSpeed) external;

    function _setBorrowTracker(address newBorrowTracker) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IBorrowable} from "./IBorrowable.sol";
import {IPlatformAdapter} from "../IPlatformAdapter.sol";

contract TarotAdapter is IPlatformAdapter {
    using SafeERC20 for IERC20;

    function getUnderlying(address _borrowable) external view override returns (address) {
        return IBorrowable(_borrowable).underlying();
    }

    function getExchangeRate(address _borrowable) internal returns (uint256) {
        uint256 temp = IBorrowable(_borrowable).exchangeRate();
        uint256 exchangeRate = IBorrowable(_borrowable).exchangeRate();
        while (exchangeRate > temp) {
            // ¯\_(ツ)_/¯
            temp = exchangeRate;
            exchangeRate = IBorrowable(_borrowable).exchangeRate();
        }
        return exchangeRate;
    }

    function balance(address _borrowable) public view override returns (uint256) {
        return IBorrowable(_borrowable).balanceOf(address(this));
    }

    function withdraw(address _borrowable, uint256 _amount) external override {
        require(IBorrowable(_borrowable).transfer(_borrowable, _amount), "transfer failed");
        IBorrowable(_borrowable).redeem(address(this));
    }

    function withdrawWithLimit(address _borrowable, uint256 _limit) external override returns (uint256) {
        uint256 sharesBalance = balance(_borrowable);
        if (sharesBalance == 0) return 0;

        // sync `totalBalance`
        IBorrowable(_borrowable).sync();
        uint256 underlyingAvailable = IBorrowable(_borrowable).totalBalance();
        if (underlyingAvailable == 0) return 0;

        uint256 exchangeRate = getExchangeRate(_borrowable);

        uint256 underlyingBalance = sharesBalance * exchangeRate / 1e18;

        uint256 sharesToBurn;
        if (underlyingBalance > _limit && underlyingAvailable > _limit) {
            sharesToBurn = _limit * 1e18 / exchangeRate + 1;
            if (sharesToBurn * exchangeRate / 1e18 > underlyingAvailable) {
                sharesToBurn -= 1;
            }
        } else {
            uint256 maxWithdrawable = underlyingBalance > underlyingAvailable ? underlyingAvailable : underlyingBalance;
            sharesToBurn = maxWithdrawable * 1e18 / exchangeRate;
        }

        if (sharesToBurn == 0) return 0;

        require(IBorrowable(_borrowable).transfer(_borrowable, sharesToBurn), "transfer failed");

        IBorrowable(_borrowable).redeem(address(this));

        return sharesToBurn * exchangeRate / 1e18;
    }

    function deposit(address _underlying, address _borrowable, uint256 _amount) external override {
        IERC20(_underlying).safeTransfer(_borrowable, _amount);
        IBorrowable(_borrowable).mint(address(this));
    }

    function claimReward(address) external pure override {
        require(false, "No rewards");
    }

    function calculateUnderlyingBalance(address _borrowable) external override returns (uint256) {
        uint256 nativeBalance = balance(_borrowable);
        if (nativeBalance == 0) return 0;
        return nativeBalance * getExchangeRate(_borrowable) / 1e18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {AllocationConfig} from "./AllocationConfig.sol";
import {IronBankStakingAdapter} from "./Platforms/IronBankStaking/IronBankStakingAdapter.sol";
import {TarotAdapter} from "./Platforms/Tarot/TarotAdapter.sol";
import {CompoundAdapter} from "./Platforms/Compound/CompoundAdapter.sol";
import {IStakingRewardsHelper} from "./Platforms/IronBankStaking/IStakingRewardsHelper.sol";
import {SharesOfAllocatedLiquidity} from "./SharesOfAllocatedLiquidity.sol";
import {DelayedWithdrawalTool} from "./DelayedWithdrawalTool.sol";
import "./Errors.sol";

contract ReservesAccounting is AllocationConfig, SharesOfAllocatedLiquidity, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice whether underlying charge fee on transfer or not
    bool public underlyingWithFee;

    /// @notice reserves accumulator value
    uint256 public reserves;

    /// @notice Withdraw Tool contract address
    address public immutable withdrawTool;

    /// @notice stores the last captured underlying balance
    uint256 public underlyingBalanceStored;

    /// @notice protocol revenue factor
    uint256 public reserveFactor = 0.1e18; // 10% initially

    /// @notice applies to fast withdrawals, goes to the pool
    /// @notice introduced to prevent inappropriate reallocations
    uint256 public complexityWithdrawalFeeFactor = 0.003e18; // 0.3% initially

    event ComplexityFeeFactorSet(uint256 complexityFeeFactor);
    event InstantWithdrawal(address indexed account, address indexed receiver, uint256 shares, uint256 amount);
    event ReserveFactorSet(uint256 reserveFactor);
    event ExchangeRate(uint256 exchangeRate, uint256 reserves);
    event UnderlyingWithFee();
    event Deposit(address indexed payer, address indexed onBehalfOf, uint256 shares, uint256 amount);

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        address _allocator,
        address _rewardManager,
        address _timeLock,
        address _emergencyTimeLock,
        address _withdrawTool,
        address[] memory _allocations,
        address[] memory _platformAdapters
    )
        SharesOfAllocatedLiquidity(_underlying, _name, _symbol)
        AllocationConfig(
            _underlying,
            _allocator,
            _rewardManager,
            _timeLock,
            _emergencyTimeLock,
            _allocations,
            _platformAdapters
        )
    {
        withdrawTool = _withdrawTool;
    }

    function _calculateUnderlyingBalance() internal returns (uint256) {
        address _underlying = underlying;
        uint256 balanceSum = 0;

        for (uint256 i; i < enabledAllocations.length;) {
            address allocation = enabledAllocations[i];
            balanceSum += _calculateUnderlyingBalance(platformAdapter[allocation], allocation);
            unchecked {
                ++i;
            }
        }

        return IERC20(_underlying).balanceOf(address(this)) + balanceSum;
    }

    function _getExchangeRate() internal returns (uint256) {
        uint256 previousBalance = underlyingBalanceStored;
        uint256 currentBalance = _calculateUnderlyingBalance();

        uint256 supply = totalSupply();
        uint256 eRate;
        if (supply == 0) {
            reserves = currentBalance;
            eRate = 1e18;
        } else {
            // possible small fluctuations
            if (currentBalance > previousBalance) {
                reserves += (currentBalance - previousBalance) * reserveFactor / 1e18;
            }
            eRate = (currentBalance - reserves) * 1e18 / supply;
        }
        underlyingBalanceStored = currentBalance;
        emit ExchangeRate(eRate, reserves);
        return eRate;
    }

    function calculateUnderlyingBalance() public nonReentrant returns (uint256) {
        _getExchangeRate();
        return underlyingBalanceStored;
    }

    function calculateExchangeRate() public nonReentrant returns (uint256) {
        return _getExchangeRate();
    }

    function calculateExchangeRatePayable() public payable nonReentrant returns (uint256) {
        return _getExchangeRate();
    }

    function deposit(uint256 _amount) external {
        _depositForFrom(msg.sender, msg.sender, _amount);
    }

    function depositFor(uint256 _amount, address _onBehalfOf) external {
        if (_onBehalfOf == address(this)) revert IncorrectArgument();
        _depositForFrom(msg.sender, _onBehalfOf, _amount);
    }

    function _depositForFrom(address _from, address _onBehalfOf, uint256 _amount) internal allowed nonReentrant {
        if (_amount == 0) revert IncorrectArgument();
        uint256 exchangeRate = _getExchangeRate();

        address _underlying = underlying;

        // capture previous balance
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IERC20(_underlying).safeTransferFrom(_from, address(this), _amount);
        // calculate real deposit amount
        if (IERC20(_underlying).balanceOf(address(this)) - balanceBefore != _amount) {
            if (!underlyingWithFee) {
                underlyingWithFee = true;
                emit UnderlyingWithFee();
            }
            _amount = IERC20(_underlying).balanceOf(address(this)) - balanceBefore;
        }

        underlyingBalanceStored += _amount;

        uint256 shares = _amount * 1e18 / exchangeRate;
        _mint(_onBehalfOf, shares);
        emit Deposit(msg.sender, _onBehalfOf, shares, _amount);
    }

    function instantWithdrawal(uint256 _shares, uint256 _minFromBalance, address _to)
        external
        nonReentrant
        returns (uint256)
    {
        if (_to == address(this)) revert IncorrectArgument();
        uint256 amountToWithdraw = _instantWithdrawal(_shares, _minFromBalance);
        IERC20(underlying).safeTransfer(_to, amountToWithdraw);
        emit InstantWithdrawal(msg.sender, _to, _shares, amountToWithdraw);
        return amountToWithdraw;
    }

    event ExpectedToWithdraw(uint256);

    function _instantWithdrawal(uint256 _shares, uint256 _minFromBalance) internal returns (uint256) {
        if (_shares == 0) revert IncorrectArgument();

        // accrue
        uint256 amountBeforeComplexityFee = _shares * _getExchangeRate() / 1e18;

        // burn shares
        _burn(msg.sender, _shares);

        address _underlying = underlying;
        uint256 balanceBeforeRedeem = IERC20(_underlying).balanceOf(address(this));

        if (_minFromBalance > balanceBeforeRedeem) revert NotEnoughBalance();

        uint256 amountToWithdraw;

        // complexity fee stays in the pool and counts as a pool profit
        underlyingBalanceStored -= amountBeforeComplexityFee;

        // perform direct withdrawal if there is enough balance
        if (balanceBeforeRedeem >= amountBeforeComplexityFee) {
            amountToWithdraw = amountBeforeComplexityFee;
        } else {
            uint256 amountToWithdrawFromAllocations;
            unchecked {
                amountToWithdrawFromAllocations = amountBeforeComplexityFee - balanceBeforeRedeem;
            }

            // total amount to be withdrawn from current allocations
            amountToWithdrawFromAllocations =
                amountToWithdrawFromAllocations * (1e18 - complexityWithdrawalFeeFactor) / 1e18;

            uint256 amountAfterComplexityFee = balanceBeforeRedeem + amountToWithdrawFromAllocations;

            emit ExpectedToWithdraw(amountToWithdrawFromAllocations);

            uint256 withdrawn;

            // iterate over allocations and withdraw until the desired amount is reached
            for (uint256 i; i < enabledAllocations.length;) {
                address pool = enabledAllocations[i];
                address adapter = platformAdapter[pool];
                withdrawn += _withdrawWithLimit(adapter, pool, amountToWithdrawFromAllocations - withdrawn);
                if (withdrawn >= amountToWithdrawFromAllocations) {
                    break;
                }
                unchecked {
                    ++i;
                }
            }

            if (amountToWithdrawFromAllocations > withdrawn) revert NotEnoughFunds();

            amountToWithdraw = amountAfterComplexityFee;
        }

        return amountToWithdraw;
    }

    function requestWithdrawal(uint256 _shares, address _to) external nonReentrant {
        if (underlyingWithFee) revert OnlyInstantWithdrawals();
        if (_shares == 0) revert IncorrectArgument();
        _transfer(msg.sender, withdrawTool, _shares);
        uint256 requestedAmount = _shares * _getExchangeRate() / 1e18;
        DelayedWithdrawalTool(withdrawTool).request(_to, _shares, requestedAmount);
    }

    function _fulfillWithdrawalRequests() internal {
        uint256 underlyingAmount = DelayedWithdrawalTool(withdrawTool).totalUnderlyingRequested();

        // there will be some leftover underlying balance due to the profit accumulation during the withdrawal period
        // it will be counted as a pool profit
        underlyingBalanceStored -= underlyingAmount;

        uint256 sharesToBurn = balanceOf(withdrawTool);
        _burn(withdrawTool, sharesToBurn);

        IERC20(underlying).safeTransfer(withdrawTool, underlyingAmount);

        DelayedWithdrawalTool(withdrawTool).markFulfilled(sharesToBurn);
    }

    function withdrawReserves(address _to) external onlyReservesManager {
        uint256 _reserves = reserves;
        reserves = 0;
        underlyingBalanceStored -= _reserves;
        require(IERC20(underlying).transfer(_to, _reserves), "transfer failed");
    }

    /**
     *  @notice only timeLock contract is allowed to set the security factor
     *  @notice complexity fee cannot be greater than 1%
     *  @param _complexityWithdrawalFeeFactor the value of the complexity fee applying to withdrawals from allocations
     */
    function setComplexityWithdrawalFeeFactor(uint256 _complexityWithdrawalFeeFactor) external onlyTimeLock {
        if (_complexityWithdrawalFeeFactor > 0.01e18) revert IncorrectArgument();
        complexityWithdrawalFeeFactor = _complexityWithdrawalFeeFactor;
        emit ComplexityFeeFactorSet(_complexityWithdrawalFeeFactor);
    }

    /**
     *  @notice only admin is allowed to set the reserve factor
     *  @notice reserves factor CAN be changed without prior notice, but will apply only to the future profit
     *  @notice performance fee cannot be greater than 100% of the profit
     */
    function setReserveFactor(uint256 _reserveFactor) external onlyAdmin {
        if (_reserveFactor > 1e18) revert IncorrectArgument();
        calculateExchangeRate();
        reserveFactor = _reserveFactor;
        emit ReserveFactorSet(_reserveFactor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract SharesOfAllocatedLiquidity is ERC20 {
    uint8 internal immutable _decimals;

    constructor(address _underlying, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _decimals = IERC20Metadata(_underlying).decimals();
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}