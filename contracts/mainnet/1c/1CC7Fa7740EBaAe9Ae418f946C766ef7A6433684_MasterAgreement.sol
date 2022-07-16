// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMuonV02.sol";

contract MasterAgreement is AccessControl {
    using SafeERC20 for IERC20;

    enum QuoteState {
        PENDING,
        OPEN,
        CANCEL_PENDING,
        CANCELED,
        CLOSE_PENDING,
        CLOSE_CANCELING,
        CLOSED,
        LIQUIDATED
    }

    enum PositionType {
        SHORT,
        LONG
    }

    struct Quote {
        uint256 assetId;
        PositionType positionType;
        uint256 limitPrice; // the price that user sent in sendQuote() & requestToClose()
        uint256 filledPrice; // the price that hedger filled in openPosition()
        uint256 closedPrice; // the price that hedger closed in closePosition()
        uint256 quantity;
        uint256 makerCVA;
        uint256 takerCVA;
        uint256 makerIM;
        uint256 takerIM;
        address taker;
        QuoteState quoteState;
        uint256 modifiedTimestamp;
    }

    event Deposit(address owner, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event SendQuote(address maker, uint256 qid);
    event OpenPosition(address maker, address taker, uint256 qid);
    event RequestToClosePosition(address maker, uint256 qid, uint256 price);
    event AcceptCloseRequest(address maker, address taker, uint256 qid);
    event RequestToCancelQuote(address maker, uint256 qid);
    event CancelQuote(address maker, uint256 qid);
    event ClosePosition(address maker, uint256 qid);
    event PerformCloseRequest(address maker, uint256 qid);
    event RequestToCancelClosePosition(address maker, uint256 qid);
    event CancelRequestToClosePosition(address maker, uint256 qid);
    event Liquidate(
        address liquidator,
        address maker,
        uint256 remainingBalance
    );
    event LiquidatePosition(
        address liquidator,
        address maker,
        uint256 qid,
        uint256 liquidatorShare,
        int256 takerShare
    );
    event Reset(address maker);
    event SetCancelQuoteCooldown(uint256 oldCooldown, uint256 newCooldown);
    event SetCancelRequestToCloseCooldown(
        uint256 oldCooldown,
        uint256 newCooldown
    );
    event SetPerformCloseCooldown(uint256 oldCooldown, uint256 newCooldown);
    event SetLiquidationShare(uint256 oldShare, uint256 newShare);

    mapping(address => mapping(uint256 => Quote)) private _quotes;
    mapping(address => uint256) private _openQuotesLength;
    mapping(address => uint256) private _quotesLength;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lockedCVA;
    mapping(address => uint256) private _lockedIM;
    mapping(address => bool) private _liquidationStatus;
    mapping(address => uint256) private _positionLiquidatorsShare;
    address public collateral;
    uint256 public cancelRequestToCloseCooldown;
    uint256 public performCloseCooldown;
    uint256 public cancelQuoteCooldown;
    uint256 public liquidatorShare;
    uint256 private scale = 1e18;

    bytes32 public constant TAKER_ROLE = keccak256("TAKER_ROLE");

    modifier notLiquidateUser(address user) {
        require(!_liquidationStatus[user], "MasterAgreement: LIQUIDATED_USER");
        _;
    }

    constructor(address admin, address collateral_) {
        collateral = collateral_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function getLockedCVA(address owner) external view returns (uint256) {
        return _lockedCVA[owner];
    }

    function getLockedIM(address owner) external view returns (uint256) {
        return _lockedIM[owner];
    }

    function getQuote(address maker, uint256 qid)
        external
        view
        returns (Quote memory)
    {
        return _quotes[maker][qid];
    }

    function getQuotesLength(address user) external view returns (uint256) {
        return _quotesLength[user];
    }

    function getOpenQuotesLength(address user) external view returns (uint256) {
        return _openQuotesLength[user];
    }

    function getLiquidationStatus(address user) external view returns (bool) {
        return _liquidationStatus[user];
    }

    function getQuotes(
        address user,
        uint256 from,
        uint256 to
    ) external view returns (Quote[] memory quotes) {
        uint256 quotesLength = _quotesLength[user];
        to = min(quotesLength, to);
        uint256 idx = 0;
        for (uint256 i = from; i < to; i++) {
            quotes[idx] = _quotes[user][i];
            idx++;
        }
    }

    function getQuotes(address user)
        external
        view
        returns (Quote[] memory quotes)
    {
        uint256 quotesLength = _quotesLength[user];
        uint256 to = quotesLength;
        for (uint256 i = 0; i < to; i++) {
            quotes[i] = _quotes[user][i];
        }
    }

    function _updateQuoteState(
        address maker,
        uint256 qid,
        QuoteState state
    ) internal {
        _quotes[maker][qid].quoteState = state;
        _quotes[maker][qid].modifiedTimestamp = block.timestamp;
    }

    function _deposit(address user, uint256 amount)
        internal
        notLiquidateUser(user)
    {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        _balances[user] += amount;

        emit Deposit(user, amount);
    }

    function _withdraw(address user, uint256 amount)
        internal
        notLiquidateUser(user)
    {
        _balances[user] -= amount;
        IERC20(collateral).safeTransfer(user, amount);

        emit Withdraw(user, amount);
    }

    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, amount);
    }

    function sendQuote(
        address taker,
        uint256 assetId,
        PositionType positionType,
        uint256 limitPrice,
        uint256 quantity,
        uint256 makerCVA,
        uint256 takerCVA,
        uint256 makerIM,
        uint256 takerIM,
        SchnorrSign[] memory solvencySignatures
    ) external notLiquidateUser(msg.sender) {
        // todo: add slipage
        // todo: validate assetId
        // todo: validate signatures
        require(!hasRole(TAKER_ROLE, msg.sender), "MasterAgreement: NOT_MAKER");
        Quote memory _quote = Quote(
            assetId,
            positionType,
            limitPrice,
            uint256(0), // filled price
            uint256(0), // closed price
            quantity,
            makerCVA,
            takerCVA,
            makerIM,
            takerIM,
            taker,
            QuoteState.PENDING,
            block.timestamp
        );
        uint256 qid = _quotesLength[msg.sender]++;
        _quotes[msg.sender][qid] = _quote;

        emit SendQuote(msg.sender, qid);
    }

    function openPosition(
        address maker,
        uint256 qid,
        uint256 filledPrice,
        SchnorrSign[] memory solvencySignatures
    ) external onlyRole(TAKER_ROLE) notLiquidateUser(maker) {
        Quote storage quote = _quotes[maker][qid];
        require(
            quote.quoteState == QuoteState.PENDING ||
                quote.quoteState == QuoteState.CANCEL_PENDING,
            "MasterAgreement: INVALID_STATE"
        );
        require(quote.taker == msg.sender, "MasterAgreement: INVALID_TAKER");
        require(
            quote.positionType == PositionType.SHORT
                ? filledPrice >= quote.limitPrice
                : filledPrice <= quote.limitPrice,
            "MasterAgreement: INVALID_FILLED_PRICE"
        );
        // TODO: validate signature
        _updateQuoteState(maker, qid, QuoteState.OPEN);
        quote.filledPrice = filledPrice;
        _balances[maker] -= (quote.makerCVA + quote.makerIM);
        _balances[msg.sender] -= (quote.takerCVA + quote.takerIM);
        _lockedCVA[maker] += quote.makerCVA;
        _lockedCVA[msg.sender] += quote.takerCVA;
        _lockedIM[maker] += quote.makerIM;
        _lockedIM[msg.sender] += quote.takerIM;

        _openQuotesLength[maker]++;
        _openQuotesLength[msg.sender]++;

        emit OpenPosition(maker, msg.sender, qid);
    }

    function requestToCancelQuote(uint256 qid)
        external
        notLiquidateUser(msg.sender)
    {
        require(
            _quotes[msg.sender][qid].quoteState == QuoteState.PENDING,
            "MasterAgreement: INVALID_STATE"
        );

        _updateQuoteState(msg.sender, qid, QuoteState.CANCEL_PENDING);

        emit RequestToCancelQuote(msg.sender, qid);
    }

    function cancelQuote(address maker, uint256 qid)
        external
        notLiquidateUser(maker)
    {
        Quote storage quote = _quotes[maker][qid];

        require(
            quote.quoteState == QuoteState.CANCEL_PENDING,
            "MasterAgreement: INVALID_STATE"
        );
        require(
            quote.taker == msg.sender ||
                block.timestamp - quote.modifiedTimestamp >=
                cancelQuoteCooldown,
            "MasterAgreement: INVALID_TAKER"
        );

        _updateQuoteState(maker, qid, QuoteState.CANCELED);

        emit CancelQuote(maker, qid);
    }

    function requestToClosePosition(
        uint256 qid,
        uint256 price,
        SchnorrSign[] memory solvencySignatures
    ) external notLiquidateUser(msg.sender) {
        // todo: add slippage
        Quote storage quote = _quotes[msg.sender][qid];
        require(
            quote.quoteState == QuoteState.OPEN,
            "MasterAgreement: INVALID_STATE"
        );
        // todo: validate signature
        quote.limitPrice = price;
        _updateQuoteState(msg.sender, qid, QuoteState.CLOSE_PENDING);

        emit RequestToClosePosition(msg.sender, qid, price);
    }

    function closePosition(address maker, uint256 qid)
        external
        onlyRole(TAKER_ROLE)
        notLiquidateUser(maker)
    {
        Quote storage quote = _quotes[maker][qid];
        require(
            quote.quoteState == QuoteState.OPEN ||
                quote.quoteState == QuoteState.CLOSE_PENDING ||
                quote.quoteState == QuoteState.CANCEL_PENDING ||
                quote.quoteState == QuoteState.CLOSE_CANCELING,
            "MasterAgreement: INVALID_STATE"
        );
        require(quote.taker == msg.sender, "MasterAgreement: INVALID_TAKER");

        _updateQuoteState(maker, qid, QuoteState.CLOSED);

        _openQuotesLength[maker]--;
        _openQuotesLength[msg.sender]--;

        emit ClosePosition(maker, qid);
    }

    function performClosePosition(
        address maker,
        uint256 qid,
        SchnorrSign[] memory priceSignatures,
        SchnorrSign[] memory solvencySignatures
    ) external notLiquidateUser(maker) {
        Quote storage quote = _quotes[maker][qid];
        require(
            quote.quoteState == QuoteState.CLOSE_PENDING,
            "MasterAgreement: INVALID_STATE"
        );
        require(
            block.timestamp - quote.modifiedTimestamp >= performCloseCooldown,
            "MasterAgreement: COOLDOWN_ERROR"
        );
        _updateQuoteState(maker, qid, QuoteState.CLOSED);

        _openQuotesLength[maker]--;
        _openQuotesLength[quote.taker]--;

        emit PerformCloseRequest(maker, qid);
    }

    function requestToCancelClosePosition(uint256 qid)
        external
        notLiquidateUser(msg.sender)
    {
        Quote storage quote = _quotes[msg.sender][qid];

        require(
            quote.quoteState == QuoteState.CLOSE_PENDING,
            "MasterAgreement: INVALID_STATE"
        );
        _updateQuoteState(msg.sender, qid, QuoteState.CLOSE_CANCELING);

        emit RequestToCancelClosePosition(msg.sender, qid);
    }

    function cancelRequestToClosePosition(address maker, uint256 qid)
        external
        notLiquidateUser(maker)
    {
        Quote storage quote = _quotes[maker][qid];
        require(
            quote.quoteState == QuoteState.CLOSE_CANCELING,
            "MasterAgreement: INVALID_STATE"
        );
        require(
            quote.taker == msg.sender ||
                block.timestamp - quote.modifiedTimestamp >=
                cancelRequestToCloseCooldown,
            "MasterAgreement: INVALID_TAKER"
        );

        _updateQuoteState(maker, qid, QuoteState.OPEN);

        emit CancelRequestToClosePosition(maker, qid);
    }

    function acceptCloseRequest(
        address maker,
        uint256 qid,
        uint256 closedPrice,
        SchnorrSign[] memory solvencySignatures
    ) external onlyRole(TAKER_ROLE) notLiquidateUser(maker) {
        Quote storage quote = _quotes[maker][qid];
        require(quote.taker == msg.sender, "MasterAgreement: INVALID_TAKER");
        require(
            quote.quoteState == QuoteState.CLOSE_CANCELING ||
                quote.quoteState == QuoteState.CLOSE_PENDING,
            "MasterAgreement: INVALID_STATE"
        );
        quote.quoteState = QuoteState.CLOSED;
        quote.closedPrice = closedPrice;

        _balances[maker] += (quote.makerCVA + quote.makerIM);
        _balances[msg.sender] += (quote.takerCVA + quote.takerIM);
        _lockedCVA[maker] -= quote.makerCVA;
        _lockedCVA[msg.sender] -= quote.takerCVA;
        _lockedIM[maker] -= quote.makerIM;
        _lockedIM[msg.sender] -= quote.takerIM;

        (int256 makerShare, int256 takerShare) = calculatePnL(
            quote.positionType,
            quote.filledPrice,
            quote.closedPrice,
            quote.quantity
        );
        _balances[maker] = (makerShare < 0)
            ? (_balances[maker] - uint256(-makerShare))
            : (_balances[maker] + uint256(makerShare));
        _balances[msg.sender] = (takerShare < 0)
            ? (_balances[msg.sender] - uint256(-takerShare))
            : (_balances[msg.sender] + uint256(takerShare));

        _openQuotesLength[maker]--;
        _openQuotesLength[msg.sender]--;

        emit AcceptCloseRequest(maker, msg.sender, qid);
    }

    function calculatePnL(
        PositionType positionType,
        uint256 filledPrice,
        uint256 closedPrice,
        uint256 quantity
    ) public view returns (int256 makerShare, int256 takerShare) {
        int256 priceDiff = int256(closedPrice) - int256(filledPrice);
        int256 pnl = priceDiff * int256(quantity);
        (makerShare, takerShare) = positionType == PositionType.SHORT
            ? (-pnl, pnl)
            : (pnl, -pnl);
    }

    function liquidate(
        address maker,
        uint256 remainingBalance,
        SchnorrSign[] memory solvencySignatures,
        SchnorrSign[] memory balanceSignatures
    ) external {
        // todo: verify signatures
        _liquidationStatus[maker] = true;
        uint256 share = (remainingBalance * liquidatorShare) / scale;
        _balances[msg.sender] += share;
        _positionLiquidatorsShare[maker] =
            (remainingBalance - share) /
            _openQuotesLength[maker];
        _balances[maker] = 0;
        _lockedCVA[maker] = 0;
        _lockedIM[maker] = 0;

        emit Liquidate(msg.sender, maker, remainingBalance);
    }

    function liquidatePositions(
        address maker,
        uint256[] memory quotesIds,
        uint256[] memory priceList,
        SchnorrSign[][] memory priceSignatures
    ) external {
        require(_liquidationStatus[maker], "MasterAgreement: SOLVENT_USER");

        for (uint256 i = 0; i < quotesIds.length; i++) {
            Quote storage quote = _quotes[maker][quotesIds[i]];
            require(
                quote.quoteState == QuoteState.OPEN ||
                    quote.quoteState == QuoteState.CLOSE_PENDING ||
                    quote.quoteState == QuoteState.CLOSE_CANCELING,
                "MasterAgreement: INVALID_STATE"
            );
            // todo: verify priceSignatures

            (, int256 takerShare) = calculatePnL(
                quote.positionType,
                quote.filledPrice,
                priceList[i],
                quote.quantity
            );

            _balances[quote.taker] = (takerShare < 0)
                ? (_balances[quote.taker] - uint256(-takerShare))
                : (_balances[quote.taker] + uint256(takerShare));

            _balances[msg.sender] += _positionLiquidatorsShare[maker];

            _updateQuoteState(maker, quotesIds[i], QuoteState.LIQUIDATED);
            _openQuotesLength[maker]--;
            _openQuotesLength[quote.taker]--;

            emit LiquidatePosition(
                msg.sender,
                maker,
                quotesIds[i],
                _positionLiquidatorsShare[maker],
                takerShare
            );
        }

        if (_openQuotesLength[maker] == 0) {
            _liquidationStatus[maker] = false;
            _positionLiquidatorsShare[maker] = 0;

            emit Reset(maker);
        }
    }

    function setCancelQuoteCooldown(uint256 cooldown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit SetCancelQuoteCooldown(cancelQuoteCooldown, cooldown);
        cancelQuoteCooldown = cooldown;
    }

    function setCancelRequestToCloseCooldown(uint256 cooldown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit SetCancelRequestToCloseCooldown(
            cancelRequestToCloseCooldown,
            cooldown
        );
        cancelRequestToCloseCooldown = cooldown;
    }

    function setPerformCloseCooldown(uint256 cooldown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit SetPerformCloseCooldown(performCloseCooldown, cooldown);
        performCloseCooldown = cooldown;
    }

    function setLiquidationShare(uint256 share)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit SetLiquidationShare(liquidatorShare, share);
        liquidatorShare = share;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a < b) ? a : b;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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