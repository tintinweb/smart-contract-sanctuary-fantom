// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {StrategyLib} from "./StrategyLib.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;
    string public metadataURI;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    modifier onlyEmergencyAuthorized() {
        _onlyEmergencyAuthorized();
        _;
    }

    modifier onlyStrategist() {
        _onlyStrategist();
        _;
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    modifier onlyRewarder() {
        _onlyRewarder();
        _;
    }

    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }

    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance());
    }

    function _onlyEmergencyAuthorized() internal {
        require(
            msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyRewarder() internal {
        require(msg.sender == governance() || msg.sender == strategist);
    }

    function _onlyKeepers() internal {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        SafeERC20.safeApprove(want, _vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, type(uint256).max); // Allow rewards to be pulled
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyRewarder {
        address oldRewards = rewards;
        rewards = _rewards;
        StrategyLib.internalSetRewards(oldRewards, _rewards, address(vault));
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI)
        external
        onlyAuthorized
    {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 180000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return
            vault.strategies(address(this)).debtRatio > 0 ||
            estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function liquidateAllPositions()
        internal
        virtual
        returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);

        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        return
            StrategyLib.internalHarvestTrigger(
                address(vault),
                address(this),
                ethToWant(callCostInWei),
                minReportDelay,
                maxReportDelay,
                debtThreshold,
                profitFactor
            );
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        SafeERC20.safeTransfer(want, msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        SafeERC20.safeTransfer(
            want,
            _newStrategy,
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++)
            require(_token != _protectedTokens[i], "!protected");

        SafeERC20.safeTransfer(
            IERC20(_token),
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);

    constructor(address _vault) public BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        return this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper
        );

        emit Cloned(newStrategy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {StrategyParams, VaultAPI, StrategyAPI} from "./BaseStrategy.sol";

library StrategyLib {
    using SafeMath for uint256;

    function internalHarvestTrigger(
        address vault,
        address strategy,
        uint256 callCost,
        uint256 minReportDelay,
        uint256 maxReportDelay,
        uint256 debtThreshold,
        uint256 profitFactor
    ) public view returns (bool) {
        StrategyParams memory params = VaultAPI(vault).strategies(strategy);
        // Should not trigger if Strategy is not activated
        if (params.activation == 0) {
            return false;
        }

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay)
            return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay)
            return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = VaultAPI(vault).debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = StrategyAPI(strategy).estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = VaultAPI(vault).creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    function internalSetRewards(
        address oldRewards,
        address newRewards,
        address vault
    ) public {
        require(newRewards != address(0));
        VaultAPI(vault).approve(oldRewards, 0);
        VaultAPI(vault).approve(newRewards, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {BaseStrategy} from "../BaseStrategy.sol";

// Part: IGenericLender

interface IGenericLender {
    function lenderName() external view returns (string memory);

    function nav() external view returns (uint256);

    function strategy() external view returns (address);

    function apr() external view returns (uint256);

    function weightedApr() external view returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

    function emergencyWithdraw(uint256 amount) external;

    function deposit() external;

    function withdrawAll() external returns (bool);

    function hasAssets() external view returns (bool);

    function aprAfterDeposit(uint256 amount) external view returns (uint256);

    function setDust(uint256 _dust) external;

    function sweep(address _token) external;
}

// Part: IUni

interface IUni {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// Part: IWantToEth

interface IWantToEth {
    function wantToEth(uint256 input) external view returns (uint256);

    function ethToWant(uint256 input) external view returns (uint256);
}

contract StrategyLenderYieldOptimiser is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant UNISWAP_ROUTER =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    uint256 public withdrawalThreshold = 1e16;
    uint256 public constant SECONDSPERYEAR = 31556952;

    IGenericLender[] public lenders;
    bool public externalOracle; // default is false
    address public wantToEthOracle;

    event Cloned(address indexed clone);

    constructor(address _vault) public BaseStrategy(_vault) {
        debtThreshold = 100 * 1e18;
    }

    function clone(address _vault) external returns (address newStrategy) {
        newStrategy = this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        StrategyLenderYieldOptimiser(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper
        );

        emit Cloned(newStrategy);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function setWithdrawalThreshold(uint256 _threshold)
        external
        onlyAuthorized
    {
        withdrawalThreshold = _threshold;
    }

    function setPriceOracle(address _oracle) external onlyAuthorized {
        wantToEthOracle = _oracle;
    }

    function name() external view override returns (string memory) {
        return "StrategyLenderYieldOptimiser";
    }

    //management functions
    //add lenders for the strategy to choose between
    // only governance to stop strategist adding dodgy lender
    function addLender(address a) public onlyGovernance {
        IGenericLender n = IGenericLender(a);
        require(n.strategy() == address(this), "Undocked Lender");

        for (uint256 i = 0; i < lenders.length; i++) {
            require(a != address(lenders[i]), "Already Added");
        }
        lenders.push(n);
    }

    //but strategist can remove for safety
    function safeRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, false);
    }

    function forceRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, true);
    }

    //force removes the lender even if it still has a balance
    function _removeLender(address a, bool force) internal {
        for (uint256 i = 0; i < lenders.length; i++) {
            if (a == address(lenders[i])) {
                bool allWithdrawn = lenders[i].withdrawAll();

                if (!force) {
                    require(allWithdrawn, "WITHDRAW FAILED");
                }

                //put the last index here
                //remove last index
                if (i != lenders.length - 1) {
                    lenders[i] = lenders[lenders.length - 1];
                }

                //pop shortens array by 1 thereby deleting the last index
                lenders.pop();

                //if balance to spend we might as well put it into the best lender
                if (want.balanceOf(address(this)) > 0) {
                    adjustPosition(0);
                }
                return;
            }
        }
        require(false, "NOT LENDER");
    }

    //we could make this more gas efficient but it is only used by a view function
    struct LendStatus {
        string name;
        uint256 assets;
        uint256 rate;
        address add;
    }

    //Returns the status of all lenders attached the strategy
    function lendStatuses() public view returns (LendStatus[] memory) {
        LendStatus[] memory statuses = new LendStatus[](lenders.length);
        for (uint256 i = 0; i < lenders.length; i++) {
            LendStatus memory s;
            s.name = lenders[i].lenderName();
            s.add = address(lenders[i]);
            s.assets = lenders[i].nav();
            s.rate = lenders[i].apr();
            statuses[i] = s;
        }

        return statuses;
    }

    // lent assets plus loose assets
    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 nav = lentTotalAssets();
        nav = nav.add(want.balanceOf(address(this)));

        return nav;
    }

    function numLenders() public view returns (uint256) {
        return lenders.length;
    }

    //the weighted apr of all lenders. sum(nav * apr)/totalNav
    function estimatedAPR() public view returns (uint256) {
        uint256 bal = estimatedTotalAssets();
        if (bal == 0) {
            return 0;
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            weightedAPR = weightedAPR.add(lenders[i].weightedApr());
        }

        return weightedAPR.div(bal);
    }

    //Estimates the impact on APR if we add more money. It does not take into account adjusting position
    function _estimateDebtLimitIncrease(uint256 change)
        internal
        view
        returns (uint256)
    {
        uint256 highestAPR = 0;
        uint256 aprChoice = 0;
        uint256 assets = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr > highestAPR) {
                aprChoice = i;
                highestAPR = apr;
                assets = lenders[i].nav();
            }
        }

        uint256 weightedAPR = highestAPR.mul(assets.add(change));

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {
                weightedAPR = weightedAPR.add(lenders[i].weightedApr());
            }
        }

        uint256 bal = estimatedTotalAssets().add(change);

        return weightedAPR.div(bal);
    }

    //Estimates debt limit decrease. It is not accurate and should only be used for very broad decision making
    function _estimateDebtLimitDecrease(uint256 change)
        internal
        view
        returns (uint256)
    {
        uint256 lowestApr = uint256(-1);
        uint256 aprChoice = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr < lowestApr) {
                aprChoice = i;
                lowestApr = apr;
            }
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {
                weightedAPR = weightedAPR.add(lenders[i].weightedApr());
            } else {
                uint256 asset = lenders[i].nav();
                if (asset < change) {
                    //simplistic. not accurate
                    change = asset;
                }
                weightedAPR = weightedAPR.add(lowestApr.mul(change));
            }
        }
        uint256 bal = estimatedTotalAssets().add(change);
        return weightedAPR.div(bal);
    }

    //estimates highest and lowest apr lenders. Public for debugging purposes but not much use to general public
    function estimateAdjustPosition()
        public
        view
        returns (
            uint256 _lowest,
            uint256 _lowestApr,
            uint256 _highest,
            uint256 _potential
        )
    {
        //all loose assets are to be invested
        uint256 looseAssets = want.balanceOf(address(this));

        // our simple algo
        // get the lowest apr strat
        // cycle through and see who could take its funds plus want for the highest apr
        _lowestApr = uint256(-1);
        _lowest = 0;
        uint256 lowestNav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {
            if (lenders[i].hasAssets()) {
                uint256 apr = lenders[i].apr();
                if (apr < _lowestApr) {
                    _lowestApr = apr;
                    _lowest = i;
                    lowestNav = lenders[i].nav();
                }
            }
        }

        uint256 toAdd = lowestNav.add(looseAssets);

        uint256 highestApr = 0;
        _highest = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr;
            apr = lenders[i].aprAfterDeposit(looseAssets);

            if (apr > highestApr) {
                highestApr = apr;
                _highest = i;
            }
        }

        //if we can improve apr by withdrawing we do so
        _potential = lenders[_highest].aprAfterDeposit(toAdd);
    }

    //gives estiomate of future APR with a change of debt limit. Useful for governance to decide debt limits
    function estimatedFutureAPR(uint256 newDebtLimit)
        public
        view
        returns (uint256)
    {
        uint256 oldDebtLimit = vault.strategies(address(this)).totalDebt;
        uint256 change;
        if (oldDebtLimit < newDebtLimit) {
            change = newDebtLimit - oldDebtLimit;
            return _estimateDebtLimitIncrease(change);
        } else {
            change = oldDebtLimit - newDebtLimit;
            return _estimateDebtLimitDecrease(change);
        }
    }

    //cycle all lenders and collect balances
    function lentTotalAssets() public view returns (uint256) {
        uint256 nav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {
            nav = nav.add(lenders[i].nav());
        }
        return nav;
    }

    // we need to free up profit plus _debtOutstanding.
    // If _debtOutstanding is more than we can free we get as much as possible
    // should be no way for there to be a loss. we hope...
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _profit = 0;
        _loss = 0; //for clarity
        _debtPayment = _debtOutstanding;

        uint256 lentAssets = lentTotalAssets();

        uint256 looseAssets = want.balanceOf(address(this));

        uint256 total = looseAssets.add(lentAssets);

        if (lentAssets == 0) {
            //no position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                //we can only return looseAssets
                _debtPayment = looseAssets;
            }

            return (_profit, _loss, _debtPayment);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if (total > debt) {
            _profit = total - debt;

            uint256 amountToFree = _profit.add(_debtPayment);
            //we need to add outstanding to our profit
            //dont need to do logic if there is nothiing to free
            if (amountToFree > 0 && looseAssets < amountToFree) {
                //withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                //if we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(
                            newLoose - _profit,
                            _debtPayment
                        );
                    }
                }
            }
        } else {
            //serious loss should never happen but if it does lets record it accurately
            _loss = debt - total;
            uint256 amountToFree = _loss.add(_debtPayment);

            if (amountToFree > 0 && looseAssets < amountToFree) {
                //withdraw what we can withdraw

                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                //if we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_loss > newLoose) {
                        _loss = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _loss, _debtPayment);
                    }
                }
            }
        }
    }

    /*
     * Key logic.
     *   The algorithm moves assets from lowest return to highest
     *   like a very slow idiots bubble sort
     *   we ignore debt outstanding for an easy life
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        _debtOutstanding; //ignored. we handle it in prepare return
        //emergency exit is dealt with at beginning of harvest
        if (emergencyExit) {
            return;
        }

        //we just keep all money in want if we dont have any lenders
        if (lenders.length == 0) {
            return;
        }

        (
            uint256 lowest,
            uint256 lowestApr,
            uint256 highest,
            uint256 potential
        ) = estimateAdjustPosition();

        if (potential > lowestApr) {
            //apr should go down after deposit so wont be withdrawing from self
            lenders[lowest].withdrawAll();
        }

        uint256 bal = want.balanceOf(address(this));
        if (bal > 0) {
            want.safeTransfer(address(lenders[highest]), bal);
            lenders[highest].deposit();
        }
    }

    struct LenderRatio {
        address lender;
        //share x 1000
        uint16 share;
    }

    //share must add up to 1000. 500 means 50% etc
    function manualAllocation(LenderRatio[] memory _newPositions)
        public
        onlyAuthorized
    {
        uint256 share = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            lenders[i].withdrawAll();
        }

        uint256 assets = want.balanceOf(address(this));

        for (uint256 i = 0; i < _newPositions.length; i++) {
            bool found = false;

            //might be annoying and expensive to do this second loop but worth it for safety
            for (uint256 j = 0; j < lenders.length; j++) {
                if (address(lenders[j]) == _newPositions[i].lender) {
                    found = true;
                }
            }
            require(found, "NOT LENDER");

            share = share.add(_newPositions[i].share);
            uint256 toSend = assets.mul(_newPositions[i].share).div(1000);
            want.safeTransfer(_newPositions[i].lender, toSend);
            IGenericLender(_newPositions[i].lender).deposit();
        }

        require(share == 1000, "SHARE!=1000");
    }

    //cycle through withdrawing from worst rate first
    function _withdrawSome(uint256 _amount)
        internal
        returns (uint256 amountWithdrawn)
    {
        if (lenders.length == 0) {
            return 0;
        }

        //dont withdraw dust
        if (_amount < withdrawalThreshold) {
            return 0;
        }

        amountWithdrawn = 0;
        //most situations this will only run once. Only big withdrawals will be a gas guzzler
        uint256 j = 0;
        while (amountWithdrawn < _amount) {
            uint256 lowestApr = uint256(-1);
            uint256 lowest = 0;
            for (uint256 i = 0; i < lenders.length; i++) {
                if (lenders[i].hasAssets()) {
                    uint256 apr = lenders[i].apr();
                    if (apr < lowestApr) {
                        lowestApr = apr;
                        lowest = i;
                    }
                }
            }
            if (!lenders[lowest].hasAssets()) {
                return amountWithdrawn;
            }
            amountWithdrawn = amountWithdrawn.add(
                lenders[lowest].withdraw(_amount - amountWithdrawn)
            );
            j++;
            //dont want infinite loop
            if (j >= 6) {
                return amountWithdrawn;
            }
        }
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _amountFreed, uint256 _loss)
    {
        uint256 _balance = want.balanceOf(address(this));

        if (_balance >= _amountNeeded) {
            //if we don't set reserve here withdrawer will be sent our full balance
            return (_amountNeeded, 0);
        } else {
            uint256 received = _withdrawSome(_amountNeeded - _balance).add(
                _balance
            );
            if (received >= _amountNeeded) {
                return (_amountNeeded, 0);
            } else {
                return (received, 0);
            }
        }
    }

    function ethToWant(uint256 _amount) public view override returns (uint256) {
        //three situations
        //1 currency is eth so no change.
        //2 we use external oracle
        //3 we use uniswap swap price
        if (address(want) == WETH) {
            return _amount;
        } else if (wantToEthOracle != address(0)) {
            return IWantToEth(wantToEthOracle).ethToWant(_amount);
        }

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(want);

        uint256[] memory amounts = IUni(UNISWAP_ROUTER).getAmountsOut(
            _amount,
            path
        );
        return amounts[amounts.length - 1];
    }

    function tendTrigger(uint256 callCost) public view override returns (bool) {
        // make sure to call tendtrigger with same callcost as harvestTrigger
        if (harvestTrigger(callCost)) {
            return false;
        }

        //now let's check if there is better apr somewhere else.
        //If there is and profit potential is worth changing then lets do it
        (
            uint256 lowest,
            uint256 lowestApr,
            ,
            uint256 potential
        ) = estimateAdjustPosition();

        //if protential > lowestApr it means we are changing horses
        if (potential > lowestApr) {
            uint256 nav = lenders[lowest].nav();

            //To calculate our potential profit increase we work out how much extra
            //we would make in a typical harvest interlude. That is maxReportingDelay
            //then we see if the extra profit is worth more than the gas cost * profitFactor

            //safe math not needed here
            //apr is scaled by 1e18 so we downscale here
            uint256 profitIncrease = (nav.mul(potential) - nav.mul(lowestApr))
                .div(1e18)
                .mul(maxReportDelay)
                .div(SECONDSPERYEAR);

            uint256 wantCallCost = ethToWant(callCost);

            return (wantCallCost.mul(profitFactor) < profitIncrease);
        }
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        _amountFreed = _withdrawSome(lentTotalAssets());
    }

    /*
     * revert if we can't withdraw full balance
     */
    function prepareMigration(address _newStrategy) internal override {
        uint256 outstanding = vault.strategies(address(this)).totalDebt;
        (, uint256 loss, uint256 wantBalance) = prepareReturn(outstanding);
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {BaseStrategy} from "../BaseStrategy.sol";
import {VaultAPI} from "../interfaces/VaultAPI.sol";

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
}

interface CTokenI {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

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
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface CErc20I is CTokenI {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenI cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function comptroller() external view returns (address);
}

interface ComptrollerI {
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /***  Comp claims ****/
    function claimComp(address holder) external;

    function claimComp(address holder, CTokenI[] memory cTokens) external;

    function markets(address ctoken)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function compSpeeds(address ctoken) external view returns (uint256); // will be deprecated

    function compSupplySpeeds(address ctoken) external view returns (uint256);

    function compBorrowSpeeds(address ctoken) external view returns (uint256);

    function oracle() external view returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface InterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256, uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

contract LevCompFactory {
    address public immutable original;

    event Cloned(address indexed clone);
    event Deployed(address indexed original);

    constructor(
        address _vault,
        address _cToken,
        address _router,
        address _comp,
        address _comptroller,
        address _weth,
        uint256 _secondsPerBlock
    ) public {
        GenLevCompV3NoFlash _original = new GenLevCompV3NoFlash(
            _vault,
            _cToken,
            _router,
            _comp,
            _comptroller,
            _weth,
            _secondsPerBlock
        );
        emit Deployed(address(_original));

        original = address(_original);
        _original.setStrategist(msg.sender);
    }

    function name() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Factory",
                    GenLevCompV3NoFlash(payable(original)).name(),
                    "@",
                    GenLevCompV3NoFlash(payable(original)).apiVersion()
                )
            );
    }

    function cloneLevComp(
        address _vault,
        address _cToken,
        address _router,
        address _comp,
        address _comptroller,
        address _weth,
        uint256 _secondsPerBlock
    ) external returns (address payable newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(original);
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        GenLevCompV3NoFlash(newStrategy).initialize(
            _vault,
            _cToken,
            _router,
            _comp,
            _comptroller,
            _weth,
            _secondsPerBlock
        );
        GenLevCompV3NoFlash(newStrategy).setRewards(msg.sender);
        GenLevCompV3NoFlash(newStrategy).setStrategist(msg.sender);

        emit Cloned(newStrategy);
    }
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract GenLevCompV3NoFlash is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Comptroller address for compound.finance
    ComptrollerI public compound;

    //Only three tokens we use
    address public comp;
    address public weth;
    CErc20I public cToken;

    uint256 private secondsPerBlock; //1 for fantom. 13 for ethereum

    IUniswapV2Router02 public currentRouter; //uni v2 forks only

    uint256 public collateralTarget; // total borrow / total supply ratio we are targeting (100% = 1e18)
    uint256 private blocksToLiquidationDangerZone; // minimum number of blocks before liquidation

    uint256 public minWant; // minimum amount of want to act on

    // Rewards handling
    bool public dontClaimComp; // enable/disables COMP claiming
    uint256 public minCompToSell; // minimum amount of COMP to be sold

    uint256 public iterations; //number of loops we do

    bool public forceMigrate;
    bool public withdrawChecks;

    bool public splitCompDistribution;

    constructor(
        address _vault,
        address _cToken,
        address _router,
        address _comp,
        address _comptroller,
        address _weth,
        uint256 _secondsPerBlock
    ) public BaseStrategy(_vault) {
        _initializeThis(
            _cToken,
            _router,
            _comp,
            _comptroller,
            _weth,
            _secondsPerBlock
        );
    }

    function approveTokenMax(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    function name() external view override returns (string memory) {
        return "GenLevCompV3NoFlash";
    }

    function initialize(
        address _vault,
        address _cToken,
        address _router,
        address _comp,
        address _comptroller,
        address _weth,
        uint256 _secondsPerBlock
    ) external {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
        _initializeThis(
            _cToken,
            _router,
            _comp,
            _comptroller,
            _weth,
            _secondsPerBlock
        );
    }

    function _initializeThis(
        address _cToken,
        address _router,
        address _comp,
        address _comptroller,
        address _weth,
        uint256 _secondsPerBlock
    ) internal {
        cToken = CErc20I(_cToken);
        comp = _comp;
        weth = _weth;
        secondsPerBlock = _secondsPerBlock;
        compound = ComptrollerI(_comptroller);
        require(IERC20Extended(address(want)).decimals() <= 18); // dev: want not supported
        currentRouter = IUniswapV2Router02(_router);

        //pre-set approvals
        approveTokenMax(comp, address(currentRouter));
        approveTokenMax(address(want), address(cToken));

        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 86400; // once per 24 hours
        profitFactor = 100_000; // multiple before triggering harvest
        debtThreshold = 1e30;
        iterations = 6; //standard 6

        // set minWant to 1e-5 want
        minWant = uint256(
            uint256(10)**uint256((IERC20Extended(address(want))).decimals())
        ).div(1e5);
        minCompToSell = 0.1 ether; //may need to be changed depending on what comp is
        collateralTarget = 0.73 ether;
        blocksToLiquidationDangerZone = 46500;
    }

    /*
     * Control Functions
     */

    function setWithdrawChecks(bool _withdrawChecks) external management {
        withdrawChecks = _withdrawChecks;
    }

    function setDontClaimComp(bool _dontClaimComp) external management {
        dontClaimComp = _dontClaimComp;
    }

    function setRouter(address _currentV2Router) external onlyGovernance {
        currentRouter = IUniswapV2Router02(_currentV2Router);
    }

    function setForceMigrate(bool _force) external onlyGovernance {
        forceMigrate = _force;
    }

    function setSplitCompDistribution(bool _split) external management {
        splitCompDistribution = _split;
    }

    function setMinCompToSell(uint256 _minCompToSell) external management {
        minCompToSell = _minCompToSell;
    }

    function setIterations(uint256 _iterations) external management {
        require(_iterations > 0 && _iterations <= 100);
        iterations = _iterations;
    }

    function setMinWant(uint256 _minWant) external management {
        minWant = _minWant;
    }

    function setCollateralTarget(uint256 _collateralTarget)
        external
        management
    {
        (, uint256 collateralFactorMantissa, ) = compound.markets(
            address(cToken)
        );
        require(collateralFactorMantissa > _collateralTarget);
        collateralTarget = _collateralTarget;
    }

    /*
     * Base External Facing Functions
     */
    /*
     * An accurate estimate for the total amount of assets (principle + return)
     * that this strategy is currently managing, denominated in terms of want tokens.
     */
    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();

        uint256 _claimableComp = predictCompAccrued();
        uint256 currentComp = balanceOfToken(comp);

        // Use touch price. it doesnt matter if we are wrong as this is not used for decision making
        uint256 estimatedWant = priceCheck(
            comp,
            address(want),
            _claimableComp.add(currentComp)
        );
        uint256 conservativeWant = estimatedWant.mul(9).div(10); //10% pessimist

        return
            balanceOfToken(address(want))
                .add(deposits)
                .add(conservativeWant)
                .sub(borrows);
    }

    function balanceOfToken(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    //predicts our profit at next report
    function expectedReturn() public view returns (uint256) {
        uint256 estimateAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets.sub(debt);
        }
    }

    /*
     * Provide a signal to the keeper that `tend()` should be called.
     * (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     * tendTrigger should be called with same gasCost as harvestTrigger
     */
    function tendTrigger(uint256 gasCost) public view override returns (bool) {
        if (harvestTrigger(gasCost)) {
            //harvest takes priority
            return false;
        }

        return getblocksUntilLiquidation() <= blocksToLiquidationDangerZone;
    }

    //WARNING. manipulatable and simple routing. Only use for safe functions
    function priceCheck(
        address start,
        address end,
        uint256 _amount
    ) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        if (start == end) {
            return _amount;
        }

        uint256[] memory amounts = currentRouter.getAmountsOut(
            _amount,
            getTokenOutPathV2(start, end)
        );

        return amounts[amounts.length - 1];
    }

    /*****************
     * Public non-base function
     ******************/

    //Calculate how many blocks until we are in liquidation based on current interest rates
    //WARNING does not include compounding so the estimate becomes more innacurate the further ahead we look
    //equation. Compound doesn't include compounding for most blocks
    //((deposits*colateralThreshold - borrows) / (borrows*borrowrate - deposits*colateralThreshold*interestrate));
    function getblocksUntilLiquidation() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = compound.markets(
            address(cToken)
        );

        (uint256 deposits, uint256 borrows) = getCurrentPosition();

        uint256 borrrowRate = cToken.borrowRatePerBlock();

        uint256 supplyRate = cToken.supplyRatePerBlock();

        uint256 collateralisedDeposit = deposits
            .mul(collateralFactorMantissa)
            .div(1e18);

        uint256 denom1 = borrows.mul(borrrowRate);
        uint256 denom2 = collateralisedDeposit.mul(supplyRate);

        if (denom2 >= denom1) {
            return type(uint256).max;
        } else {
            uint256 numer = collateralisedDeposit.sub(borrows);
            uint256 denom = denom1.sub(denom2);
            //minus 1 for this block
            return numer.mul(1e18).div(denom);
        }
    }

    // This function makes a prediction on how much comp is accrued
    // It is not 100% accurate as it uses current balances in Compound to predict into the past
    function predictCompAccrued() public view returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        if (deposits == 0) {
            return 0; // should be impossible to have 0 balance and positive comp accrued
        }

        uint256 distributionPerBlockSupply;
        uint256 distributionPerBlockBorrow;

        if (splitCompDistribution) {
            distributionPerBlockSupply = compound.compSupplySpeeds(
                address(cToken)
            );
            distributionPerBlockBorrow = compound.compBorrowSpeeds(
                address(cToken)
            );
        } else {
            //pre 062 forks
            distributionPerBlockSupply = compound.compSpeeds(address(cToken));
            distributionPerBlockBorrow = distributionPerBlockSupply;
        }

        uint256 totalBorrow = cToken.totalBorrows();

        //total supply needs to be echanged to underlying using exchange rate
        uint256 totalSupplyCtoken = cToken.totalSupply();
        uint256 totalSupply = totalSupplyCtoken
            .mul(cToken.exchangeRateStored())
            .div(1e18);

        uint256 blockShareSupply = 0;
        if (totalSupply > 0) {
            blockShareSupply = deposits.mul(distributionPerBlockSupply).div(
                totalSupply
            );
        }

        uint256 blockShareBorrow = 0;
        if (totalBorrow > 0) {
            blockShareBorrow = borrows.mul(distributionPerBlockBorrow).div(
                totalBorrow
            );
        }

        //how much we expect to earn per block
        uint256 blockShare = blockShareSupply.add(blockShareBorrow);

        //last time we ran harvest
        uint256 lastReport = vault.strategies(address(this)).lastReport;
        uint256 blocksSinceLast = (block.timestamp.sub(lastReport)).div(
            secondsPerBlock
        );

        return blocksSinceLast.mul(blockShare);
    }

    //Returns the current position
    //WARNING - this returns just the balance at last time someone touched the cToken token. Does not accrue interst in between
    //cToken is very active so not normally an issue.
    function getCurrentPosition()
        public
        view
        returns (uint256 deposits, uint256 borrows)
    {
        (
            ,
            uint256 ctokenBalance,
            uint256 borrowBalance,
            uint256 exchangeRate
        ) = cToken.getAccountSnapshot(address(this));
        borrows = borrowBalance;

        deposits = ctokenBalance.mul(exchangeRate).div(1e18);
    }

    //statechanging version
    function getLivePosition()
        public
        returns (uint256 deposits, uint256 borrows)
    {
        deposits = cToken.balanceOfUnderlying(address(this));

        //we can use non state changing now because we updated state with balanceOfUnderlying call
        borrows = cToken.borrowBalanceStored(address(this));
    }

    //Same warning as above
    function netBalanceLent() public view returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return deposits.sub(borrows);
    }

    /***********
     * internal core logic
     *********** */
    /*
     * A core method.
     * Called at beggining of harvest before providing report to owner
     * 1 - claim accrued comp
     * 2 - if enough to be worth it we sell
     * 3 - because we lose money on our loans we need to offset profit from comp.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _profit = 0;
        _loss = 0; // for clarity. also reduces bytesize

        if (balanceOfToken(address(cToken)) == 0) {
            uint256 wantBalance = balanceOfToken(address(want));
            //no position to harvest
            //but we may have some debt to return
            //it is too expensive to free more debt in this method so we do it in adjust position
            _debtPayment = Math.min(wantBalance, _debtOutstanding);
            return (_profit, _loss, _debtPayment);
        }

        (uint256 deposits, uint256 borrows) = getLivePosition();

        //claim comp accrued
        _claimComp();
        //sell comp
        _disposeOfComp();

        uint256 wantBalance = balanceOfToken(address(want));

        uint256 investedBalance = deposits.sub(borrows);
        uint256 balance = investedBalance.add(wantBalance);

        uint256 debt = vault.strategies(address(this)).totalDebt;

        //Balance - Total Debt is profit
        if (balance > debt) {
            _profit = balance.sub(debt);
            if (wantBalance < _profit) {
                //all reserve is profit
                _profit = wantBalance;
            } else if (wantBalance > _profit.add(_debtOutstanding)) {
                _debtPayment = _debtOutstanding;
            } else {
                _debtPayment = wantBalance.sub(_profit);
            }
        } else {
            //we will lose money until we claim comp then we will make money
            //this has an unintended side effect of slowly lowering our total debt allowed
            _loss = debt.sub(balance);
            _debtPayment = Math.min(wantBalance, _debtOutstanding);
        }
    }

    /*
     * Second core function. Happens after report call.
     *
     * Similar to deposit function from V1 strategy
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        //we are spending all our cash unless we have debt outstanding
        uint256 _wantBal = balanceOfToken(address(want));
        if (_wantBal < _debtOutstanding) {
            //this is graceful withdrawal. dont use backup
            //we use more than 1 because withdrawunderlying causes problems with 1 token due to different decimals
            if (balanceOfToken(address(cToken)) > 1) {
                _withdrawSome(_debtOutstanding.sub(_wantBal));
            }

            return;
        }

        (uint256 position, bool deficit) = _calculateDesiredPosition(
            _wantBal.sub(_debtOutstanding),
            true
        );

        //if we are below minimun want change it is not worth doing
        //need to be careful in case this pushes to liquidation
        uint256 i = 0;
        while (position > minWant) {
            position = position.sub(_noFlashLoan(position, deficit));
            if (i >= iterations) {
                break;
            }
            i++;
        }
    }

    /*************
     * Very important function
     * Input: amount we want to withdraw
     *       cannot be more than we have
     * Returns amount we were able to withdraw. notall if user has some balance left
     *
     * Deleverage position -> redeem our cTokens
     ******************** */
    function _withdrawSome(uint256 _amount) internal returns (bool notAll) {
        (uint256 position, bool deficit) = _calculateDesiredPosition(
            _amount,
            false
        );

        //If there is no deficit we dont need to adjust position
        //if the position change is tiny do nothing
        if (deficit && position > minWant) {
            uint8 i = 0;
            //position will equal 0 unless we haven't been able to deleverage enough with flash loan
            //if we are not in deficit we dont need to do flash loan
            while (position > minWant.add(100)) {
                position = position.sub(_noFlashLoan(position, true));
                i++;
                //A limit set so we don't run out of gas
                if (i >= iterations) {
                    notAll = true;
                    break;
                }
            }
        }
        //now withdraw
        //if we want too much we just take max

        //This part makes sure our withdrawal does not force us into liquidation
        (uint256 depositBalance, uint256 borrowBalance) = getCurrentPosition();

        uint256 tempColla = collateralTarget;

        uint256 reservedAmount = 0;
        if (tempColla == 0) {
            tempColla = 1e15; // 0.001 * 1e18. lower we have issues
        }

        reservedAmount = borrowBalance.mul(1e18).div(tempColla);
        if (depositBalance >= reservedAmount) {
            uint256 redeemable = depositBalance.sub(reservedAmount);
            uint256 balan = cToken.balanceOf(address(this));
            if (balan > 1) {
                if (redeemable < _amount) {
                    cToken.redeemUnderlying(redeemable);
                } else {
                    cToken.redeemUnderlying(_amount);
                }
            }
        }

        if (
            collateralTarget == 0 &&
            balanceOfToken(address(want)) > borrowBalance
        ) {
            cToken.repayBorrow(borrowBalance);
        }
    }

    /***********
     *  This is the main logic for calculating how to change our lends and borrows
     *  Input: balance. The net amount we are going to deposit/withdraw.
     *  Input: dep. Is it a deposit or withdrawal
     *  Output: position. The amount we want to change our current borrow position.
     *  Output: deficit. True if we are reducing position size
     *
     *  For instance deficit =false, position 100 means increase borrowed balance by 100
     ****** */
    function _calculateDesiredPosition(uint256 balance, bool dep)
        internal
        returns (uint256 position, bool deficit)
    {
        //we want to use statechanging for safety
        (uint256 deposits, uint256 borrows) = getLivePosition();

        //When we unwind we end up with the difference between borrow and supply
        uint256 unwoundDeposit = deposits.sub(borrows);

        //we want to see how close to collateral target we are.
        //So we take our unwound deposits and add or remove the balance we are are adding/removing.
        //This gives us our desired future undwoundDeposit (desired supply)

        uint256 desiredSupply = 0;
        if (dep) {
            desiredSupply = unwoundDeposit.add(balance);
        } else {
            if (balance > unwoundDeposit) {
                balance = unwoundDeposit;
            }
            desiredSupply = unwoundDeposit.sub(balance);
        }

        //(ds *c)/(1-c)
        uint256 num = desiredSupply.mul(collateralTarget);
        uint256 den = uint256(1e18).sub(collateralTarget);

        uint256 desiredBorrow = num.div(den);
        if (desiredBorrow > 1e5) {
            //stop us going right up to the wire
            desiredBorrow = desiredBorrow.sub(1e5);
        }

        //now we see if we want to add or remove balance
        // if the desired borrow is less than our current borrow we are in deficit. so we want to reduce position
        if (desiredBorrow < borrows) {
            deficit = true;
            position = borrows.sub(desiredBorrow); //safemath check done in if statement
        } else {
            //otherwise we want to increase position
            deficit = false;
            position = desiredBorrow.sub(borrows);
        }
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amount`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _amountFreed, uint256 _loss)
    {
        uint256 _balance = balanceOfToken(address(want));
        uint256 assets = netBalanceLent().add(_balance);

        (uint256 deposits, uint256 borrows) = getLivePosition();
        if (assets < _amountNeeded) {
            //if we cant afford to withdraw we take all we can
            //withdraw all we can

            //1 token causes rounding error with withdrawUnderlying
            if (balanceOfToken(address(cToken)) > 1) {
                _withdrawSome(deposits.sub(borrows));
            }

            _amountFreed = Math.min(
                _amountNeeded,
                balanceOfToken(address(want))
            );
        } else {
            if (_balance < _amountNeeded) {
                _withdrawSome(_amountNeeded.sub(_balance));

                //overflow error if we return more than asked for
                _amountFreed = Math.min(
                    _amountNeeded,
                    balanceOfToken(address(want))
                );
            } else {
                _amountFreed = _amountNeeded;
            }
        }

        // To prevent the vault from moving on to the next strategy in the queue
        // when we return the amountRequested minus dust, take a dust sized loss
        if (_amountFreed < _amountNeeded) {
            uint256 diff = _amountNeeded.sub(_amountFreed);
            if (diff <= minWant) {
                _loss = diff;
            }
        }

        if (withdrawChecks) {
            require(_amountNeeded == _amountFreed.add(_loss)); // dev: fourThreeProtection
        }
    }

    function _claimComp() internal {
        if (dontClaimComp) {
            return;
        }
        CTokenI[] memory tokens = new CTokenI[](1);
        tokens[0] = cToken;

        compound.claimComp(address(this), tokens);
    }

    //sell comp function
    function _disposeOfComp() internal {
        uint256 _comp = balanceOfToken(comp);
        if (_comp < minCompToSell) {
            return;
        }

        currentRouter.swapExactTokensForTokens(
            _comp,
            0,
            getTokenOutPathV2(comp, address(want)),
            address(this),
            now
        );
    }

    function getTokenOutPathV2(address _tokenIn, address _tokenOut)
        internal
        view
        returns (address[] memory _path)
    {
        bool isWeth = _tokenIn == address(weth) || _tokenOut == address(weth);
        _path = new address[](isWeth ? 2 : 3);
        _path[0] = _tokenIn;

        if (isWeth) {
            _path[1] = _tokenOut;
        } else {
            _path[1] = address(weth);
            _path[2] = _tokenOut;
        }
    }

    //lets leave
    //if we can't deleverage in one go set collateralFactor to 0 and call harvest multiple times until delevered
    function prepareMigration(address _newStrategy) internal override {
        if (!forceMigrate) {
            (uint256 deposits, uint256 borrows) = getLivePosition();
            _withdrawSome(deposits.sub(borrows));

            (, , uint256 borrowBalance, ) = cToken.getAccountSnapshot(
                address(this)
            );

            require(borrowBalance < 10_000);

            IERC20 _comp = IERC20(comp);
            uint256 _compB = balanceOfToken(address(_comp));
            if (_compB > 0) {
                _comp.safeTransfer(_newStrategy, _compB);
            }
        }
    }

    //Three functions covering normal leverage and deleverage situations
    // max is the max amount we want to increase our borrowed balance
    // returns the amount we actually did
    function _noFlashLoan(uint256 max, bool deficit)
        internal
        returns (uint256 amount)
    {
        //we can use non-state changing because this function is always called after _calculateDesiredPosition
        (uint256 lent, uint256 borrowed) = getCurrentPosition();

        //if we have nothing borrowed then we can't deleverage any more
        if (borrowed == 0 && deficit) {
            return 0;
        }
        if (lent == 0) {
            cToken.mint(balanceOfToken(address(want)));
            (lent, borrowed) = getCurrentPosition();
        }

        (, uint256 collateralFactorMantissa, ) = compound.markets(
            address(cToken)
        );

        if (deficit) {
            amount = _normalDeleverage(
                max,
                lent,
                borrowed,
                collateralFactorMantissa
            );
        } else {
            amount = _normalLeverage(
                max,
                lent,
                borrowed,
                collateralFactorMantissa
            );
        }
    }

    //maxDeleverage is how much we want to reduce by
    function _normalDeleverage(
        uint256 maxDeleverage,
        uint256 lent,
        uint256 borrowed,
        uint256 collatRatio
    ) internal returns (uint256 deleveragedAmount) {
        uint256 theoreticalLent = 0;

        //collat ration should never be 0. if it is something is very wrong... but just incase
        if (collatRatio != 0) {
            theoreticalLent = borrowed.mul(1e18).div(collatRatio);
        }
        deleveragedAmount = lent.sub(theoreticalLent);

        if (deleveragedAmount >= borrowed) {
            deleveragedAmount = borrowed;
        }
        if (deleveragedAmount >= maxDeleverage) {
            deleveragedAmount = maxDeleverage;
        }
        uint256 exchangeRateStored = cToken.exchangeRateStored();
        //redeemTokens = redeemAmountIn * 1e18 / exchangeRate. must be more than 0
        //a rounding error means we need another small addition
        if (
            deleveragedAmount.mul(1e18) >= exchangeRateStored &&
            deleveragedAmount > 10
        ) {
            deleveragedAmount = deleveragedAmount.sub(uint256(10));
            cToken.redeemUnderlying(deleveragedAmount);

            //our borrow has been increased by no more than maxDeleverage
            cToken.repayBorrow(deleveragedAmount);
        }
    }

    //maxDeleverage is how much we want to increase by
    function _normalLeverage(
        uint256 maxLeverage,
        uint256 lent,
        uint256 borrowed,
        uint256 collatRatio
    ) internal returns (uint256 leveragedAmount) {
        uint256 theoreticalBorrow = lent.mul(collatRatio).div(1e18);

        leveragedAmount = theoreticalBorrow.sub(borrowed);

        if (leveragedAmount >= maxLeverage) {
            leveragedAmount = maxLeverage;
        }
        if (leveragedAmount > 10) {
            leveragedAmount = leveragedAmount.sub(uint256(10));
            cToken.borrow(leveragedAmount);
            cToken.mint(balanceOfToken(address(want)));
        }
    }

    //emergency function that we can use to deleverage manually if something is broken
    function manualDeleverage(uint256 amount) external management {
        require(cToken.redeemUnderlying(amount) == 0);
        require(cToken.repayBorrow(amount) == 0);
    }

    //emergency function that we can use to deleverage manually if something is broken
    function manualReleaseWant(uint256 amount) external onlyGovernance {
        require(cToken.redeemUnderlying(amount) == 0); // dev: !manual-release-want
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    //returns our current collateralisation ratio. Should be compared with collateralTarget
    function storedCollateralisation() public view returns (uint256 collat) {
        (uint256 lend, uint256 borrow) = getCurrentPosition();
        if (lend == 0) {
            return 0;
        }
        collat = uint256(1e18).mul(borrow).div(lend);
    }

    // -- Internal Helper functions -- //

    function ethToWant(uint256 _amtInWei)
        public
        view
        override
        returns (uint256)
    {
        return priceCheck(weth, address(want), _amtInWei);
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        (_amountFreed, ) = liquidatePosition(vault.debtOutstanding());
        (uint256 deposits, uint256 borrows) = getCurrentPosition();

        uint256 position = deposits.sub(borrows);

        //we want to revert if we can't liquidateall
        if (!forceMigrate) {
            require(position < minWant);
        }
    }

    function mgtm_check() internal view {
        require(
            msg.sender == governance() ||
                msg.sender == vault.management() ||
                msg.sender == strategist,
            "!authorized"
        );
    }

    modifier management() {
        mgtm_check();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;

import {ICustomHealthCheck} from "./interfaces/ICustomHealthCheck.sol";
import {StrategyAPI} from "./BaseStrategy.sol";

struct Limits {
    uint256 profitLimitRatio;
    uint256 lossLimitRatio;
    bool exists;
}

contract CommonHealthCheck {
    // Default Settings for all strategies
    uint256 constant MAX_BPS = 10_000;
    uint256 public profitLimitRatio;
    uint256 public lossLimitRatio;
    mapping(address => Limits) public strategiesLimits;

    address public governance;
    address public management;

    mapping(address => address) public checks;
    mapping(address => bool) public disabledCheck;
    event DisableHealthCheck(address strategy, bool disabled);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!authorized");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == governance || msg.sender == management,
            "!authorized"
        );
        _;
    }

    modifier onlyVault(address strategy) {
        require(msg.sender == StrategyAPI(strategy).vault(), "!authorized");
        _;
    }

    constructor() public {
        governance = msg.sender;
        management = msg.sender;
        profitLimitRatio = 100;
        lossLimitRatio = 1;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0));
        governance = _governance;
    }

    function setManagement(address _management) external onlyGovernance {
        require(_management != address(0));
        management = _management;
    }

    function setProfitLimitRatio(uint256 _profitLimitRatio)
        external
        onlyAuthorized
    {
        require(_profitLimitRatio < MAX_BPS);
        profitLimitRatio = _profitLimitRatio;
    }

    function setlossLimitRatio(uint256 _lossLimitRatio)
        external
        onlyAuthorized
    {
        require(_lossLimitRatio < MAX_BPS);
        lossLimitRatio = _lossLimitRatio;
    }

    function setStrategyLimits(
        address _strategy,
        uint256 _profitLimitRatio,
        uint256 _lossLimitRatio
    ) external onlyAuthorized {
        require(_lossLimitRatio < MAX_BPS);
        require(_profitLimitRatio < MAX_BPS);
        strategiesLimits[_strategy] = Limits(
            _profitLimitRatio,
            _lossLimitRatio,
            true
        );
    }

    function setCheck(address _strategy, address _check)
        external
        onlyAuthorized
    {
        checks[_strategy] = _check;
    }

    function enableCheck(address _strategy) external onlyVault(_strategy) {
        emit DisableHealthCheck(_strategy, false);
        disabledCheck[_strategy] = false;
    }

    function setDisabledCheck(address _strategy, bool disabled)
        external
        onlyAuthorized
    {
        emit DisableHealthCheck(_strategy, disabled);
        disabledCheck[_strategy] = disabled;
    }

    function doHealthCheck(address _strategy) external view returns (bool) {
        return !disabledCheck[_strategy];
    }

    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool) {
        address strategy = msg.sender;

        return
            _runChecks(
                strategy,
                profit,
                loss,
                debtPayment,
                debtOutstanding,
                totalDebt
            );
    }

    function check(
        address strategy,
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool) {
        require(strategy != address(0));

        return
            _runChecks(
                strategy,
                profit,
                loss,
                debtPayment,
                debtOutstanding,
                totalDebt
            );
    }

    function _runChecks(
        address strategy,
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) internal view returns (bool) {
        address customCheck = checks[strategy];

        if (customCheck == address(0)) {
            return _executeDefaultCheck(strategy, profit, loss, totalDebt);
        }

        return
            ICustomHealthCheck(customCheck).check(
                strategy,
                profit,
                loss,
                debtPayment,
                debtOutstanding
            );
    }

    function _executeDefaultCheck(
        address strategy,
        uint256 _profit,
        uint256 _loss,
        uint256 _totalDebt
    ) internal view returns (bool) {
        Limits memory limits = strategiesLimits[strategy];
        uint256 _profitLimitRatio;
        uint256 _lossLimitRatio;
        if (limits.exists) {
            _profitLimitRatio = limits.profitLimitRatio;
            _lossLimitRatio = limits.lossLimitRatio;
        } else {
            _profitLimitRatio = profitLimitRatio;
            _lossLimitRatio = lossLimitRatio;
        }

        if (_profit > ((_totalDebt * _profitLimitRatio) / MAX_BPS)) {
            return false;
        }
        if (_loss > ((_totalDebt * _lossLimitRatio) / MAX_BPS)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;

interface ICustomHealthCheck {
    function check(
        address callerStrategy,
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    ) external view returns (bool);
}