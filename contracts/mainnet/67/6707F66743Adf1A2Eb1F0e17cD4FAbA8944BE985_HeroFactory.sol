//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./HeroLibrary.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract HeroFactory is AccessControl, Pausable {
    bool public isHeroFactory = true;

    // ROLES
    bytes32 public constant HERO_ADMIN_ROLE = keccak256("HERO_ADMIN_ROLE");

    // *************************************************
    // Contract Params
    // *************************************************
    uint256[16] internal TOTAL_TRAIT_COUNTS = [
        uint256(35),
        64,
        11,
        83,
        88,
        58,
        11,
        1,
        100,
        100,
        100,
        100,
        100,
        100,
        100,
        100
    ];

    // *************************************************
    // Data
    // *************************************************
    mapping(uint256 => SharedStructs.Hero) _heroes;

    // *************************************************
    // Events
    // *************************************************
    event HeroUpdated(SharedStructs.Hero hero);

    // *************************************************
    // Constructor
    // *************************************************
    constructor() {
        // setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(HERO_ADMIN_ROLE, msg.sender);
    }

    // *************************************************
    // Internal Functions
    // *************************************************
    function _convertLargeNumToTrait(uint16[16] memory _genesArr)
        internal
        view
        returns (uint16[16] memory)
    {
        uint16[16] memory traitIdArr;

        for (uint16 i = 0; i < 16; i++) {
            // determine what trait the gene represents
            // add 1 to make sure there are no 0s
            traitIdArr[i] = (_genesArr[i] % uint16(TOTAL_TRAIT_COUNTS[i])) + 1;
        }

        return traitIdArr;
    }

    // *************************************************
    // Hero Editors - Admin only
    // *************************************************
    function editGeneration(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].generation = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    // forging data
    function editParent1(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].parent1 = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editParent2(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].parent2 = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editForgeCount(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].forgeCount = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editCooldown(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].cooldown = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    // dna data
    function editHeroGene(
        uint256 _heroId,
        uint256 _index,
        uint16 value
    ) public whenNotPaused onlyRole(HERO_ADMIN_ROLE) {
        _heroes[_heroId].genes[_index] = value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    // training data
    function editPowerLevel(
        uint256 _heroId,
        uint256 _index,
        uint256 value
    ) public whenNotPaused onlyRole(HERO_ADMIN_ROLE) {
        _heroes[_heroId].powerlevels[_index] = value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editTrainingCount(
        uint256 _heroId,
        uint256 _index,
        uint256 value
    ) public whenNotPaused onlyRole(HERO_ADMIN_ROLE) {
        _heroes[_heroId].trainingCounts[_index] = value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    // game stats
    function editWinCount(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].winCount = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editLoseCount(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].loseCount = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function editLevel(uint256 _heroId, uint256 _value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_heroId].level = _value;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function updateTotalTraitsArr(uint256 index, uint256 value)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        TOTAL_TRAIT_COUNTS[index] = value;
    }

    // *************************************************
    // Public Functions - Admin Only
    // *************************************************
    function createNewHero(
        uint16[16] memory genesArr,
        uint256 generation,
        uint256 p1,
        uint256 p2,
        uint256 newTokenID,
        bool isMint,
        uint256[16] memory powerLevelsArr
    )
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
        returns (SharedStructs.Hero memory)
    {
        uint256[16] memory temp = [
            uint256(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];

        // calculat traits
        uint16[16] memory traitsArr;

        if (isMint) {
            // only need to convert from LARGE RANDOM GENES if its a mint
            traitsArr = _convertLargeNumToTrait(genesArr);
        } else {
            traitsArr = (genesArr);
        }

        SharedStructs.Hero memory _newHero = SharedStructs.Hero({
            id: newTokenID,
            generation: generation,
            parent1: p1,
            parent2: p2,
            cooldown: block.timestamp + 3 hours,
            genes: traitsArr,
            forgeCount: 0,
            powerlevels: powerLevelsArr,
            trainingCounts: temp,
            level: 0,
            winCount: 0,
            loseCount: 0
        });

        _heroes[newTokenID] = _newHero;

        return _newHero;
    }

    function updateBattleCounts(uint256 _heroId, bool _isWin)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        if (_isWin) {
            _heroes[_heroId].winCount++;
        } else {
            _heroes[_heroId].loseCount++;
        }

        _heroes[_heroId].level = uint256(
            (2 * _heroes[_heroId].winCount + _heroes[_heroId].loseCount) / 10
        );
        emit HeroUpdated(_heroes[_heroId]);
    }

    function updateTrainingCount(
        uint256 _heroId,
        uint256 _geneIndex,
        uint256 _count
    ) public whenNotPaused onlyRole(HERO_ADMIN_ROLE) {
        _heroes[_heroId].trainingCounts[_geneIndex] += _count;
        emit HeroUpdated(_heroes[_heroId]);
    }

    function updateGenePower(
        uint256 _heroId,
        uint256 geneIndex,
        uint256 val,
        bool isNegative
    ) public whenNotPaused onlyRole(HERO_ADMIN_ROLE) {
        if (isNegative == true) {
            // check for underflow, if possible set power to 0
            if (_heroes[_heroId].powerlevels[geneIndex] <= val) {
                _heroes[_heroId].powerlevels[geneIndex] = 0;
            }
            // otherwise subtract from gene's powerlevel
            else {
                _heroes[_heroId].powerlevels[geneIndex] -= val;
            }
        } else {
            _heroes[_heroId].powerlevels[geneIndex] += val;
        }

        emit HeroUpdated(_heroes[_heroId]);
    }

    function updateForgeData(uint256 _hero1, uint256 _hero2)
        public
        whenNotPaused
        onlyRole(HERO_ADMIN_ROLE)
    {
        _heroes[_hero1].forgeCount++;
        _heroes[_hero2].forgeCount++;

        _heroes[_hero1].cooldown =
            block.timestamp +
            (_heroes[_hero1].forgeCount * 1 hours);

        _heroes[_hero2].cooldown =
            block.timestamp +
            (_heroes[_hero2].forgeCount * 1 hours);

        emit HeroUpdated(_heroes[_hero1]);
        emit HeroUpdated(_heroes[_hero2]);
    }

    // *************************************************
    // Public Functions
    // *************************************************
    function getHero(uint256 _id)
        public
        view
        returns (SharedStructs.Hero memory)
    {
        return _heroes[_id];
    }

    function getTotalTraitCount() public view returns (uint256[16] memory) {
        return TOTAL_TRAIT_COUNTS;
    }

    function isRelated(uint256 hero1, uint256 hero2)
        public
        view
        returns (bool)
    {
        // for gen0 all parents will be 0, so we can ignore this
        if (_heroes[hero1].generation == 0 && _heroes[hero2].generation == 0) {
            return false;
        }

        return
            // parent check
            // hero 2 cannot be a parent of hero 1
            _heroes[hero1].parent1 == hero2 ||
            _heroes[hero1].parent2 == hero2 ||
            // hero 1 cannot be a parent of hero 2
            _heroes[hero2].parent1 == hero1 ||
            _heroes[hero2].parent2 == hero1 ||
            // sibling check
            // heroA cannot have parent 1 as heroB's parents
            _heroes[hero1].parent1 == _heroes[hero2].parent1 ||
            _heroes[hero1].parent1 == _heroes[hero2].parent2 ||
            // heroA cannot have parent 1 as heroB's parents
            _heroes[hero1].parent2 == _heroes[hero2].parent1 ||
            _heroes[hero1].parent2 == _heroes[hero2].parent2;
    }

    // *************************************************
    // Admin Functions
    // *************************************************
    function makeAdmin(address _newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(HERO_ADMIN_ROLE, _newAdmin);
    }

    function removeAdmin(address _newAdmin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(HERO_ADMIN_ROLE, _newAdmin);
    }

    function userIsAdmin(address _user) public view returns (bool) {
        return hasRole(HERO_ADMIN_ROLE, _user);
    }

    function pause() public onlyRole(HERO_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(HERO_ADMIN_ROLE) {
        _unpause();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SharedStructs {
    struct Hero {
        uint256 id; // nft id
        uint256 generation; // birth generation
        // forging data
        uint256 parent1; // id of parent 1
        uint256 parent2; // id of parent 2
        uint256 forgeCount; // number of times this hero has been used for forging
        uint256 cooldown; // forging cooldown
        // dna data
        uint16[16] genes;
        // training data
        uint256[16] powerlevels; // store the power for each expressed trait
        uint256[16] trainingCounts; // traint count for each trait
        // game stats
        uint256 winCount;
        uint256 loseCount;
        uint256 level;
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