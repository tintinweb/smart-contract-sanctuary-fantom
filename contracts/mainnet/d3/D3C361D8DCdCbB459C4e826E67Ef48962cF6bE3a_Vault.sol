// Be name Khoda
// SPDX-License-Identifier: GPL-3.0-or-later

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Vault ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// Mmd: https://github.com/mmd-mostafaee

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IVeLender.sol";
import "./interfaces/IPlatformVoter.sol";
import "./interfaces/IBaseV1Voter.sol";
import "./interfaces/Ive.sol";
import "../Fluid/IFluid.sol";

/// @title Vault of veNFTs
/// @author DEUS Finance
/// @notice to sell/buy veNFTs or add collateral to ve-lender
contract Vault is AccessControl {
    event SetPlatformVoter(address oldValue, address newValue);
    event SetLender(address oldValue, address newValue);
    event Deposit(address user, uint256 tokenId);
    event Lock(
        address locker,
        uint256 tokenId,
        uint256 amount,
        address user,
        address[] poolVote,
        int256[] weights
    );
    event Unlock(address user, uint256 tokenId, uint256 amount, address to);
    event Buy(address buyer, uint256 tokenId, uint256 amount, address user);
    event Sell(address seller, uint256 tokenId);
    event Withdraw(
        address withdrawer,
        uint256 tokenId,
        uint256 amount,
        address user
    );
    event Liquidate(address user, uint256 tokenId);
    event Vote(address user, address[] poolVote, int256[] weights);
    event VoteFor(uint256[] tokenIds, address[] poolVote, int256[] weights);

    address public immutable votingEscrow; // veNFT contract address

    address public immutable token; // Fluid contract address

    address public immutable baseV1Voter; // voter contract address

    address public platformVoter; // platform voter contract address

    address public lender; // veLender contract address

    mapping(address => uint256) public ownerToId; // owner -> tokenId
    mapping(address => uint256) public lockPendingId; // owner -> lock pending tokenId
    mapping(address => uint256) public withdrawPendingId; // owner -> withdraw pending tokenId

    mapping(uint256 => bool) public isFree; // tokenId -> has owner

    bytes32 public constant VE_LENDER_ROLE = keccak256("VE_LENDER_ROLE"); // veLender role

    bytes32 public constant PLATFORM_VOTER_ROLE =
        keccak256("PLATFORM_VOTER_ROLE"); // platform voter role

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // manager role

    constructor(
        address votingEscrow_,
        address token_,
        address baseV1Voter_,
        address manager,
        address platformVoter_,
        address lender_,
        address admin
    ) {
        votingEscrow = votingEscrow_;
        token = token_;
        baseV1Voter = baseV1Voter_;
        platformVoter = platformVoter_;
        lender = lender_;

        IFluid(token).approve(lender, type(uint256).max);

        _setupRole(VE_LENDER_ROLE, lender_);
        _setupRole(MANAGER_ROLE, manager);
        _setupRole(PLATFORM_VOTER_ROLE, platformVoter_);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Sets new platformVoter 
    /// @param platformVoter_ new platformVoter address 
    function setPlatformVoter(address platformVoter_)
        external
        onlyRole(MANAGER_ROLE)
    {
        emit SetPlatformVoter(platformVoter, platformVoter_);
        platformVoter = platformVoter_;
    }

    /// @notice Sets new lender 
    /// @param lender_ new lender address 
    function setLender(address lender_) external onlyRole(MANAGER_ROLE) {
        emit SetLender(lender, lender_);
        lender = lender_;
    }

    /// @notice Sets user tokenId
    /// @dev Merge happens in case of already having a tokenId
    /// @param user owner address
    /// @param tokenId veNFT tokenId
    function _setNft(address user, uint256 tokenId) internal {
        if (ownerToId[user] != 0) {
            IBaseV1Voter(baseV1Voter).reset(ownerToId[user]);
            Ive(votingEscrow).merge(ownerToId[user], tokenId);
        }
        ownerToId[user] = tokenId;
    }

    /// @notice Deposits veNFT into the vault 
    /// @dev TokenId added to lockPendingId mapping
    /// @param tokenId veNFT tokenId
    function deposit(uint256 tokenId) external {
        require(
            lockPendingId[msg.sender] == 0,
            "Vault: PENDING_DEPOSIT_EXISTS"
        );

        IBaseV1Voter(baseV1Voter).reset(tokenId);

        Ive(votingEscrow).transferFrom(msg.sender, address(this), tokenId);

        uint256 amount = getCollateralAmount(tokenId);
        require(amount > 0, "Vault: ZERO_COLLATERAL_AMOUNT");

        lockPendingId[msg.sender] = tokenId;

        emit Deposit(msg.sender, tokenId);
    }

    /// @notice Locks veNFT for user 
    /// @dev Votes must be verified and amount of token will be added to veLender as collateral
    /// @param user owner address
    /// @param poolVote user votes 
    /// @param weights user votes weights 
    /// @return amount of token
    function _lockFor(
        address user,
        address[] memory poolVote,
        int256[] memory weights
    ) internal returns (uint256) {
        uint256 tokenId = lockPendingId[msg.sender];
        lockPendingId[msg.sender] = 0;

        require(tokenId != 0, "Vault: PENDING_DEPOSIT_DOES_NOT_EXIST");

        uint256 amount = getCollateralAmount(tokenId);

        _setNft(user, tokenId);

        IFluid(token).mint(address(this), amount);

        IVeLender(lender).vaultAddCollateral(user, amount);

        IPlatformVoter(platformVoter).verifyVotes(poolVote, weights);

        IBaseV1Voter(baseV1Voter).vote(tokenId, poolVote, weights);

        emit Lock(msg.sender, tokenId, amount, user, poolVote, weights);

        return amount;
    }

    /// @notice Locks veNFT for caller
    /// @dev Deposit should be called first 
    /// @param poolVote user votes
    /// @param weights user votes weights 
    /// @return amount of token 
    function lock(address[] memory poolVote, int256[] memory weights)
        external
        returns (uint256)
    {
        return _lockFor(msg.sender, poolVote, weights);
    }

    /// @notice Locks veNFT for user 
    /// @dev Deposit should be called first 
    /// @param user owner address
    /// @param poolVote user votes
    /// @param weights user votes weights 
    /// @return amount of token 
    function lockFor(
        address user,
        address[] memory poolVote,
        int256[] memory weights
    ) external returns (uint256) {
        return _lockFor(user, poolVote, weights);
    }

    /// @notice Unlocks veNFT for user 
    /// @dev Only called by lender 
    /// @param user user address 
    /// @param amount amount of token
    /// @param to veNFT reciever address
    function unlockFor(
        address user,
        uint256 amount,
        address to
    ) external onlyRole(VE_LENDER_ROLE) {
        uint256 tokenId = ownerToId[user];

        require(tokenId != 0, "Vault: INVALID_TOKEN_ID");

        ownerToId[user] = 0;
        IFluid(token).burn(msg.sender, amount);
        IBaseV1Voter(baseV1Voter).reset(tokenId);
        Ive(votingEscrow).transferFrom(address(this), to, tokenId);

        emit Unlock(user, tokenId, amount, to);
    }

    /// @notice Buys free veNFT for user 
    /// @param tokenId veNFT tokenId
    /// @param user user address 
    /// @return amount of token 
    function _buyFor(uint256 tokenId, address user) internal returns (uint256) {
        require(isFree[tokenId], "Vault: NOT_FREE");

        uint256 amount = getCollateralAmount(tokenId);

        IFluid(token).burn(msg.sender, amount);

        IBaseV1Voter(baseV1Voter).reset(tokenId);
        Ive(votingEscrow).transferFrom(address(this), user, tokenId);

        isFree[tokenId] = false;

        emit Buy(msg.sender, tokenId, amount, user);

        return amount;
    }

    /// @notice Buys free veNFT for caller 
    /// @param tokenId veNFT tokenId
    /// @return amount of token 
    function buy(uint256 tokenId) external returns (uint256) {
        return _buyFor(tokenId, msg.sender);
    }

    /// @notice Buys free veNFT for user
    /// @param tokenId veNFT tokenId
    /// @param user user address
    /// @return amount of token 
    function buyFor(uint256 tokenId, address user) external returns (uint256) {
        return _buyFor(tokenId, user);
    }

    /// @notice Sells veNFT to the vault 
    /// @dev TokenId added to withdrawPendingId mapping
    /// @param tokenId veNFT tokenId  
    function sell(uint256 tokenId) external {
        require(
            withdrawPendingId[msg.sender] == 0,
            "Vault: PENDING_WITHDRAW_EXISTS"
        );

        withdrawPendingId[msg.sender] = tokenId;
        isFree[tokenId] = true;

        IBaseV1Voter(baseV1Voter).reset(tokenId);

        Ive(votingEscrow).transferFrom(msg.sender, address(this), tokenId);

        emit Sell(msg.sender, tokenId);
    }

    /// @notice Withdraws token for user 
    /// @dev Called  
    /// @param user user address  
    function _withdraw(address user) internal {
        uint256 tokenId = withdrawPendingId[msg.sender];
        require(tokenId != 0, "Vault: PENDING_WITHDRAW_DOES_NOT_EXIST");

        withdrawPendingId[msg.sender] = 0;

        (address[] memory poolVote, int256[] memory weights) = IPlatformVoter(
            platformVoter
        ).getVotes();
        IBaseV1Voter(baseV1Voter).vote(tokenId, poolVote, weights);

        uint256 amount = getCollateralAmount(tokenId);
        IFluid(token).mint(user, amount);

        emit Withdraw(msg.sender, tokenId, amount, user);
    }

    function withdraw() external {
        _withdraw(msg.sender);
    }

    function withdrawTo(address user) external {
        _withdraw(user);
    }

    function liquidate(address user) external onlyRole(VE_LENDER_ROLE) {
        uint256 tokenId = ownerToId[user];
        require(tokenId != 0, "Vault: INVALID_TOKEN_ID");
        ownerToId[user] = 0;
        isFree[tokenId] = true;

        emit Liquidate(user, tokenId);
    }

    function _vote(address[] memory poolVote, int256[] memory weights)
        internal
    {
        require(
            IPlatformVoter(platformVoter).canVote(msg.sender),
            "Vault: VOTING_RESTRICTED"
        );

        IPlatformVoter(platformVoter).verifyVotes(poolVote, weights);

        IBaseV1Voter(baseV1Voter).vote(
            ownerToId[msg.sender],
            poolVote,
            weights
        );

        emit Vote(msg.sender, poolVote, weights);
    }

    function vote(address[] memory poolVote, int256[] memory weights) external {
        _vote(poolVote, weights);
    }

    function voteFor(
        uint256[] memory tokenIds,
        address[] memory poolVote,
        int256[] memory weights
    ) external {
        require(
            msg.sender == platformVoter,
            "Vault: CALLER_IS_NOT_PLATFORM_VOTER"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isFree[tokenId] == true, "Vault: NOT_FREE_TOKEN");
            IBaseV1Voter(baseV1Voter).vote(tokenId, poolVote, weights);
        }

        emit VoteFor(tokenIds, poolVote, weights);
    }

    function getCollateralAmount(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (uint256 amount, ) = Ive(votingEscrow).locked(tokenId);
        return amount;
    }

    function getTokenId(address user) external view returns (uint256) {
        return ownerToId[user];
    }
}

//Dar panah khoda

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

import "../../DeiLenderLP/interfaces/IOracle.sol";

interface IVeLender {
    struct AccrueInfo {
        uint256 lastAccrued; // lastAccrue timestamp
        uint256 interestPerSecond; // interest per second
    }
    struct LiquidationInput {
        address to; // address of collateral receiver
        address recipient; // address of swap recipient in swapper
        address swapper; // address of swapper contract
        address[] users; // array of users addresses
    }

    function initialize(
        address collateral_,
        address oracle_,
        address vault_,
        uint256 maxCap_,
        uint256 borrowOpeningFee_,
        uint256 liquidationRatio_,
        uint256 distributionRatio_,
        uint256 interestPerSecond
    ) external;

    function setOracle(address oracle_) external;

    function setMaxCap(uint256 maxCap_) external;

    function setBorrowOpeningFee(uint256 borrowOpeningFee_) external;

    function setLiquidationRatio(uint256 liquidationRatio_) external;

    function setDiscountRatio(uint256 discountRatio_) external;

    function setInterestPerSecond(uint256 interestPerSecond_) external;

    function setVault(address vault_) external;

    function setMintHelper(address mintHelper_) external;

    function setHolderManager(address holderManager_) external;

    function getRepayAmount(uint256 amount)
        external
        view
        returns (uint256 repayAmount);

    function getDebt(address user) external view returns (uint256 debt);

    function getLiquidationPrice(address user) external view returns (uint256);

    function getWithdrawableCollateralAmount(address user, uint256 price)
        external
        view
        returns (uint256);

    function isSolvent(address user, uint256 price)
        external
        view
        returns (bool);

    function accrue() external;

    function userAddCollateral(address to, uint256 amount) external;

    function vaultAddCollateral(address to, uint256 amount) external;

    function removeCollateral(
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external;

    function unlock(address to, IOracle.Signature calldata signature) external;

    function borrow(
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external returns (uint256 debt);

    function repayElastic(address to, uint256 debt)
        external
        returns (uint256 repayAmount);

    function repayBase(address to, uint256 amount)
        external
        returns (uint256 repayAmount);

    function liquidate(
        LiquidationInput calldata liquidationInput,
        IOracle.Signature calldata signature
    ) external;

    function withdrawFee(address to, uint256 amount) external;

    function emergencyWithdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function emergencyWithdrawETH(address to, uint256 amount) external;
}
//Dar panah khoda

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IPlatformVoter {
    function verifyVotes(
        address[] calldata poolVote_,
        int256[] calldata weights_
    ) external view;

    function getVotes()
        external
        view
        returns (address[] memory, int256[] memory);

    function canVote(address user) external returns (bool);
}
//Dar panah khoda

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IBaseV1Voter {
    // address public immutable _ve; // the ve token that governs these contracts
    // address public immutable factory; // the BaseV1Factory
    // address public immutable gaugefactory;
    // address public immutable bribefactory;
    // address public minter;

    // uint public totalWeight; // total voting weight

    // address[] public pools; // all pools viable for incentives
    // mapping(address => address) public gauges; // pool => gauge
    // mapping(address => address) public poolForGauge; // gauge => pool
    // mapping(address => address) public bribes; // gauge => bribe
    // mapping(address => int256) public weights; // pool => weight
    function votes(uint256 nft, address pool) external view returns (int256); // nft => pool => votes

    function poolVote(uint256 nft, uint256 index) external view returns (address); // nft => pools

    // mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    // mapping(address => bool) public isGauge;
    // mapping(address => bool) public isWhitelisted;

    function initialize(address[] memory _tokens, address _minter) external;

    function listing_fee() external view returns (uint256);

    function reset(uint256 _tokenId) external;

    function poke(uint256 _tokenId) external;

    function vote(
        uint256 tokenId,
        address[] calldata _poolVote,
        int256[] calldata _weights
    ) external;

    function whitelist(address _token, uint256 _tokenId) external;

    function createGauge(address _pool) external returns (address);

    function attachTokenToGauge(uint256 tokenId, address account) external;

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external;

    function detachTokenFromGauge(uint256 tokenId, address account) external;

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external;

    function length() external view returns (uint256);

    // mapping(address => uint) external claimable;

    function notifyRewardAmount(uint256 amount) external;

    function updateFor(address[] memory _gauges) external;

    function updateForRange(uint256 start, uint256 end) external;

    function updateAll() external;

    function updateGauge(address _gauge) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function distributeFees(address[] memory _gauges) external;

    function distribute(address _gauge) external;

    function distro() external;

    function distribute() external;

    function distribute(uint256 start, uint256 finish) external;

    function distribute(address[] memory _gauges) external;
}
//Dar panah khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface Ive {
    function increase_amount(uint256 tokenID, uint256 value) external;

    function increase_unlock_time(uint256 tokenID, uint256 duration) external;

    function merge(uint256 fromID, uint256 toID) external;

    function locked(uint256 tokenID)
        external
        view
        returns (uint256 amount, uint256 unlockTime);

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOfNFT(uint256 tokenId) external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);

    function create_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IFluid {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function VAULT_ROLE() external view returns (bytes32);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
//Dar panah khoda

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma experimental ABIEncoderV2;

import "./IMuonV02.sol";

interface IOracle {
    struct Signature {
        uint256 price;
        uint256 timestamp;
        bytes reqId;
        SchnorrSign[] sigs;
    }

    event SetMuon(address oldValue, address newValue);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetValiTime(uint256 oldValue, uint256 newValue);
    event SetAppId(uint32 oldValue, uint32 newValue);
    event SetExpireTime(uint256 oldValue, uint256 newValue);

    function muon() external view returns (address);

    function appId() external view returns (uint32);

    function minimumRequiredSignatures() external view returns (uint256);

    function expireTime() external view returns (uint256);

    function SETTER_ROLE() external view returns (bytes32);

    function setMuon(address muon_) external;

    function setAppId(uint32 appId_) external;

    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_)
        external;

    function setExpireTime(uint256 expireTime_) external;

    function getPrice(address collateral, Signature calldata signature)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}