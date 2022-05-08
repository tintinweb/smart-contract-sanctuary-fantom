// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= DEI_AMO v3 =========================
// =============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem gh: https://github.com/kazemghareghani

// Auditor(s)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniwapV2Pair.sol";
import "./interfaces/ISolidly.sol";
import "./interfaces/IBeetPool.sol";
import "./interfaces/FlashBorrower.sol";
import "./PoolGateway.sol";
import "./interfaces/IGeneralLender.sol";

contract DeiAMO is AccessControl, FlashBorrower {
    using SafeERC20 for IERC20;

    /* ========== ROLES ========== */
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");

    /* ========== STATE VARIABLES ========== */
    address public poolGateway;
    address public generalLender;
    address public dei;
    address public usdc;

    bytes private data;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    struct AMOInput {
        address router;
        uint256 amountIn;
        uint256 minAmountOut;
        address[] uniswapPath;
        ISolidly.route[] routes;
    }

    struct GeneralLenderIndexInput {
        uint256[] collateralIndexes;
        uint256[] value;
    }

    struct BeetInput {
        address router;
        IBeetPool.SingleSwap singleSwap;
        IBeetPool.FundManagement funds;
        uint256 limit;
    }

    struct AMOData {
        AMOInput[] amoInputs;
        BeetInput[] beetInputs;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address admin,
        address trusty,
        address dei_,
        address usdc_,
        address poolGatewayAddress_,
        address generalLenderAddress_
    ) {
        poolGateway = poolGatewayAddress_;
        generalLender = generalLenderAddress_;
        dei = dei_;
        usdc = usdc_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(TRUSTY_ROLE, trusty);

        IERC20(dei).safeApprove(poolGateway, type(uint256).max);
        IERC20(usdc).safeApprove(poolGateway, type(uint256).max);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setParams(
        address poolGatewayAddress_,
        address generalLenderAddress_
    ) public onlyRole(TRUSTY_ROLE) {
        poolGateway = poolGatewayAddress_;
        generalLender = generalLenderAddress_;

        IERC20(dei).safeApprove(poolGateway, type(uint256).max);
        IERC20(usdc).safeApprove(poolGateway, type(uint256).max);
    }

    function approve(address token, address to) public onlyRole(TRUSTY_ROLE) {
        IERC20(token).safeApprove(to, type(uint256).max);
    }

    function withdrawERC20(address token, uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) external onlyRole(TRUSTY_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function onFlashLoanFromPoolGateway(address initiator)
        external
        override
        returns (bytes32)
    {
        require(msg.sender == poolGateway, "DeiAmoV3: UNTRUSTED_POOL_GATEWAY");
        require(
            initiator == address(this),
            "DeiAmoV3: UNTRUSTED_LOAN_INITIATOR"
        );
        AMOData memory amoData = abi.decode(data, (AMOData));
        for (uint256 i = 0; i < amoData.amoInputs.length; i = i + 1) {
            AMOInput memory input = amoData.amoInputs[i];
            if (input.uniswapPath.length > 0) {
                IUniswapV2Router02(input.router).swapExactTokensForTokens(
                    input.amountIn,
                    input.minAmountOut,
                    input.uniswapPath,
                    address(this),
                    deadline
                );
            } else if (input.routes.length > 0) {
                ISolidly(input.router).swapExactTokensForTokens(
                    input.amountIn,
                    input.minAmountOut,
                    input.routes,
                    address(this),
                    deadline
                );
            }
        }
        for (uint256 i = 0; i < amoData.beetInputs.length; i = i + 1) {
            BeetInput memory input = amoData.beetInputs[i];
            IBeetPool(input.router).swap(
                input.singleSwap,
                input.funds,
                input.limit,
                deadline
            );
        }

        return keccak256("FlashBorrower.onFlashLoanFromPoolGateway");
    }

    function buyDei(uint256 amount, AMOData memory amoData)
        external
        onlyRole(TRUSTY_ROLE)
    {
        data = abi.encode(amoData);
        PoolGateway(poolGateway).loanUsdc(amount);
        data = "";
    }

    function sellDei(uint256 amount, AMOData memory amoData)
        external
        onlyRole(TRUSTY_ROLE)
    {
        data = abi.encode(amoData);
        PoolGateway(poolGateway).loanDei(amount);
        data = "";
    }

    function setInterest(GeneralLenderIndexInput memory input)
        external
        onlyRole(TRUSTY_ROLE)
    {
        for (uint256 i = 0; i < input.collateralIndexes.length; i += 1) {
            IGeneralLender(generalLender).setInterestPerSecond(
                input.collateralIndexes[i],
                input.value[i]
            );
        }
    }

    function setBorrowOpeningFee(GeneralLenderIndexInput memory input)
        external
        onlyRole(TRUSTY_ROLE)
    {
        uint256 discount;
        for (uint256 i = 0; i < input.collateralIndexes.length; i += 1) {
            discount = IGeneralLender(generalLender).discountRatios(
                input.collateralIndexes[i]
            );
            require(
                input.value[i] >= discount,
                "DeiAmoV3: INVALID_BORROW_OPENING_FEE"
            );
            IGeneralLender(generalLender).setBorrowOpeningFee(
                input.collateralIndexes[i],
                input.value[i]
            );
        }
    }

    function setDiscountRatio(GeneralLenderIndexInput memory input)
        external
        onlyRole(TRUSTY_ROLE)
    {
        uint256 openingFee;
        for (uint256 i = 0; i < input.collateralIndexes.length; i += 1) {
            openingFee = IGeneralLender(generalLender).borrowOpeningFees(
                input.collateralIndexes[i]
            );
            require(openingFee >= input.value[i], "DeiAmoV3: INVALID_DISCOUNT");
            IGeneralLender(generalLender).setDiscountRatio(
                input.collateralIndexes[i],
                input.value[i]
            );
        }
    }

    /* ========== VIEWS ========== */

    function getAmountsOut(AMOData calldata amoData)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountsOut = new uint256[](amoData.amoInputs.length);
        for (uint256 i = 0; i < amoData.amoInputs.length; i += 1) {
            AMOInput memory transaction = amoData.amoInputs[i];
            if (transaction.uniswapPath.length > 0) {
                amountsOut[i] = IUniswapV2Router02(transaction.router)
                    .getAmountsOut(
                        transaction.amountIn,
                        transaction.uniswapPath
                    )[transaction.uniswapPath.length - 1];
            } else if (transaction.routes.length > 0) {
                amountsOut[i] = ISolidly(transaction.router).getAmountsOut(
                    transaction.amountIn,
                    transaction.routes
                )[transaction.routes.length];
            }
        }
        return amountsOut;
    }

    function getInterests(uint256[] calldata indexes)
        public
        view
        returns (IGeneralLender.AccrueInfo[] memory)
    {
        IGeneralLender.AccrueInfo[]
            memory infos = new IGeneralLender.AccrueInfo[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i += 1) {
            infos[i] = IGeneralLender(generalLender).accrueInfos(indexes[i]);
        }
        return infos;
    }

    function getBorrowOpeningFees(uint256[] calldata indexes)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory infos = new uint256[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i += 1) {
            infos[i] = IGeneralLender(generalLender).borrowOpeningFees(
                indexes[i]
            );
        }
        return infos;
    }

    function getDiscountRatios(uint256[] calldata indexes)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory infos = new uint256[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i += 1) {
            infos[i] = IGeneralLender(generalLender).discountRatios(indexes[i]);
        }
        return infos;
    }
}

// Dar panahe Khoda

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata uniswapPath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata uniswapPath
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUniwapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function totalSupply() external view returns (uint);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISolidly {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBeetPool {
    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @return The keccak256 hash of "FlashBorrower.onFlashLoanFromPoolGateway"
     */
    function onFlashLoanFromPoolGateway(address initiator)
        external
        returns (bytes32);
}

// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= PoolGateway =========================
// =============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem gh: https://github.com/kazemghareghani

// Auditor(s)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IDEIStablecoin.sol";
import "./interfaces/FlashBorrower.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IUsdcPool.sol";

contract PoolGateway is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    /* ========== ROLES ========== */
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
    bytes32 public constant RATE_SETTER_ROLE = keccak256("RATE_SETTER_ROLE");

    /* ========== STATE VARIABLES ========== */
    address public oracle;
    address public buybackContract;
    address public usdcPool;
    address public dei;
    address public usdc;

    uint256 public boughtDeiMeanPrice;
    uint256 public totalDeiBought;
    uint256 public minterPoolWithdrawnAmount;
    uint256 public discountRate; // in 18 decimals
    uint256 public mintFeeRate; // in 18 decimals

    mapping(address => bool) public AMOs;
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("FlashBorrower.onFlashLoanFromPoolGateway");

    /* ========== CONSTRUCTOR ========== */

    /* ========== EVENTS =============== */
    event SetOracle(address oldValue, address newValue);
    event SetAMO(address amo, bool isAMO);
    event Loan(address token, uint256 lendedAmount, uint256 repaidAmount);
    event BuyDei(address user, uint256 amountIn, uint256 amountOut);
    event SetRate(
        uint256 oldMintFee,
        uint256 newMintFee,
        uint256 oldDiscount,
        uint256 newDiscount
    );
    event SetUsdcFromMinterPool(uint256 oldValue, uint256 newValue);
    event WithdrawUsdcFromMinterPool(uint256 value);
    event PaybackUsdcToMinterPool(uint256 value);
    event SetBuyParams(
        uint256 oldMeanPrice,
        uint256 newMeanPrice,
        uint256 oldTotalDeiBought,
        uint256 newTotalDeiBought
    );
    event SetMainContracts(
        address oldUsdcPool,
        address newUsdcPool,
        address oldBuybackContract,
        address newBuybackContract
    );

    constructor(
        address admin,
        address trusty,
        address rateSetter,
        address dei_,
        address usdc_,
        address oracle_,
        address buybackContract_,
        address usdcPool_,
        uint256 mintFeeRate_,
        uint256 discountRate_
    ) {
        require(
            dei_ != address(0) &&
                usdc_ != address(0) &&
                oracle_ != address(0) &&
                buybackContract_ != address(0) &&
                usdcPool_ != address(0) &&
                admin != address(0) &&
                rateSetter != address(0) &&
                trusty != address(0),
            "PoolGateway: ZERO_ADDRESS_DETECTED"
        );
        dei = dei_;
        usdc = usdc_;
        oracle = oracle_;
        buybackContract = buybackContract_;
        usdcPool = usdcPool_;
        mintFeeRate = mintFeeRate_;
        discountRate = discountRate_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(TRUSTY_ROLE, trusty);
        _setupRole(RATE_SETTER_ROLE, rateSetter);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice set oracle address
    /// @param oracle_ oracle address
    function setOracle(address oracle_) external onlyRole(TRUSTY_ROLE) {
        require(oracle_ != address(0), "PoolGateway: ZERO_ADDRESS_DETECTED");
        emit SetOracle(oracle, oracle_);
        oracle = oracle_;
    }

    /// @notice set mint fee rate and discount rate
    /// @param mintFeeRate_ mint fee rate
    /// @param discountRate_ discount rate
    function setRates(uint256 mintFeeRate_, uint256 discountRate_)
        external
        onlyRole(RATE_SETTER_ROLE)
    {
        emit SetRate(mintFeeRate, mintFeeRate_, discountRate, discountRate_);
        mintFeeRate = mintFeeRate_;
        discountRate = discountRate_;
    }

    /// @notice set main contracts addresses
    /// @param usdcPool_ address of usdc pool
    /// @param buybackContract_ address of deus buyback contract
    function setMainContracts(address usdcPool_, address buybackContract_)
        external
        onlyRole(TRUSTY_ROLE)
    {
        require(
            usdcPool_ != address(0) && buybackContract_ != address(0),
            "PoolGateway: ZERO_ADDRESS_DETECTED"
        );
        emit SetMainContracts(
            usdcPool,
            usdcPool_,
            buybackContract,
            buybackContract_
        );
        usdcPool = usdcPool_;
        buybackContract = buybackContract_;
    }

    /// @notice set usdc from minter pool amount
    /// @param value usdc amount
    function setUsdcFromMinterPool(uint256 value)
        external
        onlyRole(TRUSTY_ROLE)
    {
        emit SetUsdcFromMinterPool(minterPoolWithdrawnAmount, value);
        minterPoolWithdrawnAmount = value;
    }

    /// @notice set parameters for buy process
    /// @param boughtDeiMeanPrice_ bought dei mean price
    /// @param totalDeiBought_ total amount of dei that AMOs bought
    function setBuyParams(uint256 boughtDeiMeanPrice_, uint256 totalDeiBought_)
        external
        onlyRole(TRUSTY_ROLE)
    {
        emit SetBuyParams(
            boughtDeiMeanPrice,
            boughtDeiMeanPrice_,
            totalDeiBought,
            totalDeiBought_
        );
        boughtDeiMeanPrice = boughtDeiMeanPrice_;
        totalDeiBought = totalDeiBought_;
    }

    /// @notice approve token to spender
    /// @param token address of token
    /// @param to address of spender
    function approve(address token, address to) public onlyRole(TRUSTY_ROLE) {
        require(token != address(0), "PoolGateway: INVALID_ADDRESS");
        require(to != address(0), "PoolGateway: INVALID_ADDRESS");
        IERC20(token).safeApprove(to, type(uint256).max);
    }

    /// @notice emergency withdraw ERC20
    /// @param token address of token
    /// @param amount token amount
    function emergencyWithdrawERC20(address token, uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @notice emergency withdraw native token
    /// @param amount native token amount
    function emergencyWithdrawETH(uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        payable(msg.sender).transfer(amount);
    }

    /// @notice transfer usdc to minter pool
    /// @param amount usdc amount
    function transferUsdcToMinterPool(uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        emit PaybackUsdcToMinterPool(amount);
        minterPoolWithdrawnAmount -= amount;
        IERC20(usdc).safeTransfer(usdcPool, amount);
    }

    /// @notice transfer usdc from minter pool
    /// @param amount usdc amount
    function transferUsdcFromMinterPool(uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        emit WithdrawUsdcFromMinterPool(amount);
        minterPoolWithdrawnAmount += amount;
        IUsdcPool(usdcPool).emergencyWithdrawERC20(usdc, amount, address(this));
    }

    /// @notice add and remove official AMO
    /// @param amo address of AMO
    /// @param isAMO the bool that set AMO as valid or invalid AMO
    function setAMO(address amo, bool isAMO) external onlyRole(TRUSTY_ROLE) {
        require(amo != address(0), "PoolGateway: ZERO_ADDRESS_DETECTED");
        emit SetAMO(amo, isAMO);
        AMOs[amo] = isAMO;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    /// @notice loan usdc and get dei from borrower
    /// @param amount amount of loan
    /// @return true if loan has repaid
    function loanUsdc(uint256 amount) external whenNotPaused returns (bool) {
        require(AMOs[msg.sender], "PoolGateway: INVALID_RECEIVER");
        // send usdc
        require(
            amount <= IERC20(usdc).balanceOf(address(this)),
            "PoolGateway: INSUFFICIENT_AMOUNT_IN"
        );
        uint256 oldBalance = IERC20(dei).balanceOf(address(this)) +
            (IERC20(usdc).balanceOf(address(this)) * 1e12);
        FlashBorrower receiver = FlashBorrower(msg.sender);
        IERC20(usdc).safeTransfer(msg.sender, amount);
        require(
            receiver.onFlashLoanFromPoolGateway(msg.sender) == CALLBACK_SUCCESS,
            "PoolGateway: CALLBACK_FAILED"
        );
        // receive all dei balance of receiver
        uint256 receiver_dei_balance = IERC20(dei).balanceOf(msg.sender);
        IERC20(dei).transferFrom(
            msg.sender,
            address(this),
            receiver_dei_balance
        );
        uint256 newBalance = IERC20(dei).balanceOf(address(this)) +
            (IERC20(usdc).balanceOf(address(this)) * 1e12);
        require(
            newBalance >= oldBalance,
            "PoolGateway: INSUFFICIENT_REPAY_AMOUNT"
        );
        boughtDeiMeanPrice =
            ((totalDeiBought * boughtDeiMeanPrice) + (amount * 1e30)) /
            (totalDeiBought + receiver_dei_balance);
        totalDeiBought += receiver_dei_balance;

        emit Loan(usdc, amount, receiver_dei_balance);
        return true;
    }

    /// @notice loan dei and get usdc from borrower
    /// @param amount amount of loan
    /// @return true if loan has repaid
    function loanDei(uint256 amount) external whenNotPaused returns (bool) {
        require(AMOs[msg.sender], "PoolGateway: INVALID_RECEIVER");
        // send dei
        uint256 extraDei;
        if (amount > totalDeiBought) {
            extraDei = amount - totalDeiBought;
            IDEIStablecoin(dei).pool_mint(address(this), extraDei);
        }
        uint256 oldBalance = IERC20(dei).balanceOf(address(this)) +
            (IERC20(usdc).balanceOf(address(this)) * 1e12);
        FlashBorrower receiver = FlashBorrower(msg.sender);
        IERC20(dei).safeTransfer(msg.sender, amount);
        require(
            receiver.onFlashLoanFromPoolGateway(msg.sender) == CALLBACK_SUCCESS,
            "PoolGateway: CALLBACK_FAILED"
        );
        // receive all usdc balance of receiver
        uint256 receiver_usdc_balance = IERC20(usdc).balanceOf(msg.sender);
        IERC20(usdc).transferFrom(
            msg.sender,
            address(this),
            receiver_usdc_balance
        );
        uint256 newBalance = IERC20(dei).balanceOf(address(this)) +
            (IERC20(usdc).balanceOf(address(this)) * 1e12);

        require(
            newBalance >= oldBalance,
            "PoolGateway: INSUFFICIENT_REPAY_AMOUNT"
        );

        if (amount >= totalDeiBought) {
            boughtDeiMeanPrice = 0;
            totalDeiBought = 0;

            uint256 deiCollateralRatio = IDEIStablecoin(dei)
                .global_collateral_ratio();
            uint256 collateralAmount = (extraDei * deiCollateralRatio) /
                (1e6 * 1e12);
            IERC20(usdc).transfer(usdcPool, collateralAmount);

            uint256 buybackUsdcAmount = (extraDei / 1e12) - collateralAmount;
            IERC20(usdc).safeTransfer(buybackContract, buybackUsdcAmount);
        } else {
            boughtDeiMeanPrice =
                ((totalDeiBought * boughtDeiMeanPrice) -
                    (receiver_usdc_balance * 1e30)) /
                (totalDeiBought - amount);
            totalDeiBought -= amount;
        }

        emit Loan(dei, amount, receiver_usdc_balance);

        return true;
    }

    /// @notice user buy dei
    /// @param minAmountOut min amount out dei
    /// @param signature signature from oracle for dei price
    function buyDei(uint256 minAmountOut, IOracle.Signature calldata signature)
        external
        whenNotPaused
    {
        uint256 price = IOracle(oracle).getPrice(signature);
        uint256 deiPrice = price - discountRate;

        if (deiPrice < boughtDeiMeanPrice) {
            deiPrice = boughtDeiMeanPrice;
        }

        IERC20(usdc).transferFrom(
            msg.sender,
            address(this),
            signature.amountIn
        );
        uint256 deiAmount = (signature.amountIn * 1e30) / deiPrice;
        if (deiAmount > totalDeiBought) {
            uint256 usdcNeededForBuyExistingDei = (totalDeiBought * deiPrice) /
                1e30;
            uint256 extraUsdc = signature.amountIn -
                usdcNeededForBuyExistingDei;
            uint256 deiCollateralRatio = IDEIStablecoin(dei)
                .global_collateral_ratio();
            uint256 collateralAmount = (extraUsdc * deiCollateralRatio) / 1e6;
            uint256 buybackUsdcAmount = extraUsdc - collateralAmount;

            uint256 mintingDei = extraUsdc * 1e12;
            uint256 mintFee = (mintingDei * mintFeeRate) / 1e18;

            IDEIStablecoin(dei).pool_mint(address(this), mintingDei - mintFee);
            deiAmount = totalDeiBought + mintingDei - mintFee;

            require(
                deiAmount >= minAmountOut,
                "PoolGateway: INSUFFICIENT_OUTPUT_AMOUNT"
            );

            boughtDeiMeanPrice = 0;
            totalDeiBought = 0;

            IERC20(usdc).transfer(usdcPool, collateralAmount);
            IERC20(usdc).safeTransfer(buybackContract, buybackUsdcAmount);
            IERC20(dei).safeTransfer(msg.sender, deiAmount);
        } else {
            require(
                deiAmount >= minAmountOut,
                "PoolGateway: INSUFFICIENT_OUTPUT_AMOUNT"
            );
            if (totalDeiBought == deiAmount) {
                boughtDeiMeanPrice = 0;
            } else {
                boughtDeiMeanPrice =
                    ((totalDeiBought * boughtDeiMeanPrice) -
                        (deiAmount * deiPrice)) /
                    (totalDeiBought - deiAmount);
            }
            totalDeiBought -= deiAmount;
            IERC20(dei).safeTransfer(msg.sender, deiAmount);
        }
        emit BuyDei(msg.sender, signature.amountIn, deiAmount);
    }

    /// @notice pause contract
    function pause() external onlyRole(RATE_SETTER_ROLE) {
        super._pause();
    }

    /// @notice unpause contract
    function unpause() external onlyRole(RATE_SETTER_ROLE) {
        super._unpause();
    }

    /* ========== VIEWS ========== */

    function collatDollarBalance(uint256 collat_usd_price)
        public
        view
        returns (uint256)
    {
        return minterPoolWithdrawnAmount;
    }

    function getAmountOut(uint256 amountIn, uint256 price)
        public
        view
        returns (uint256)
    {
        uint256 deiPrice = price - discountRate;
        if (deiPrice < boughtDeiMeanPrice) {
            deiPrice = boughtDeiMeanPrice;
        }
        uint256 deiAmount = (amountIn * 1e30) / deiPrice;
        if (deiAmount > totalDeiBought) {
            uint256 usdcNeededForBuyExistingDei = (totalDeiBought * deiPrice) /
                1e30;
            uint256 extraUsdc = amountIn - usdcNeededForBuyExistingDei;
            uint256 mintingDei = extraUsdc * 1e12;
            uint256 mintFee = (mintingDei * mintFeeRate) / 1e18;
            deiAmount = totalDeiBought + mintingDei - mintFee;
            return deiAmount;
        }
        return deiAmount;
    }
}

// Dar panahe Khoda

// SPDX-License-Identifier: GPL3.0-or-later

pragma solidity ^0.8.13;

interface IGeneralLender {
    struct AccrueInfo {
        uint256 lastAccrued;
        uint256 interestPerSecond;
    }

    function setInterestPerSecond(
        uint256 collateralIndex,
        uint256 interestPerSecond
    ) external;

    function setBorrowOpeningFee(
        uint256 collateralIndex,
        uint256 borrowOpeningFee_
    ) external;

    function setDiscountRatio(uint256 collateralIndex, uint256 discountRatio_)
        external;

    function accrueInfos(uint256 collateralIndex)
        external
        view
        returns (AccrueInfo memory accrueInfo);

    function borrowOpeningFees(uint256 collateralIndex)
        external
        view
        returns (uint256);

    function discountRatios(uint256 collateralIndex)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

interface IDEIStablecoin {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function global_collateral_ratio() external view returns (uint256);
    function dei_pools(address _address) external view returns (bool);
    function dei_pools_array() external view returns (address[] memory);
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);
    function dei_info(uint256[] memory collat_usd_price) external view returns (uint256, uint256, uint256);
    function getChainID() external view returns (uint256);
    function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);
    function refreshCollateralRatio(uint deus_price, uint dei_price, uint256 expire_block, bytes[] calldata sigs) external;
    function useGrowthRatio(bool _use_growth_ratio) external;
    function setGrowthRatioBands(uint256 _GR_top_band, uint256 _GR_bottom_band) external;
    function setPriceBands(uint256 _top_band, uint256 _bottom_band) external;
    function activateDIP(bool _activate) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function addPool(address pool_address) external;
    function removePool(address pool_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
    function setOracle(address _oracle) external;
    function setDEIStep(uint256 _new_step) external;
    function setReserveTracker(address _reserve_tracker_address) external;
    function setRefreshCooldown(uint256 _new_cooldown) external;
    function setDEUSAddress(address _deus_address) external;
    function toggleCollateralRatio() external;
}

//Dar panah khoda

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import "./IMuonV02.sol";

interface IOracle {
    struct Signature {
        uint256 amountIn;
        uint256 price;
        uint256 timestamp;
        bytes reqId;
        SchnorrSign[] sigs;
    }

    function getPrice(Signature calldata signature) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IUsdcPool {
    function emergencyWithdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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