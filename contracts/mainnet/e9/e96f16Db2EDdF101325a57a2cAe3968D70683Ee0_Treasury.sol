// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './lib/Babylonian.sol';
import './Interfaces/IBasisAsset.sol';
import './Interfaces/IOracle.sol';
import './Interfaces/IBoardroom.sol';
import './Interfaces/IShare.sol';
import './Interfaces/IBoardroomAllocation.sol';
import './lib/SafeMathint.sol';
import './lib/UInt256Lib.sol';
import './Interfaces/ITreasury.sol';
import './Interfaces/ISmartBondPool.sol';
import './Interfaces/IBalanceRebaser.sol';
import './Interfaces/IEpochListener.sol';

/**
 * @title Charge Defi Treasury contract
 * @notice Monetary policy logic to adjust supplies of tokens based on price. This increases above peg and rebases below
 *
 */
contract Treasury is AccessControlEnumerable, ITreasury, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;
	using UInt256Lib for uint256;
	using SafeMathInt for int256;

	/* ========= CONSTANT VARIABLES ======== */

	uint256 public override PERIOD;
	bytes32 public constant allocatorRole = keccak256('allocator');

	/* ========== STATE VARIABLES ========== */

	// flags
	bool public migrated = false;
	bool public initialized = false;

	// epoch
	uint256 public startTime;
	uint256 public override epoch = 0;
	uint256 public epochSupplyContractionLeft = 0;
	uint256 public epochsUnderOne = 0;

	// core components
	address public dollar;
	address public bond;
	address public share;

	address public boardroomAllocation;
	address public dollarOracle;
	address public smartBondPool;

	// Listeners than can be notified of an epoch change
	IEpochListener[] public listeners;

	// price
	uint256 public dollarPriceOne;
	uint256 public dollarPriceCeiling;

	uint256 public seigniorageSaved;

	// protocol parameters
	uint256 public bondDepletionFloorPercent;
	uint256 public smartBondDepletionFloorPercent;
	uint256 public maxDebtRatioPercent;
	uint256 public devPercentage;
	uint256 public bondRepayPercent;
	uint256 public bondRepayToBondSmartPoolPercent;
	int256 public contractionIndex;
	int256 public expansionIndex;
	uint256 public triggerRebasePriceCeiling;
	uint256 public triggerRebaseNumEpochFloor;
	uint256 public maxSupplyContractionPercent;

	// share rewards
	uint256 public sharesMintedPerEpoch;

	address public devAddress;

	/* =================== Events =================== */

	event Initialized(address indexed executor, uint256 at);
	event Migration(address indexed target);
	event RedeemedBonds(
		uint256 indexed epoch,
		address indexed from,
		uint256 amount
	);
	event BoughtBonds(
		uint256 indexed epoch,
		address indexed from,
		uint256 amount
	);
	event TreasuryFunded(
		uint256 indexed epoch,
		uint256 timestamp,
		uint256 seigniorage
	);
	event BoardroomFunded(
		uint256 indexed epoch,
		uint256 timestamp,
		uint256 seigniorage,
		uint256 shareRewards
	);
	event DevsFunded(
		uint256 indexed epoch,
		uint256 timestamp,
		uint256 seigniorage
	);

	event NewSmartBondPool(address indexed smartBondPool);
	event NewSmartBondPoolPercent(uint256 percent);
	event NewContractIndex(int256 percent);
	event NewExpansionIndex(int256 percent);
	event NewBondRepayPercent(uint256 percent);
	event NewMaxSupplyContraction(uint256 percent);
	event NewMaxDebtRatio(uint256 percent);
	event NewBondDepletionFloor(uint256 percent);
	event NewSmartBondDepletionFloor(uint256 percent);
	event NewDevPercentage(uint256 percent);
	event NewDevAddress(address indexed devAddress);
	event NewDollarOracle(address indexed oracle);
	event NewDollarPriceCeiling(uint256 dollarCeiling);
	event NewRebasePriceCeiling(uint256 priceCeiling);
	event NewRebaseNumEpochFloor(uint256 floor);
	event NewSharesMintedPerEpoch(uint256 amount);

	/* =================== Modifier =================== */

	modifier whenActive() {
		require(!migrated, 'Migrated');
		require(block.timestamp >= startTime, 'Not started yet');
		_;
	}

	modifier whenNextEpoch() {
		require(block.timestamp >= nextEpochPoint(), 'Not opened yet');
		epoch = epoch.add(1);

		epochSupplyContractionLeft = IERC20(dollar)
			.totalSupply()
			.mul(maxSupplyContractionPercent)
			.div(10000);
		_;
	}

	/**
	 * @dev Modifier to make a function callable only by a certain role. In
	 * addition to checking the sender's role, `address(0)` 's role is also
	 * considered. Granting a role to `address(0)` is equivalent to enabling
	 * this role for everyone.
	 */
	modifier onlyRoleOrOpenRole(bytes32 role) {
		if (!hasRole(role, address(0))) {
			_checkRole(role, _msgSender());
		}
		_;
	}

	/* ========== VIEW FUNCTIONS ========== */

	// flags
	function isMigrated() external view returns (bool) {
		return migrated;
	}

	function isInitialized() external view returns (bool) {
		return initialized;
	}

	// epoch
	function nextEpochPoint() public view override returns (uint256) {
		return startTime.add(epoch.mul(PERIOD));
	}

	// oracle
	function getDollarPrice()
		public
		view
		override
		returns (uint256 dollarPrice)
	{
		try IOracle(dollarOracle).consult(dollar, 1e18) returns (
			uint256 price
		) {
			return price;
		} catch {
			revert('Failed to consult dollar price from the oracle');
		}
	}

	// budget
	function getReserve() public view returns (uint256) {
		return seigniorageSaved;
	}

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/* ========== GOVERNANCE ========== */

	function initialize(
		uint256 _period,
		address _dollar,
		address _bond,
		address _share,
		uint256 _startTime,
		address _devAddress,
		address _boardroomAllocation,
		address _dollarOracle,
		address _smartBondPool
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!initialized, 'Initialized');

		expansionIndex = 1000;
		contractionIndex = 10000;
		bondDepletionFloorPercent = 10000;
		smartBondDepletionFloorPercent = 9500;
		bondRepayPercent = 1000;
		triggerRebaseNumEpochFloor = 11;
		maxSupplyContractionPercent = 0;
		maxDebtRatioPercent = 0;
		PERIOD = _period;

		dollar = _dollar;
		bond = _bond;
		share = _share;
		smartBondPool = _smartBondPool;
		startTime = _startTime;
		devAddress = _devAddress;
		boardroomAllocation = _boardroomAllocation;
		dollarOracle = _dollarOracle;
		dollarPriceOne = 1e18;
		dollarPriceCeiling = dollarPriceOne.mul(101).div(100);
		triggerRebasePriceCeiling = dollarPriceOne.mul(80).div(100);

		seigniorageSaved = IERC20(dollar).balanceOf(address(this));

		initialized = true;
		emit Initialized(msg.sender, block.number);
	}

	/**
	 * @notice It allows the admin to change address of the smart bond pool
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _smartBondPool The new smart bond pool
	 */
	function setSmartBondPool(address _smartBondPool)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		smartBondPool = _smartBondPool;
		emit NewSmartBondPool(_smartBondPool);
	}

	/**
	 * @notice It allows the admin to change how much of bond savings should be sent to smart bond pool
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param newAmount The new percentage
	 */
	function setSmartBondPoolPercent(uint256 newAmount)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		bondRepayToBondSmartPoolPercent = newAmount;
		emit NewSmartBondPoolPercent(bondRepayToBondSmartPoolPercent);
	}

	/**
	 * @notice It allows the admin to change how much contraction via rebases is allowed each epoch under peg
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _contractionIndex The new contraction index
	 */
	function setContractionIndex(int256 _contractionIndex)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_contractionIndex >= 0, 'less than 0');
		require(_contractionIndex <= 10000, 'Contraction too large');
		contractionIndex = _contractionIndex;
		emit NewContractIndex(_contractionIndex);
	}

	/**
	 * @notice It allows the admin to change how much expansion is allowed each epoch over peg
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _expansionIndex The new expansion index
	 */
	function setExpansionIndex(int256 _expansionIndex)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_expansionIndex >= 0, 'less than 0');
		require(_expansionIndex <= 10000, 'Expansion too large');
		expansionIndex = _expansionIndex;
		emit NewExpansionIndex(_expansionIndex);
	}

	/**
	 * @notice It allows the admin to change how much bonds are repaid each epoch after a contraction
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _bondRepayPercent The new repay percent
	 */
	function setBondRepayPercent(uint256 _bondRepayPercent)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_bondRepayPercent <= 10000, 'Bond repayment is too large');
		bondRepayPercent = _bondRepayPercent;
		emit NewBondRepayPercent(_bondRepayPercent);
	}

	/**
	 * @notice It allows the admin to change how much contraction is allowed due to bond buying
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _maxSupplyContractionPercent The percent of the max supply that can be used for bonds
	 */
	function setMaxSupplyContractionPercent(
		uint256 _maxSupplyContractionPercent
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_maxSupplyContractionPercent <= 10000, 'out of range'); // [0%, 100%]
		maxSupplyContractionPercent = _maxSupplyContractionPercent;
		emit NewMaxSupplyContraction(_maxSupplyContractionPercent);
	}

	/**
	 * @notice It allows the admin to change the max debt ratio of the protocol
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _maxDebtRatioPercent The new debt ratio
	 */
	function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_maxDebtRatioPercent <= 10000, 'out of range'); // [0%, 100%]
		maxDebtRatioPercent = _maxDebtRatioPercent;
		emit NewMaxDebtRatio(_maxDebtRatioPercent);
	}

	/**
	 * @notice It allows the admin to change the amount of bonds that can be funded
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _bondDepletionFloorPercent The new bond depletion percent
	 */
	function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(
			_bondDepletionFloorPercent >= 500 &&
				_bondDepletionFloorPercent <= 10000,
			'out of range'
		); // [5%, 100%]
		bondDepletionFloorPercent = _bondDepletionFloorPercent;
		emit NewBondDepletionFloor(_bondDepletionFloorPercent);
	}

	/**
	 * @notice It allows the admin to change the max amount of bonds from the total supply in smart bond pool that can
	 *			be funded.
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _smartBondDepletionFloorPercent The new bond depletion percent for the smart bond pool
	 */
	function setSmartBondDepletionFloorPercent(
		uint256 _smartBondDepletionFloorPercent
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_smartBondDepletionFloorPercent <= 99000, 'out of range'); // [0%, 99%]
		smartBondDepletionFloorPercent = _smartBondDepletionFloorPercent;
		emit NewSmartBondDepletionFloor(_smartBondDepletionFloorPercent);
	}

	/**
	 * @notice It allows the admin to change the amount devs get each expansion
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _devPercentage The new dev percentage in basis points
	 */
	function setDevPercentage(uint256 _devPercentage)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_devPercentage < 2000, 'Greedy devs are bad.');

		devPercentage = _devPercentage;
		emit NewDevPercentage(_devPercentage);
	}

	/**
	 * @notice It allows the admin to change the dev address funded each expansion
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _devAddress The new dev address
	 */
	function setDevAddress(address _devAddress)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		devAddress = _devAddress;
		emit NewDevAddress(_devAddress);
	}

	/**
	 * @notice It allows the admin to change the dollar oracle
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _dollarOracle The new dollar oracle
	 */
	function setDollarOracle(address _dollarOracle)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		dollarOracle = _dollarOracle;
		emit NewDollarOracle(_dollarOracle);
	}

	/**
	 * @notice It allows the admin to change the dollar price ceiling. i.e upper limit of peg
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _dollarPriceCeiling The upper limit of peg
	 */
	function setDollarPriceCeiling(uint256 _dollarPriceCeiling)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(
			_dollarPriceCeiling >= dollarPriceOne &&
				_dollarPriceCeiling <= dollarPriceOne.mul(120).div(100),
			'out of range'
		); // [$1.0, $1.2]
		dollarPriceCeiling = _dollarPriceCeiling;
		emit NewDollarPriceCeiling(_dollarPriceCeiling);
	}

	/**
	 * @notice It allows the admin to change at what price rebases happen
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _triggerRebasePriceCeiling The new dollar price to rebase at
	 */
	function setTriggerRebasePriceCeiling(uint256 _triggerRebasePriceCeiling)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(
			_triggerRebasePriceCeiling < dollarPriceOne,
			'rebase ceiling is too high'
		);
		triggerRebasePriceCeiling = _triggerRebasePriceCeiling;
		emit NewRebasePriceCeiling(_triggerRebasePriceCeiling);
	}

	/**
	 * @notice It allows the admin to shares minted per epoch
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _triggerRebaseNumEpochFloor The new number of epochs before a rebase happens
	 */
	function setTriggerRebaseNumEpochFloor(uint256 _triggerRebaseNumEpochFloor)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		triggerRebaseNumEpochFloor = _triggerRebaseNumEpochFloor;
		emit NewRebaseNumEpochFloor(_triggerRebaseNumEpochFloor);
	}

	/**
	 * @notice It allows the admin to shares minted per epoch
	 * @dev This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param _sharesMintedPerEpoch The new mint value
	 */
	function setSharesMintedPerEpoch(uint256 _sharesMintedPerEpoch)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		sharesMintedPerEpoch = _sharesMintedPerEpoch;
		emit NewSharesMintedPerEpoch(_sharesMintedPerEpoch);
	}

	/**
	 * @notice Adds an address as IEpochListener that gets called when a epoch updates
	 * @param listener Address of the listener contract
	 */
	function addEpochListener(IEpochListener listener)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(listeners.length <= 10, 'Too many listeners');

		for (uint256 i = 0; i < listeners.length; i++) {
			require(listeners[i] != listener, 'Listener exists');
		}
		listeners.push(listener);
	}

	/**
	 * @notice Removes an address as IEpochListener that gets called when a epoch updates
	 * @param listener Address of the listener contract
	 */
	function removeEpochListener(IEpochListener listener)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		for (uint256 i = 0; i < listeners.length; i++) {
			if (listeners[i] == listener) {
				listeners[i] = listeners[listeners.length - 1];
				listeners.pop();
				return;
			}
		}

		revert('Listener not found');
	}

	/**
	 * @return Number of listeners, in the listener list
	 */
	function listenersSize() external view returns (uint256) {
		return listeners.length;
	}

	/**
	 * @dev Handles migrating assets to a new treasury contract
	 *
	 * Steps to migrate
	 *	1. Deploy new treasury contract with required roles
	 * 	2. Call this migrate method with `target`
	 *  3. Revoke roles of this contract (optional, as all mint/rebase functions are blocked after migration)
	 *
	 * This function is only callable by DEFAULT_ADMIN_ROLE
	 * @param target The address of the new Treasury contract
	 *
	 */
	function migrate(address target) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!migrated, 'Migrated');

		require(target != address(0), 'New contract cannot be zero');

		IERC20(dollar).safeTransfer(
			target,
			IERC20(dollar).balanceOf(address(this))
		);
		IERC20(bond).safeTransfer(
			target,
			IERC20(bond).balanceOf(address(this))
		);
		IERC20(share).safeTransfer(
			target,
			IERC20(share).balanceOf(address(this))
		);

		migrated = true;
		emit Migration(target);
	}

	/* ========== MUTABLE FUNCTIONS ========== */

	function _updateDollarPrice() internal {
		try IOracle(dollarOracle).update() {} catch {}
	}

	/**
	 * @notice Buy bonds for a user
	 * @dev Bonds can only be redeemed below peg and only a certain amount `epochSupplyContractionLeft`
	 *		can be bought per epoch
	 * @param amount The amount bonds to buy
	 */
	function buyBonds(uint256 amount) external nonReentrant whenActive {
		require(amount > 0, 'Cannot purchase bonds with zero amount');

		uint256 dollarPrice = getDollarPrice();
		uint256 accountBalance = IERC20(dollar).balanceOf(msg.sender);

		require(
			dollarPrice < dollarPriceOne, // price < $1
			'DollarPrice not eligible for bond purchase'
		);

		require(
			amount <= epochSupplyContractionLeft,
			'Not enough bond left to purchase this epoch'
		);
		require(accountBalance >= amount, 'Not enough BTD to buy bond');

		uint256 dollarSupply = IERC20(dollar).totalSupply();
		uint256 newBondSupply = IERC20(bond).totalSupply().add(amount);

		require(
			newBondSupply <= dollarSupply.mul(maxDebtRatioPercent).div(10000),
			'over max debt ratio'
		);

		IBasisAsset(dollar).burnFrom(msg.sender, amount);
		IBasisAsset(bond).mint(msg.sender, amount);

		epochSupplyContractionLeft = epochSupplyContractionLeft.sub(amount);
		_updateDollarPrice();

		emit BoughtBonds(epoch, msg.sender, amount);
	}

	/**
	 * @notice Redeems bonds for a user
	 * @dev Bonds can only be redeemed above peg and treasury must have enough funds for redemption
	 * @param amount The amount bonds to be redeemed
	 */
	function redeemBonds(uint256 amount) external nonReentrant whenActive {
		require(amount > 0, 'Cannot redeem bonds with zero amount');

		uint256 dollarPrice = getDollarPrice();
		require(
			dollarPrice > dollarPriceCeiling, // price > $1.01
			'DollarPrice not eligible for bond purchase'
		);
		require(
			IERC20(dollar).balanceOf(address(this)) >= amount,
			'Treasury has no more budget'
		);
		require(getReserve() >= amount, "Treasury hasn't saved any dollar");

		seigniorageSaved = seigniorageSaved.sub(amount);

		IBasisAsset(bond).burnFrom(msg.sender, amount);
		IERC20(dollar).safeTransfer(msg.sender, amount);

		_updateDollarPrice();

		emit RedeemedBonds(epoch, msg.sender, amount);
	}

	/**
	 * @notice Handles the expansion/contract of dollar supply based on epoch price
	 * @dev This can only be called once per epoch
	 */
	function allocateSeigniorage()
		external
		nonReentrant
		whenActive
		whenNextEpoch
		onlyRoleOrOpenRole(allocatorRole)
	{
		_updateDollarPrice();

		// expansion amount = (TWAP - 1.00) * totalsupply * index / maxindex
		// 10% saved for bonds
		// 10% after bonds saved for team
		// 45% after bonds given to shares
		// 45% after bonds given to LP

		uint256 dollarPrice = getDollarPrice();
		epochsUnderOne = dollarPrice >= dollarPriceOne
			? 0
			: epochsUnderOne.add(1);

		int256 supplyDelta = _computeSupplyDelta(dollarPrice, dollarPriceOne);
		uint256 shareRewards = _getSharesRewardsForEpoch();
		uint256 dollarRewards = 0;

		if (dollarPrice > dollarPriceCeiling) {
			dollarRewards = _expandDollar(supplyDelta);
		} else if (
			dollarPrice <= triggerRebasePriceCeiling ||
			epochsUnderOne > triggerRebaseNumEpochFloor
		) {
			_contractDollar(supplyDelta);
		}
		_sendToBoardRoom(dollarRewards, shareRewards);
		_notifyEpochChanged();
	}

	/**
	 * @notice It allows the admin to tokens in the contract
	 * @dev This function is only callable by admin.
	 * @param _token The address of the token to withdraw
	 * @param _amount The number of tokens to withdraw
	 * @param _to The account to send tokens
	 */
	function governanceRecoverUnsupported(
		IERC20 _token,
		uint256 _amount,
		address _to
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		// do not allow to drain core tokens
		require(address(_token) != address(dollar), 'dollar');
		require(address(_token) != address(bond), 'bond');
		require(address(_token) != address(share), 'share');
		_token.safeTransfer(_to, _amount);
	}

	/**
	 * @notice The amount of shares that can be minted per epoch
	 * @return Shares amount
	 */
	function _getSharesRewardsForEpoch() internal view returns (uint256) {
		uint256 mintLimit = IShare(share).mintLimitOf(address(this));
		uint256 mintedAmount = IShare(share).mintedAmountOf(address(this));

		uint256 amountMintable = mintLimit > mintedAmount
			? mintLimit.sub(mintedAmount)
			: 0;

		return Math.min(sharesMintedPerEpoch, amountMintable);
	}

	/**
	 * @notice Expands the dollar supply based on input
	 * @dev This method expands, saves tokens for bonds and returns the remaining amount available for boardroom
	 * @param supplyDelta The amount to increase the dollar supply by
	 * @return The amount of dollar tokens saved for boardroom
	 */
	function _expandDollar(int256 supplyDelta) private returns (uint256) {
		require(supplyDelta >= 0, 'Not allowed to convert to uint');

		// Expansion (Price > 1.01$): there is some seigniorage to be allocated
		supplyDelta = supplyDelta.mul(expansionIndex).div(10000);

		uint256 _bondSupply = IERC20(bond).totalSupply();
		uint256 _savedForBond = 0;
		uint256 _savedForBoardRoom;
		uint256 _savedForDevs;
		uint256 _totalBondsToRepay = _bondSupply
			.mul(bondDepletionFloorPercent)
			.div(10000);

		if (seigniorageSaved >= _totalBondsToRepay) {
			_savedForBoardRoom = uint256(supplyDelta);
		} else {
			// have not saved enough to pay dept, mint more
			uint256 _seigniorage = uint256(supplyDelta);
			if (
				_seigniorage.mul(bondRepayPercent).div(10000) <=
				_totalBondsToRepay.sub(seigniorageSaved)
			) {
				_savedForBond = _seigniorage.mul(bondRepayPercent).div(10000);
				_savedForBoardRoom = _seigniorage.sub(_savedForBond);
			} else {
				_savedForBond = _totalBondsToRepay.sub(seigniorageSaved);
				_savedForBoardRoom = _seigniorage.sub(_savedForBond);
			}
		}

		if (_savedForBond > 0) {
			uint256 maxAmountForSmartBondPool = IBalanceRebaser(smartBondPool)
				.totalBalance()
				.mul(smartBondDepletionFloorPercent)
				.div(10000);
			uint256 savedForSmartPool = _savedForBond
				.mul(bondRepayToBondSmartPoolPercent)
				.div(10000);

			savedForSmartPool = Math.min(
				savedForSmartPool,
				maxAmountForSmartBondPool
			);
			_savedForBond = _savedForBond.sub(savedForSmartPool);

			seigniorageSaved = seigniorageSaved.add(_savedForBond);
			emit TreasuryFunded(epoch, block.timestamp, _savedForBond);
			IBasisAsset(dollar).mint(
				address(this),
				_savedForBond.add(savedForSmartPool)
			);
			if (savedForSmartPool > 0) {
				IERC20(dollar).approve(smartBondPool, savedForSmartPool);
				ISmartBondPool(smartBondPool).allocateSeigniorage(
					savedForSmartPool
				);
			}
		}

		if (_savedForBoardRoom > 0) {
			_savedForDevs = _savedForBoardRoom.mul(devPercentage).div(10000);
			_savedForBoardRoom = _savedForBoardRoom.sub(_savedForDevs);
			_sendToDevs(_savedForDevs);
		}

		return _savedForBoardRoom;
	}

	function _contractDollar(int256 supplyDelta) private {
		supplyDelta = supplyDelta.mul(contractionIndex).div(10000);
		IBasisAsset(dollar).rebase(epoch, supplyDelta);
	}

	function _sendToDevs(uint256 _amount) internal {
		if (_amount > 0) {
			require(
				IBasisAsset(dollar).mint(devAddress, _amount),
				'Unable to mint for devs'
			);
			emit DevsFunded(epoch, block.timestamp, _amount);
		}
	}

	/**
	 * @notice Sends tokens to the boardroom
	 * @dev This method mints tokens as per need and sends to boardrooms based on allocation
	 * @param _cashAmount The amount of dollar tokens to send
	 * @param _shareAmount The amount of share tokens to send
	 */
	function _sendToBoardRoom(uint256 _cashAmount, uint256 _shareAmount)
		internal
	{
		if (_cashAmount > 0 || _shareAmount > 0) {
			uint256 boardroomCount = IBoardroomAllocation(boardroomAllocation)
				.boardroomInfoLength();

			// mint assets
			if (_cashAmount > 0)
				IBasisAsset(dollar).mint(address(this), _cashAmount);

			if (_shareAmount > 0)
				IBasisAsset(share).mint(address(this), _shareAmount);

			for (uint256 i = 0; i < boardroomCount; i++) {
				(
					address boardroom,
					bool isActive,
					uint256 cashAllocationPoints,
					uint256 shareAllocationPoints
				) = IBoardroomAllocation(boardroomAllocation).boardrooms(i);
				if (isActive) {
					uint256 boardroomCashAmount = _cashAmount
						.mul(cashAllocationPoints)
						.div(
							IBoardroomAllocation(boardroomAllocation)
								.totalCashAllocationPoints()
						);

					uint256 boardroomShareAmount = _shareAmount
						.mul(shareAllocationPoints)
						.div(
							IBoardroomAllocation(boardroomAllocation)
								.totalShareAllocationPoints()
						);

					if (boardroomCashAmount > 0)
						IERC20(dollar).safeApprove(
							boardroom,
							boardroomCashAmount
						);

					if (boardroomShareAmount > 0)
						IERC20(share).safeApprove(
							boardroom,
							boardroomShareAmount
						);

					if (boardroomCashAmount > 0 || boardroomShareAmount > 0) {
						IBoardroom(boardroom).allocateSeigniorage(
							boardroomCashAmount,
							boardroomShareAmount
						);
					}
				}
			}

			emit BoardroomFunded(
				epoch,
				block.timestamp,
				_cashAmount,
				_shareAmount
			);
		}
	}

	/**
	 * @notice Computes the total supply adjustment in response to the exchange rate
	 *         and the targetRate.
	 * @param rate The current token price
	 * @param targetRate The ideal token price
	 * @return Supply to be adjusted
	 */
	function _computeSupplyDelta(uint256 rate, uint256 targetRate)
		private
		view
		returns (int256)
	{
		int256 targetRateSigned = targetRate.toInt256Safe();

		int256 supply = (
			IERC20(dollar)
				.totalSupply()
				.sub(IERC20(dollar).balanceOf(address(this)))
				.sub(boardroomsBalance())
		).toInt256Safe();

		if (rate < targetRate) {
			supply = IBasisAsset(dollar).rebaseSupply().toInt256Safe();
		}
		return
			supply.mul(rate.toInt256Safe().sub(targetRateSigned)).div(
				targetRateSigned
			);
	}

	function boardroomsBalance() private view returns (uint256) {
		uint256 bal = 0;

		uint256 boardroomCount = IBoardroomAllocation(boardroomAllocation)
			.boardroomInfoLength();

		for (uint256 i = 0; i < boardroomCount; i++) {
			(address boardroom, , , ) = IBoardroomAllocation(
				boardroomAllocation
			).boardrooms(i);

			bal = bal.add(IERC20(dollar).balanceOf(boardroom));
		}

		return bal;
	}

	function _notifyEpochChanged() internal {
		for (uint256 i = 0; i < listeners.length; i++) {
			listeners[i].epochUpdate(epoch);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

/*
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

pragma solidity 0.8.4;

/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {
	uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

	/**
	 * @dev Safely converts a uint256 to an int256.
	 */
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		require(a <= MAX_INT256);
		return int256(a);
	}
}

pragma solidity 0.8.4;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	/**
	 * @dev Multiplies two int256 variables and fails on overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		// Detect overflow when multiplying MIN_INT256 with -1
		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}

	/**
	 * @dev Division of two int256 variables and fails on overflow.
	 */
	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing MIN_INT256 by -1
		require(b != -1 || a != MIN_INT256);

		// Solidity already throws when dividing by 0.
		return a / b;
	}

	/**
	 * @dev Subtracts two int256 variables and fails on overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}

	/**
	 * @dev Adds two int256 variables and fails on overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	/**
	 * @dev Converts to absolute value, and fails on overflow.
	 */
	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
}

pragma solidity 0.8.4;

library Babylonian {
	function sqrt(uint256 y) internal pure returns (uint256 z) {
		if (y > 3) {
			z = y;
			uint256 x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
		// else z = 0
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITreasury {
	function PERIOD() external view returns (uint256);

	function epoch() external view returns (uint256);

	function nextEpochPoint() external view returns (uint256);

	function getDollarPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// For interacting with our own strategy
interface ISmartBondPool {
	// Transfer want tokens yetiFarm -> strategy
	function allocateSeigniorage(uint256 amount_) external;
}

pragma solidity 0.8.4;
import './IMintableToken.sol';

interface IShare is IMintableToken {
	function mintLimitOf(address minter_) external view returns (uint256);

	function mintedAmountOf(address minter_) external view returns (uint256);

	function canMint(address mint_, uint256 amount)
		external
		view
		returns (bool);
}

pragma solidity 0.8.4;

interface IOracle {
	function update() external;

	function consult(address token, uint256 amountIn)
		external
		view
		returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMintableToken {
	function mint(address recipient_, uint256 amount_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IEpochListener {
	function epochUpdate(uint256 newEpoch) external;
}

pragma solidity 0.8.4;

interface IBoardroomAllocation {
	function totalCashAllocationPoints() external view returns (uint256);

	function totalShareAllocationPoints() external view returns (uint256);

	function boardrooms(uint256 index)
		external
		view
		returns (
			address,
			bool,
			uint256,
			uint256
		);

	function deactivateBoardRoom(uint256 index) external;

	function addBoardroom(
		address boardroom_,
		uint256 cashAllocationPoints_,
		uint256 shareAllocationPoints_
	) external;

	function updateBoardroom(
		uint256 index,
		uint256 cashAllocationPoints_,
		uint256 shareAllocationPoints_
	) external;

	function boardroomInfoLength() external view returns (uint256);
}

pragma solidity 0.8.4;

interface IBoardroom {
	function balanceOf(address _director) external view returns (uint256);

	function earned(address _director) external view returns (uint256, uint256);

	function canWithdraw(address _director) external view returns (bool);

	function canClaimReward(address _director) external view returns (bool);

	function setOperator(address _operator) external;

	function setLockUp(
		uint256 _withdrawLockupEpochs,
		uint256 _rewardLockupEpochs
	) external;

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function exit() external;

	function claimReward() external;

	function allocateSeigniorage(uint256 _cashReward, uint256 _shareReward)
		external;

	function governanceRecoverUnsupported(
		address _token,
		uint256 _amount,
		address _to
	) external;

	function APR() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import './IMintableToken.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IBasisAsset is IMintableToken, IERC20Metadata {
	function burn(uint256 amount) external;

	function burnFrom(address from, uint256 amount) external;

	function isOperator() external returns (bool);

	function operator() external view returns (address);

	function rebase(uint256 epoch, int256 supplyDelta) external;

	function rebaseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


// For interacting with our own strategy
interface IBalanceRebaser {	
	function totalBalance() external view returns (uint256);

}