pragma solidity ^0.8.4;

import "../BrokerBase/BrokerBase.sol";
import "../BrokerBase/TradeInteractor.sol";
import "../LiquidatorInteractors/LiquidatorInteractorOneToOneAssets.sol";

contract MarginBroker is
    BrokerBase,
    TradeInteractor,
    LiquidatorInteractorOneToOneAssets
{
    IERC20 borrowAsset;
    IERC20 boughtAsset;

    constructor(
        address _owner,
        IERC20 _boughtAsset,
        IMarketForBroker _borrowMM,
        IPriceOracleForBroker _borrowAssetOracle,
        IPriceOracleForBroker _boughtAssetOracle,
        IRegistryForBroker _registry
    ) BrokerBase(_owner, _registry) {
        IMarketForBroker[] memory markets = new IMarketForBroker[](1);
        markets[0] = _borrowMM;

        CollateralAsset[] memory extraAssets = new CollateralAsset[](1);
        extraAssets[0] = CollateralAsset(_boughtAsset, USE_FOR_CREDIT);

        initializeAssets(markets, extraAssets);

        IERC20 _borrowAsset = borrowAssets[0];
        _setAssetOracle(_borrowAsset, _borrowAssetOracle);
        _setAssetOracle(_boughtAsset, _boughtAssetOracle);

        boughtAsset = _boughtAsset;
        borrowAsset = _borrowAsset;
    }

    function deleverage(uint256 percentage, bytes calldata data)
        external
        virtual
        override
    {
        address user = msg.sender;
        accrueAllAndRefreshPositionsInternal(user);

        reducePosition(user, percentage, data);
        repayWithCollateral(borrowAsset, user);

        verifyCollateralLimit(user);
    }

    function liquidate(address user, bytes calldata data)
        external
        virtual
        override
    {
        Liquidator liquidator = Liquidator(msg.sender);

        accrueAllAndRefreshPositionsInternal(user);
        verifyLiquidationLimitBreached(user);

        uint256 debt0 = borrowerBorrowValue(user);
        uint256 liquidatorRewardValue = (debt0 * liquidatorShare) / 1e18;

        uint256 userBoughtAssetAmount = getUserCollateral(boughtAsset, user);
        uint256 amountForLiquidator = _min2(
            ((liquidatorRewardValue + debt0) * 1e18) / assetPrice(boughtAsset),
            userBoughtAssetAmount
        );
        reduceCollateral(boughtAsset, user, amountForLiquidator);

        uint256 borrowAssetReceived = callLiquidator(
            liquidator,
            boughtAsset,
            amountForLiquidator,
            borrowAsset,
            getBorrowPosition(borrowAsset, user).principal,
            data
        );
        addCollateral(borrowAsset, user, borrowAssetReceived);
        repayWithCollateral(borrowAsset, user);
        verifyNoDebt(borrowAsset, user);
    }

    function enterPosition(address user, bytes calldata data)
        internal
        virtual
        override
    {
        (ITradeAdapter trader, bytes memory tradeData) = abi.decode(
            data,
            (ITradeAdapter, bytes)
        );

        uint256 collateral = getUserCollateral(borrowAsset, user);

        (uint256 amountIn, uint256 amountOut) = trade(
            trader,
            borrowAsset,
            boughtAsset,
            collateral,
            0,
            tradeData
        );

        reduceCollateral(borrowAsset, user, amountIn);
        addCollateral(boughtAsset, user, amountOut);
    }

    function reducePosition(
        address user,
        uint256 percentage,
        bytes calldata data
    ) internal {
        (ITradeAdapter trader, bytes memory tradeData) = abi.decode(
            data,
            (ITradeAdapter, bytes)
        );

        uint256 sellAmount = (getUserCollateral(boughtAsset, user) *
            percentage) / 1e18;

        (uint256 amountIn, uint256 amountOut) = trade(
            trader,
            boughtAsset,
            borrowAsset,
            sellAmount,
            getBorrowPosition(borrowAsset, user).principal,
            tradeData
        );

        reduceCollateral(boughtAsset, user, amountIn);
        addCollateral(borrowAsset, user, amountOut);
    }
}

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./AssetsManager.sol";
import "../Interfaces/PriceOracle.sol";
import "./RegistryInteractor.sol";
import "../Interfaces/Liquidator.sol";

uint256 constant FULL_POSITION_PERCENTAGE = 1e18;

abstract contract BrokerBase is
    AssetsManager,
    RegistryInteractor,
    Ownable,
    ReentrancyGuard
{
    uint256 public liquidatorShare = 0.1 * 1e18;

    constructor(address _owner, IRegistryForBroker _registry)
        RegistryInteractor(_registry)
        Ownable()
    {
        _transferOwnership(_owner);
    }

    function setAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        external
        onlyOwner
    {
        _setAssetOracle(asset, oracle);
    }

    function setCollateralLimit(uint256 limit) external onlyOwner {
        _setCollateralLimit(limit);
    }

    function setLiquidationLimit(uint256 limit) external onlyOwner {
        _setLiquidationLimit(limit);
    }

    function setLiquidatorShare(uint256 share) external onlyOwner {
        liquidatorShare = share;
    }

    function deleverageByDeposit(
        address user,
        IERC20[] calldata assets,
        uint256[] calldata amounts
    ) external virtual {
        require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);
        for (uint8 index = 0; index < assets.length; index++) {
            _deposit(assets[index], user, amounts[index]);
        }

        accrueAllAndRefreshPositionsInternal(user);
        repayAllWithCollateral(user);

        verifyCollateralLimit(user);
    }

    function deleverage(uint256 percentage, bytes calldata data)
        external
        virtual;

    function leverageByWithdraw(
        IERC20[] calldata assets,
        uint256[] calldata amounts
    ) external virtual {
        require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);
        address user = msg.sender;

        for (uint8 index = 0; index < assets.length; index++) {
            _withdraw(assets[index], user, amounts[index]);
        }
        verifyCollateralLimit(user);
    }

    function leverage(
        IERC20[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        uint256 maxLeverage,
        bytes calldata data
    ) external virtual {
        address user = msg.sender;
        require(maxLeverage <= collateralLimit, INVALID_MAX_LEVERAGE);
        require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);

        accrueAllAndRefreshPositionsInternal(user);
        for (uint8 index = 0; index < assets.length; index++) {
            borrowUpdateCollateral(assets[index], user, amounts[index]);
        }

        enterPosition(user, data);
        verifyLeverageLevel(user, maxLeverage, MAX_LEVERAGE_BREACHED);
    }

    function enterPosition(address user, bytes calldata data) internal virtual {}

    function liquidate(address user, bytes calldata data) external virtual;
}

pragma solidity ^0.8.4;

import "./RegistryInteractor.sol";

abstract contract TradeInteractor is RegistryInteractor {
    function trade(
        ITradeAdapter trader,
        IERC20 assetIn,
        IERC20 assetOut,
        uint256 assetInCollateral,
        uint256 wantedOut,
        bytes memory payload
    ) internal returns (uint256 actualAmountIn, uint256 actualAmountOut) {
        verifyTraderWhitelisted(trader);

        uint256 inBalanceBefore = assetIn.balanceOf(address(this));
        uint256 outBalanceBefore = assetOut.balanceOf(address(this));
        assetIn.approve(address(trader), assetInCollateral);
        trader.trade(assetIn, assetOut, assetInCollateral, wantedOut, payload);
        assetIn.approve(address(trader), 0);

        actualAmountIn = inBalanceBefore - assetIn.balanceOf(address(this));
        actualAmountOut = assetOut.balanceOf(address(this)) - outBalanceBefore;
    }
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/Liquidator.sol";

contract LiquidatorInteractorOneToOneAssets {
    function callLiquidator(
        Liquidator liquidator,
        IERC20 sendAsset,
        uint256 amountSendToLiquidator,
        IERC20 borrowAsset,
        uint256 debtUnits,
        bytes calldata data
    ) internal returns (uint256 borrowAssetReceived) {
        IERC20[] memory assetsSent = new IERC20[](1);
        uint256[] memory amountsSent = new uint256[](1);
        IERC20[] memory assetsRequesting = new IERC20[](1);
        uint256[] memory amountsRequesting = new uint256[](1);

        assetsSent[0] = sendAsset;
        amountsSent[0] = amountSendToLiquidator;
        assetsRequesting[0] = borrowAsset;
        amountsRequesting[0] = debtUnits;

        sendAsset.transfer(address(liquidator), amountSendToLiquidator);
        uint256 amountBorrowAssetBefore = borrowAsset.balanceOf(address(this));
        liquidator.callback(
            assetsSent,
            amountsSent,
            assetsRequesting,
            amountsRequesting,
            data
        );
        borrowAssetReceived =
            borrowAsset.balanceOf(address(this)) -
            amountBorrowAssetBefore;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8;

import "./BorrowingManager.sol";
import "./CollateralsManager.sol";
import "../Interfaces/MoneyMarket.sol";
import "./BrokerErrorStrings.sol";

abstract contract AssetsManager is
    BorrowingManager,
    CollateralAccounter,
    BrokerErrorStrings
{
    uint256 public collateralLimit = 3e18;
    uint256 public liquidationLimit = 4e18;

    event Deposit(address borrower, address token, uint256 amount);
    event WithdrawCollateral(address borrower, uint256 amount);

    function initializeAssets(
        IMarketForBroker[] memory _borrowMMs,
        CollateralAsset[] memory _extraCollateralAssets
    ) internal {
        initializeBorrowingManager(_borrowMMs);
        initializeCollateralAccounter(
            createCollateralAssetsArray(_extraCollateralAssets)
        );
    }

    function createCollateralAssetsArray(
        CollateralAsset[] memory _extraCollateralAssets
    ) private view returns (CollateralAsset[] memory) {
        CollateralAsset[] memory collateralAssets = new CollateralAsset[](
            borrowAssets.length + _extraCollateralAssets.length
        );

        uint8 index = 0;
        for (; index < borrowAssets.length; index++) {
            collateralAssets[index] = CollateralAsset(
                borrowAssets[index],
                USE_FOR_CREDIT
            );
        }
        uint8 index2 = 0;
        while (index2 < _extraCollateralAssets.length) {
            collateralAssets[index++] = _extraCollateralAssets[index2++];
        }

        return collateralAssets;
    }

    function _setAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        internal
    {
        if (assetsMap[asset]) {
            _setCollateralAssetOracle(asset, oracle);
        }

        if (address(moneyMarkets[asset]) != address(0)) {
            _setBorrowAssetOracle(asset, oracle);
        }
    }

    function _setCollateralLimit(uint256 limit) internal {
        collateralLimit = limit;
    }

    function _setLiquidationLimit(uint256 limit) internal {
        liquidationLimit = limit;
    }

    function borrowUpdateCollateral(IERC20 asset, address user, uint256 amount) internal {
        uint256 balanceBefore = asset.balanceOf(address(this));
        _borrow(asset, user, amount);
        uint256 balanceAfter = asset.balanceOf(address(this));
        uint256 receivedAmount = balanceAfter - balanceBefore;
        addCollateral(asset, user, receivedAmount);
    }

    function _doTransferIn(
        address from,
        IERC20 token,
        uint256 amount
    ) private returns (uint256 actualReceived) {
        if (0 == amount) {
            return 0;
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 actualAmount = balanceAfter - balanceBefore;

        addCollateral(token, from, actualAmount);

        return actualAmount;
    }

    function _deposit(
        IERC20 asset,
        address borrower,
        uint256 amount 
    ) internal returns (uint256 actualReceived) {
        actualReceived = _doTransferIn(
            borrower,
            asset,
            amount
        );
        emit Deposit(borrower, address(asset), amount); 
    }

    function _withdraw(
        IERC20 asset,
        address borrower,
        uint256 amount
    ) internal {
        reduceCollateral(asset, borrower, amount);
        asset.transfer(borrower, amount);

        emit WithdrawCollateral(borrower, amount);
    }

    function repayWithCollateral(IERC20 asset, address user) internal returns (BorrowUserPosition memory position) {
        uint256 userCollateral = getUserCollateral(asset, user);
        position = getBorrowPosition(asset, user);
        uint256 userDebt = position.principal;
        uint256 amountToRepay = _min2(userCollateral, userDebt);
        uint256 leftovers = diffOrZero(userCollateral, userDebt);
        if (amountToRepay > 0) {
            setCollateral(asset, user, leftovers);
            position = _repay(asset, user, amountToRepay);
        }
    }

    function repayAllWithCollateral(address user) internal {
        for (uint8 index = 0; index < borrowAssets.length; index++) {
            repayWithCollateral(borrowAssets[index], user);
        }
    }

    function _creditValue(address borrower)
        public
        view
        virtual
        returns (uint256)
    {
        return userAllCreditingValue(borrower);
    }

    /**
     * @notice Returns the level of leverage for the borrower's position in mantissa
     */
    function leverageLevel(address borrower) public view returns (uint256) {
        uint256 borrowedValue = borrowerBorrowValue(borrower);
        if (borrowedValue == 0) {
            return 1e18;
        }
        uint256 creditValue = _creditValue(borrower);
        return (creditValue * 1e18) / (creditValue - borrowedValue);
    }

    function verifyLeverageLevel(
        address borrower,
        uint256 maxLeverage,
        string memory errorString
    ) public view {
        require(leverageLevel(borrower) <= maxLeverage, errorString);
    }

    /**
     * @notice This function assume that the borrowr's principal is updated (after accruing interest)
     */
    function verifyCollateralLimit(address borrower) public view {
        verifyLeverageLevel(
            borrower,
            collateralLimit,
            COLLATERAL_LIMIT_BREACHED
        );
    }

    function verifyLiquidationLimitBreached(address borrower) public view {
        require(
            leverageLevel(borrower) > liquidationLimit,
            LIQUIDATION_LIMIT_NOT_BREACHED
        );
    }

    function verifyNoDebt(IERC20 asset, address user) internal view {
        require(
            usersBorrowPositions[asset][user].principal == 0,
            EXPECTED_NO_DEBT
        );
    }
}

interface IPriceOracleForBroker {
    // function getAssetPrice(address asset) external view returns (uint256);
    function price(address asset) external view returns (uint256);
}

pragma solidity ^0.8.4;

import "../Interfaces/Registry.sol";
import "../../TradeAdapters/ITradeAdapter.sol";
import "./BrokerErrorStrings.sol";

contract RegistryInteractor is BrokerErrorStrings {
    IRegistryForBroker registry;

    constructor(IRegistryForBroker _registry) {
        registry = _registry;
    }

    function verifyTraderWhitelisted(ITradeAdapter trader) internal {
        // TODO: Add a cache mechanism
        require(
            registry.isSupportedTradeAdapter(address(trader)) == true,
            TRADER_NOT_WHITELISTED
        );
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Liquidator {
    function callback(
        IERC20[] calldata assetsReceived,
        uint256[] calldata amountsReceived,
        IERC20[] calldata assetsRequested,
        uint256[] calldata amountsRequested,
        bytes calldata data
    ) external;
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

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "../Interfaces/PriceOracle.sol";
import "../Interfaces/MoneyMarket.sol";

struct BorrowUserPosition {
    uint256 principal;
    uint256 borrowIndex;
}

abstract contract BorrowingManager {
    mapping(IERC20 => IMarketForBroker) public moneyMarkets;
    mapping(IERC20 => IPriceOracleForBroker) public borrowAssetsOracles;
    mapping(IERC20 => mapping(address => BorrowUserPosition))
        public usersBorrowPositions;

    IERC20[] public borrowAssets;

    bool private initialized = false;

    event SetOracle(address asset, address oracle);
    event Repay(address asset, address borrower, uint256 amount);
    event Borrow(
        address asset,
        address borrower,
        uint256 amount,
        uint256 positionPrincipal,
        uint256 positionBorrowIndex
    );

    function initializeBorrowingManager(IMarketForBroker[] memory _borrowMMs)
        internal
    {
        require(initialized == false, "Initialized");
        initialized = true;
        for (uint8 index = 0; index < _borrowMMs.length; index++) {
            IMarketForBroker mm = _borrowMMs[index];
            IERC20 asset = IERC20(mm.underlying());
            borrowAssets.push(asset);
            moneyMarkets[asset] = mm;
        }
    }

    function _setBorrowAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        internal
    {
        borrowAssetsOracles[asset] = oracle;
        emit SetOracle(address(asset), address(oracle));
    }

    /*******************/
    /****** Logic ******/
    /*******************/

    function _repayAll(IERC20 asset) internal {
        require(
            moneyMarkets[asset].accrueInterest() == 0,
            "accrue interest failed"
        );

        uint256 currentBorrow = calcCurrentBorrowAmount(
            usersBorrowPositions[asset][msg.sender],
            moneyMarkets[asset].borrowIndex()
        );
        _repay(asset, msg.sender, currentBorrow);
    }

    function updateBorrowerPosition(
        IERC20 asset,
        address borrower,
        uint256 borrowAddedAmount,
        uint256 borrowDeductedAmount
    ) internal returns (BorrowUserPosition memory position) {
        // We assume that we already accrued interest
        position = usersBorrowPositions[asset][borrower];
        uint256 borrowMarketIndex = moneyMarkets[asset].borrowIndex();
        position.principal =
            calcCurrentBorrowAmount(position, borrowMarketIndex) +
            borrowAddedAmount -
            borrowDeductedAmount;
        position.borrowIndex = borrowMarketIndex;
        usersBorrowPositions[asset][borrower] = position;
    }

    function updateBorrowerPositionPrincipal(
        IERC20 asset,
        address borrower,
        uint256 addPricipal,
        uint256 reducePrincipal
    ) internal {
        uint256 principalBefore = usersBorrowPositions[asset][borrower]
            .principal;
        usersBorrowPositions[asset][borrower].principal =
            principalBefore +
            addPricipal -
            reducePrincipal;
    }

    function refreshBorrowerPositionAssets(
        IERC20[] memory assets,
        address borrower
    ) internal {
        // We assume that we already accrued interest
        for (uint8 index = 0; index < assets.length; index++) {
            updateBorrowerPosition(assets[index], borrower, 0, 0);
        }
    }

    function refreshBorrowerPositionAll(address borrower) internal {
        refreshBorrowerPositionAssets(borrowAssets, borrower);
    }

    function _borrow(
        IERC20 asset,
        address borrower,
        uint256 amount
    ) internal {
        require(0 == moneyMarkets[asset].borrow(amount), "Failed borrowing");
        BorrowUserPosition memory position = updateBorrowerPosition(
            asset,
            borrower,
            amount,
            0
        );
        emit Borrow(
            address(asset),
            borrower,
            amount,
            position.principal,
            position.borrowIndex
        );
    }

    function accrueInterestForAsset(IERC20 asset) internal {
        require(
            moneyMarkets[asset].accrueInterest() == 0,
            "accrue interest failed"
        );
    }

    function accrueInterestAssets(IERC20[] memory assets) internal {
        for (uint8 index = 0; index < assets.length; index++) {
            accrueInterestForAsset(assets[index]);
        }
    }

    function accrueInterestAll() internal {
        accrueInterestAssets(borrowAssets);
    }

    // Assumes interest was accrued already
    function _repay(
        IERC20 asset,
        address borrower,
        uint256 amount
    ) internal returns (BorrowUserPosition memory position) {
        IMarketForBroker market = moneyMarkets[asset];
        uint256 totalDebt = market.borrowBalanceStored(address(this));
        position = updateBorrowerPosition(asset, borrower, 0, amount);
        amount = _min2(totalDebt, amount);
        asset.approve(address(market), amount);
        require(0 == market.repayBorrow(amount), "Failed repay");

        emit Repay(address(asset), borrower, amount);
    }

    function _repay_bkp(
        IERC20 asset,
        address borrower,
        uint256 amount,
        bool needToAccrue
    ) internal {
        IMarketForBroker market = moneyMarkets[asset];
        if (needToAccrue) {
            require(market.accrueInterest() == 0, "accrue interest failed");
        }
        uint256 totalDebt = market.borrowBalanceStored(address(this));
        updateBorrowerPosition(asset, borrower, 0, amount);

        amount = _min2(totalDebt, amount);
        asset.approve(address(market), amount);
        require(0 == market.repayBorrow(amount), "Failed repay");

        emit Repay(address(asset), borrower, amount);
    }

    function borrowValue(IERC20 asset, uint256 amount)
        internal
        view
        virtual
        returns (uint256)
    {
        if (amount == 0) return 0;

        IPriceOracleForBroker oracle = borrowAssetsOracles[asset];
        uint256 price = oracle.price(address(asset));
        return
            (price * amount) / (10**IERC20Metadata(address(asset)).decimals());
    }

    function borrowerAssetBorrowValue(IERC20 asset, address borrower)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            borrowValue(asset, usersBorrowPositions[asset][borrower].principal);
    }

    function borrowerBorrowValue(address borrower)
        public
        view
        virtual
        returns (uint256 totalDebt)
    {
        totalDebt = 0;
        for (uint8 index = 0; index < borrowAssets.length; index++) {
            totalDebt += borrowerAssetBorrowValue(
                borrowAssets[index],
                borrower
            );
        }
    }

    /*******************/
    /****** Utils ******/
    /*******************/

    function _min2(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _min3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return _min2(_min2(a, b), c);
    }

    function diffOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : 0;
    }

    /*******************/
    /****** Views ******/
    /*******************/

    function borrowerBalanceCurrent(IERC20 asset, address borrower)
        external
        returns (uint256)
    {
        IMarketForBroker market = moneyMarkets[asset];
        require(market.accrueInterest() == 0, "accrue interest failed");

        BorrowUserPosition memory position = updateBorrowerPosition(
            asset,
            borrower,
            0,
            0
        );
        return position.principal;
    }

    function calcCurrentBorrowAmount(
        BorrowUserPosition memory position,
        uint256 currentMarketIndex
    ) public pure returns (uint256 updatedAmount) {
        if (0 == position.principal) {
            return 0;
        }
        return (position.principal * currentMarketIndex) / position.borrowIndex;
    }

    function accrueAllAndRefreshPositionsInternal(address borrower) internal {
        accrueInterestAll();
        refreshBorrowerPositionAll(borrower);
    }

    function accrueAllAndRefreshPositions(address borrower) external {
        accrueAllAndRefreshPositionsInternal(borrower);
    }

    function getBorrowPosition(IERC20 asset, address user)
        public
        view
        returns (BorrowUserPosition memory position)
    {
        return usersBorrowPositions[asset][user];
    }

    function getBorrowAssets() external view returns (IERC20[] memory) {
        return borrowAssets;
    }
}

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "../Interfaces/PriceOracle.sol";

struct CollateralAsset {
    IERC20 token;
    bool useAsCredit;
}

bool constant USE_FOR_CREDIT = true;
bool constant DONT_USE_FOR_CREDIT = true;

abstract contract CollateralAccounter {
    mapping(IERC20 => mapping(address => uint256)) usersTokensCollaterals;
    mapping(IERC20 => IPriceOracleForBroker) collateralAssetsOracles;
    IERC20[] collateralAssets;
    IERC20[] creditingAssets;
    mapping(IERC20 => bool) assetsMap;

    bool private initialized = false;

    function initializeCollateralAccounter(CollateralAsset[] memory _assets)
        internal
    {
        require(initialized == false, "Initialized");
        initialized = true;

        for (uint8 index = 0; index < _assets.length; index++) {
            CollateralAsset memory asset = _assets[index];
            assetsMap[asset.token] = true;
            collateralAssets.push(asset.token);
            if (asset.useAsCredit) {
                creditingAssets.push(asset.token);
            }
        }
    }

    function setCollateral(
        IERC20 asset,
        address user,
        uint256 amount
    ) internal {
        usersTokensCollaterals[asset][user] = amount;
    }

    function addCollateral(
        IERC20 asset,
        address user,
        uint256 amount
    ) internal {
        usersTokensCollaterals[asset][user] += amount;
    }

    function reduceCollateral(
        IERC20 asset,
        address user,
        uint256 amount
    ) internal {
        usersTokensCollaterals[asset][user] -= amount;
    }

    // Returns the user's collateral value before setting it to 0;
    function resetCollateral(IERC20 asset, address user)
        internal
        returns (uint256 valueBefore)
    {
        valueBefore = usersTokensCollaterals[asset][user];
        if (valueBefore > 0) {
            usersTokensCollaterals[asset][user] = 0;
        }
    }

    function getUserCollateral(IERC20 asset, address user)
        public
        view
        returns (uint256)
    {
        return usersTokensCollaterals[asset][user];
    }

    function _setCollateralAssetOracle(
        IERC20 asset,
        IPriceOracleForBroker oracle
    ) internal {
        collateralAssetsOracles[asset] = oracle;
    }

    function assetPrice(IERC20 asset) public view returns (uint256) {
        IPriceOracleForBroker oracle = collateralAssetsOracles[asset];
        if (IPriceOracleForBroker(address(0)) == oracle) return 0;

        return oracle.price(address(asset));
    }

    function collateralValue(IERC20 asset, uint256 amount)
        internal
        view
        virtual
        returns (uint256)
    {
        if (0 == amount) return 0;
        return
            (assetPrice(asset) * amount) /
            (10**IERC20Metadata(address(asset)).decimals());
    }

    function userCollateralValue(address user, IERC20 asset)
        internal
        view
        returns (uint256)
    {
        return collateralValue(asset, usersTokensCollaterals[asset][user]);
    }

    function userAllCreditingValue(address user)
        internal
        view
        virtual
        returns (uint256 totalValue)
    {
        totalValue = 0;
        for (uint8 index = 0; index < creditingAssets.length; index++) {
            totalValue += userCollateralValue(user, creditingAssets[index]);
        }
    }

    function assetBalance(IERC20 asset) internal view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function getCollateralAssets() external view returns (IERC20[] memory) {
        return collateralAssets;
    }

    function getCreditingAssets() external view returns (IERC20[] memory) {
        return creditingAssets;
    }
}

interface IMarketForBroker {
    function underlying() external view returns (address);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256 error);

    function repayBorrow(uint256 repayAmount) external returns (uint256 error);

    function accrueInterest() external returns (uint256 error);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.4;

abstract contract BrokerErrorStrings {
    string constant ARRAYS_NOT_SAME_LENGTH = "!Arrays length match";
    string constant TRADER_NOT_WHITELISTED = "!Trader";
    string constant INVALID_MAX_LEVERAGE = "Max leverage invalid";
    string constant MAX_LEVERAGE_BREACHED = "Max leverage breached";
    string constant COLLATERAL_LIMIT_BREACHED = "!CollateralLimit";
    string constant LIQUIDATION_LIMIT_NOT_BREACHED = "!LiquidationLimit";
    string constant EXPECTED_NO_DEBT = "HasDebt";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

pragma solidity ^0.8.4;

interface IRegistryForBroker {
    function isSupportedTradeAdapter(address trader) external returns (bool);
}

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ITradeAdapter {
    function trade(
        IERC20 source,
        IERC20 target,
        uint256 maxAmountIn,
        uint256 wantedOut,
        bytes calldata payload
    ) external returns (uint256);
}