// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);

    function validateIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external view;

    function validateDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external view;

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getBuyUsdeFeeBasisPoints(address _token, uint256 _usdeAmount)
        external
        view
        returns (uint256);

    function getSellUsdeFeeBasisPoints(address _token, uint256 _usdeAmount)
        external
        view
        returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdeAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdeDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

import "../../../core/interfaces/IVaultUtils.sol";

interface ITimelock {
    function setAdmin(address _admin) external;
    function setExternalAdmin(address _target, address _admin) external;
    function setContractHandler(address _handler, bool _isActive) external;
    function setKeeper(address _keeper, bool _isActive) external;
    function setBuffer(uint256 _buffer) external;
    function setMaxLeverage(address _vault, uint256 _maxLeverage) external;
    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;
    function setShouldToggleIsLeverageEnabled(bool _shouldToggleIsLeverageEnabled) external;
    function setMarginFeeBasisPoints(uint256 _marginFeeBasisPoints, uint256 _maxMarginFeeBasisPoints) external;
    function setSwapFees(address _vault, uint256 _taxBasisPoints, uint256 _stableTaxBasisPoints, uint256 _mintBurnFeeBasisPoints, uint256 _swapFeeBasisPoints, uint256 _stableSwapFeeBasisPoints) external;
    function setFees(address _vault, uint256 _taxBasisPoints, uint256 _stableTaxBasisPoints, uint256 _mintBurnFeeBasisPoints, uint256 _swapFeeBasisPoints, uint256 _stableSwapFeeBasisPoints, uint256 _marginFeeBasisPoints, uint256 _liquidationFeeUsd, uint256 _minProfitTime, bool _hasDynamicFees) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function setTokenConfig(address _vault, address _token, uint256 _tokenWeight, uint256 _minProfitBps, uint256 _maxUsdeAmount, uint256 _bufferAmount, uint256 _usdeAmount) external;
    function setUsdeAmounts(address _vault, address[] memory _tokens, uint256[] memory _usdeAmounts) external;
    function updateUsdeSupply(uint256 usdeAmount) external;
    function setEquityCooldownDuration(uint256 _cooldownDuration) external;
    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external;
    function removeAdmin(address _token, address _account) external;
    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external;
    function setTier(address _referralStorage, uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referralStorage, address _referrer, uint256 _tierId) external;
    function govSetCodeOwner(address _referralStorage, bytes32 _code, address _newAccount) external;
    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external;
    function setMaxGasPrice(address _vault, uint256 _maxGasPrice) external;
    function withdrawFees(address _vault, address _token, address _receiver) external;
    function batchWithdrawFees(address _vault, address[] memory _tokens) external;
    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _vault, address _liquidator, bool _isActive) external;
    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external;
    function batchSetBonusRewards(address _vester, address[] memory _accounts, uint256[] memory _amounts) external;
    function transferIn(address _sender, address _token, uint256 _amount) external;
    function signalApprove(address _token, address _spender, uint256 _amount) external;
    function approve(address _token, address _spender, uint256 _amount) external;
    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external;
    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external;
    function signalMint(address _token, address _receiver, uint256 _amount) external;
    function processMint(address _token, address _receiver, uint256 _amount) external;
    function signalSetGov(address _target, address _gov) external;
    function setGov(address _target, address _gov) external;
    function signalSetHandler(address _target, address _handler, bool _isActive) external;
    function setHandler(address _target, address _handler, bool _isActive) external;
    function signalSetPriceFeed(address _vault, address _priceFeed) external;
    function setPriceFeed(address _vault, address _priceFeed) external;
    function signalRedeemUsde(address _vault, address _token, uint256 _amount) external;
    function redeemUsde(address _vault, address _token, uint256 _amount) external;
    function signalVaultSetTokenConfig(address _vault, address _token, uint256 _tokenDecimals, uint256 _tokenWeight, uint256 _minProfitBps, uint256 _maxUsdeAmount, bool _isStable, bool _isShortable) external;
    function vaultSetTokenConfig(address _vault, address _token, uint256 _tokenDecimals, uint256 _tokenWeight, uint256 _minProfitBps, uint256 _maxUsdeAmount, bool _isStable, bool _isShortable) external;
    function cancelAction(bytes32 _action) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/IVaultUtils.sol";
import "./interfaces/timelockhandler/ITimelock.sol";

contract TimelockHandler {
    using SafeMath for uint256;

    address public admin;
    address public tokenManager;
    ITimelock public timelockContract;

    mapping (address => bool) public isHandler; // missing set functions
    mapping (address => bool) public isKeeper; // missing set functions

    address public feesCollector1;
    address public vault;
    address[] public tokens;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        address _tokenManager,
        ITimelock _timelockContract
    ) public {
        admin = _admin;
        tokenManager = _tokenManager;
        timelockContract = _timelockContract;
    }

    function setAdmin(address _admin) external onlyTokenManager {
        ITimelock(timelockContract).setAdmin(_admin);
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        ITimelock(timelockContract).setExternalAdmin(_target, _admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setContractHandler(_handler, _isActive);
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setKeeper(_keeper, _isActive);
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        ITimelock(timelockContract).setBuffer(_buffer);
    }

    function setMaxLeverage(address _vault, uint256 _maxLeverage) external onlyAdmin {
        ITimelock(timelockContract).setMaxLeverage(_vault, _maxLeverage);
    }

    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setFundingRate(_vault, _fundingInterval, _fundingRateFactor, _stableFundingRateFactor);
    }

    function setShouldToggleIsLeverageEnabled(bool _shouldToggleIsLeverageEnabled) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setShouldToggleIsLeverageEnabled(_shouldToggleIsLeverageEnabled);
    }

    function setMarginFeeBasisPoints(uint256 _marginFeeBasisPoints, uint256 _maxMarginFeeBasisPoints) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setMarginFeeBasisPoints(_marginFeeBasisPoints, _maxMarginFeeBasisPoints);
    }

    function setSwapFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setSwapFees(_vault, _taxBasisPoints, _stableTaxBasisPoints, _mintBurnFeeBasisPoints, _swapFeeBasisPoints, _stableSwapFeeBasisPoints);
    }

    // assign _marginFeeBasisPoints to this.marginFeeBasisPoints
    // because enableLeverage would update Vault.marginFeeBasisPoints to this.marginFeeBasisPoints
    // and disableLeverage would reset the Vault.marginFeeBasisPoints to this.maxMarginFeeBasisPoints
    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setFees(_vault, _taxBasisPoints, _stableTaxBasisPoints, _mintBurnFeeBasisPoints, _swapFeeBasisPoints, _stableSwapFeeBasisPoints, _marginFeeBasisPoints, _liquidationFeeUsd, _minProfitTime, _hasDynamicFees);
    }

    function enableLeverage(address _vault) external onlyHandlerAndAbove {
        ITimelock(timelockContract).enableLeverage(_vault);
    }

    function disableLeverage(address _vault) external onlyHandlerAndAbove {
        ITimelock(timelockContract).disableLeverage(_vault);
    }

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setIsLeverageEnabled(_vault, _isLeverageEnabled);
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdeAmount,
        uint256 _bufferAmount,
        uint256 _usdeAmount
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setTokenConfig(_vault, _token, _tokenWeight, _minProfitBps, _maxUsdeAmount, _bufferAmount, _usdeAmount);
    }

    function setUsdeAmounts(address _vault, address[] memory _tokens, uint256[] memory _usdeAmounts) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setUsdeAmounts(_vault, _tokens, _usdeAmounts);
    }

    function updateUsdeSupply(uint256 usdeAmount) external onlyKeeperAndAbove {
        ITimelock(timelockContract).updateUsdeSupply(usdeAmount);
    }

    function setEquityCooldownDuration(uint256 _cooldownDuration) external onlyAdmin {
        ITimelock(timelockContract).setEquityCooldownDuration(_cooldownDuration);
    }

    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).setMaxGlobalShortSize(_vault, _token, _amount);
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        ITimelock(timelockContract).removeAdmin(_token, _account);
    }

    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setIsSwapEnabled(_vault, _isSwapEnabled);
    }

    function setTier(address _referralStorage, uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setTier(_referralStorage, _tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referralStorage, address _referrer, uint256 _tierId) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setReferrerTier(_referralStorage, _referrer, _tierId);
    }

    function govSetCodeOwner(address _referralStorage, bytes32 _code, address _newAccount) external onlyKeeperAndAbove {
        ITimelock(timelockContract).govSetCodeOwner(_referralStorage, _code, _newAccount);
    }

    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external onlyAdmin {
        ITimelock(timelockContract).setVaultUtils(_vault, _vaultUtils);
    }

    function setMaxGasPrice(address _vault, uint256 _maxGasPrice) external onlyAdmin {
        ITimelock(timelockContract).setMaxGasPrice(_vault, _maxGasPrice);
    }

    function withdrawFees(address _vault, address _token, address _receiver) external onlyAdmin {
        ITimelock(timelockContract).withdrawFees(_vault, _token, _receiver);
    }

    function batchWithdrawFees(address _vault, address[] memory _tokens) external onlyKeeperAndAbove {
        ITimelock(timelockContract).batchWithdrawFees(_vault, _tokens);
    }

    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external onlyAdmin {
        ITimelock(timelockContract).setInPrivateLiquidationMode(_vault, _inPrivateLiquidationMode);
    }

    function setLiquidator(address _vault, address _liquidator, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setLiquidator(_vault, _liquidator, _isActive);
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        ITimelock(timelockContract).setInPrivateTransferMode(_token, _inPrivateTransferMode);
    }

    function batchSetBonusRewards(address _vester, address[] memory _accounts, uint256[] memory _amounts) external onlyKeeperAndAbove {
        ITimelock(timelockContract).batchSetBonusRewards(_vester, _accounts, _amounts);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).transferIn(_sender, _token, _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalApprove(_token, _spender, _amount);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).approve(_token, _spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalWithdrawToken(_target, _token, _receiver, _amount);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).withdrawToken(_target, _token, _receiver, _amount);
    }

    function signalMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalMint(_token, _receiver, _amount);
    }

    function processMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).processMint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external onlyAdmin {
        ITimelock(timelockContract).signalSetGov(_target, _gov);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        ITimelock(timelockContract).setGov(_target, _gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).signalSetHandler(_target, _handler, _isActive);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setHandler(_target, _handler, _isActive);
    }

    function signalSetPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        ITimelock(timelockContract).signalSetPriceFeed(_vault, _priceFeed);
    }

    function setPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        ITimelock(timelockContract).setPriceFeed(_vault, _priceFeed);
    }

    function signalRedeemUsde(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalRedeemUsde(_vault, _token, _amount);
    }

    function redeemUsde(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).redeemUsde(_vault, _token, _amount);
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdeAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        ITimelock(timelockContract).signalVaultSetTokenConfig(_vault, _token, _tokenDecimals, _tokenWeight, _minProfitBps, _maxUsdeAmount, _isStable, _isShortable);
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdeAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        ITimelock(timelockContract).vaultSetTokenConfig(_vault, _token, _tokenDecimals, _tokenWeight, _minProfitBps, _maxUsdeAmount, _isStable, _isShortable);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        ITimelock(timelockContract).cancelAction(_action);
    }

    /* NEW */
    function setTimelockHandlerAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setTimelockHandlerTokenManager(address _tokenManager) external onlyAdmin {
        tokenManager = _tokenManager;
    }

    function setTimelockHandlerKeeper(address _keeper, bool _status) external onlyAdmin {
        isKeeper[_keeper] = _status;
    }

    function setTimelockHandlerHandler(address _handler, bool _status) external onlyAdmin {
        isKeeper[_handler] = _status;
    }

    function setTimelockHandlerFeesConfig(address _feesCollector1) external onlyAdmin {
        feesCollector1 = _feesCollector1;
    }

    function setTimelockHandlerVaultAndTokens(address _vault, address[] memory _tokens) external onlyAdmin {
        vault = _vault;
        tokens = _tokens;
    }

    function claimFees() external {        
        ITimelock(timelockContract).batchWithdrawFees(vault, tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
            uint256 TKNamount = amount;
            
            safeTKNTransfer(tokens[i], feesCollector1, TKNamount);
        }
    }

    function safeTKNTransfer(address _token, address _to, uint256 _amount) internal {
        uint256 TKNBal = IERC20(_token).balanceOf(address(this));
        if (_amount > TKNBal) {
            IERC20(_token).transfer(_to, TKNBal);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}