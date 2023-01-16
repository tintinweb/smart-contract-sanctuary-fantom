// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWeightedPool.sol";
import "./interfaces/IYieldOptimizerStaking.sol";
import "./lib/Errors.sol";

contract YieldOptimizer is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IVault.FundManagement private funds;
    Allocations public defaultAllocations;

    struct Allocations {
        uint256 reinvestedPercent; // The percentage of rewards that will be reinvested
        uint256 rewardsPercent; // A percentage of the rewards that will be exchanged for Juku token and paid to the user
        uint256 treasuryPercent; // A percentage of the rewards that will be exchanged for USDC token and sent to the treasury
        uint256 commisionsPercent; // A percentage of the rewards that will be used as a project commission
    }

    struct Pool {
        address bptToken; // pool address
        address depositToken; // Pool token to be used for deposit.
        address exitToken; // Pool token to be used for withdraw.
        address[] tokens; // Array of pool tokens
        bytes32 poolId; // ID of the pool
        bytes32 swapRouteForDepositToken; // ID of the pool through which we can get the deposit token
        bytes32 swapRouteForExitToken; // ID of the pool through which we can get the withdraw token
        bytes32[] swapRoutes; // Array of pool id`s for the swap deposit or exit tokens to pool tokens
        uint256[] tokensWeights; // tokens weights in pool
        uint256 exitTokenIndex; // exit token index in the pool tokens array
        uint256 currentEpoch;
        bool isActive; // If true the pull works, if false then not
        bool isDepositInOneToken; // if true the deposits makes in one token, if false then in all pool tokens
        bool isExitInOneToken; // if true the withdrawals makes in one token, if false then in all pool tokens
        bool isDefaultAllocations; // If true, then the default distribution will be used, if false - individual
        Allocations allocations; // Individual distribution of rewards for the pool
    }

    struct Epoch {
        uint256 commisions; // Amount of collected commissions in USDC token per epoch
        uint256 jukuRewards; // Amount of collected rewards in Juku token per epoch
        uint256 reinvestedBpt; // The amount of reinvested BPT tokens per epoch
        uint256 treasuryRevenue; // Amount of collected treasury revenue in USDC token per epoch
        uint256 start; // epoch start timestamp
        uint256 end; // epoch end timestamp
    }

    uint256 private constant PRECISSION = 10000; // PRECISSION for math operation
    address public usdcToken; // USDC token
    address public jukuToken; // Juku token address
    address public adminWallet; // contract adminWallet address
    address public vault; // Beethoven X vault address
    address public swapRouter; // swap router address
    address public revenueRecipient; // treasury revenue recipient
    address public staking; // staking USDX/JUKU address
    address[] public pathToJuku; // SwapRoute to Juku token
    mapping(address => Pool) public poolInfo; // Info about pool. See Pool struct.
    mapping(address => mapping(uint256 => Epoch)) public poolRewards; // information about the distribution of rewards in the epoch
    mapping(address => uint256) public rewardsEpochCounter; // a counter of the number of epochs for a particular pool

    //======================================================= Events ========================================================

    // @notice emitted while tokens are withdrawn from the contract
    event Withdraw(
        address indexed token,
        uint256 indexed amount,
        address indexed user,
        string userId
    );
    // @notice emitted when the adminWallet is changed
    event UpdateAdminWallet(address newAdmin);
    // @notice emitted when the funds are invested in the pool
    event Invest(
        bytes32 poolId,
        address indexed pool,
        uint256 indexed amountUsdc,
        uint256 indexed bptAmount,
        address user,
        string userId
    );
    // @notice emitted when funds are withdrawn from the pool
    event WithdrawFromPool(
        bytes32 poolId,
        address indexed pool,
        uint256 indexed amountUsdc,
        uint256 indexed bptAmount,
        address user,
        string userId
    );
    // @notice emitted when the rewards are distributed for the epoch
    event Harvest(
        address pool,
        bytes32 poolId,
        uint256 reinvestBptAmount,
        uint256 commisionsUsdcAmount,
        uint256 treasuryUsdcAmount,
        uint256 rewardsJukuAmount,
        uint256 timestamp
    );
    // @notice emitted when a new pull is added
    event AddPool(
        address pool,
        bytes32 poolId,
        address[] poolTokens,
        uint256[] poolTokensWeights
    );
    // @notice emitted when the pool exit token index is changed
    event UpdatePoolExitTokenIndex(address pool, uint256 exitTokenIndex);
    // @notice emitted when the pool deposit type is updated
    event UpdatePoolDepositType(address pool, bool depositType);
    // @notice emitted when the pool exit type is updated
    event UpdatePoolExitType(address pool, bool exitType);
    // @notice emitted when the pool swap routes for pool tokens is changed
    event UpdatePoolSwapRoutes(address pool, bytes32[] swapRoutes);
    // @notice emitted when the pool deposit token and swap route for deposit token is changed
    event UpdateDepositTokenSettings(
        address pool,
        bytes32 newSwapRoute,
        address newDepositToken
    );
    // @notice emitted when the pool exit token, exit token index and swap route for exit token is changed
    event UpdateExitTokenSettings(
        address pool,
        bytes32 newSwapRoute,
        address newExitToken,
        uint256 exitTokenIndex
    );
    // @notice emitted when setting up the individual reward distribution for the pool
    event UpdateAllocation(
        address pool,
        uint256 reinvest,
        uint256 commisions,
        uint256 rewards,
        uint256 treasury
    );
    // @notice emitted when setting up the default reward distribution
    event UpdateDefaultAllocation(
        uint256 reinvest,
        uint256 commisions,
        uint256 rewards,
        uint256 treasury
    );
    // @notice emitted when the pool activity changes
    event TogglePoolActivity(address pool, bool isActive);
    // @notice emitted when the pool allocation type is changed
    event UpdatePoolAllocationType(address pool, bool isDefault);
    // @notice emitted when the revenue recipient address is changed
    event UpdateRevenueRecipient(address newRecipient);
    // @notice emitted when the when called emergencyWithdraw
    event EmergencyWithdraw(address token, uint256 amount, address recipient);
    // @notice emitted when the when called replenishStaking
    event ReplenishStaking(address token, uint256 amount, address staking);
    // @notice emitted when the staking address setted or updated
    event SetStaking(address newStaking);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
    @dev The function plays the role of a constructor and initializes all the variables needed to start the contract.
    @param _usdcToken USDC token address
    @param _jukuToken Juku token address
    @param _admin admin address
    @param _vault Beethoven X Vault address
    @param _uniRouter spookySwap router address
    @param _revenueRecipient treasury revenue recipient
    @param _reinvestedPercent default reinvested percent. This argument is separated from the rest of the distribution. Must be from 0 - 10000.
    @param _rewardsPercent default rewards percent
    @param _treasuryPercent default treasury revenue percent
    @param _commisionsPercent default commisions percent.
    _rewardsPercent + _treasuryPercent + _commisionsPercent should be equal 10000.
    */
    function initialize(
        address _usdcToken,
        address _jukuToken,
        address _admin,
        address _vault,
        address _uniRouter,
        address _revenueRecipient,
        uint256 _reinvestedPercent,
        uint256 _rewardsPercent,
        uint256 _treasuryPercent,
        uint256 _commisionsPercent
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        _require(
            _vault != address(0) &&
                _admin != address(0) &&
                _usdcToken != address(0) &&
                _jukuToken != address(0) &&
                _uniRouter != address(0),
            Errors.ZERO_ADDRESS
        );
        _require(
            _commisionsPercent + _rewardsPercent + _treasuryPercent ==
                PRECISSION,
            Errors.INVALID_PERCENT
        );
        _require(_reinvestedPercent <= PRECISSION, Errors.PERCENT_ERROR);
        vault = _vault;
        usdcToken = _usdcToken;
        jukuToken = _jukuToken;
        swapRouter = _uniRouter;
        adminWallet = _admin;
        revenueRecipient = _revenueRecipient;
        pathToJuku = [_usdcToken, _jukuToken];
        funds = IVault.FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );
        defaultAllocations = Allocations({
            reinvestedPercent: _reinvestedPercent,
            rewardsPercent: _rewardsPercent,
            treasuryPercent: _treasuryPercent,
            commisionsPercent: _commisionsPercent
        });

        IERC20Upgradeable(_usdcToken).approve(_vault, type(uint256).max);
        IERC20Upgradeable(_usdcToken).approve(_uniRouter, type(uint256).max);
        IERC20Upgradeable(_jukuToken).approve(_uniRouter, type(uint256).max);
    }

    receive() external payable {}

    //======================================================= Modifiers ========================================================

    /**
    @dev The modifier checks whether the caller of the method 
    is an admin or the owner of the contract.
    */
    modifier onlyAdmin() {
        _require(
            msg.sender == adminWallet || msg.sender == owner(),
            Errors.ACCESS_IS_DENIED
        );
        _;
    }
    /**
    @dev The modifier checks whether the caller of the method 
    is an staking Smart Contract.
    */
    modifier onlyStaking() {
        _require(
            msg.sender == staking || msg.sender == owner(),
            Errors.ACCESS_IS_DENIED
        );
        _;
    }

    /**
    @dev The modifier checks if the pool is currently active
    @param poolAddress pool address.
    */
    modifier isActive(address poolAddress) {
        Pool storage pool = poolInfo[poolAddress];
        _require(pool.isActive, Errors.NOT_ACTIVE);
        _;
    }

    /**
    @dev The modifier checks if the pool has already been added to the YO
    @param poolAddress pool address.
    */
    modifier isAdded(address poolAddress) {
        Pool storage pool = poolInfo[poolAddress];
        _require(pool.bptToken != address(0), Errors.POOL_NOT_ADDED);
        _;
    }

    //======================================================= External Functions ========================================================

    /**
    @dev External function for withdrawing tokens from the YO.
    Only the owner or admin can call.
    @param user user wallet address.
    @param amount CBI token amount.
    @param userId user ID in CBI system.
    */
    function withdraw(
        address token,
        uint256 amount,
        address user,
        string calldata userId
    ) external onlyAdmin whenNotPaused {
        _withdraw(token, amount, user);
        emit Withdraw(token, amount, user, userId);
    }

    /**
    @dev The function invests funds into the pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param amount deposited amount in usdc.
    @param user user address.
    @param userId user ID in YO system.
    */
    function invest(
        address poolAddress,
        uint256 amount,
        address user,
        string memory userId
    ) external onlyAdmin isActive(poolAddress) whenNotPaused {
        _require(
            IERC20Upgradeable(usdcToken).balanceOf(address(this)) >= amount,
            Errors.NOT_ENOUGH_TOKENS
        );
        Pool storage pool = poolInfo[poolAddress];

        uint256[] memory giveAmounts = pool.isDepositInOneToken
            ? _investInOneToken(pool, amount)
            : _investInAllTokens(pool, amount);

        uint256 bptBalanceBefore = IERC20Upgradeable(pool.bptToken).balanceOf(
            address(this)
        );
        _balancerJoin(pool.poolId, pool.tokens, giveAmounts);
        uint256 bptBalance = IERC20Upgradeable(pool.bptToken).balanceOf(
            address(this)
        ) - bptBalanceBefore;

        emit Invest(
            pool.poolId,
            pool.bptToken,
            amount,
            bptBalance,
            user,
            userId
        );
    }

    /**
    @dev The function withdraw funds from the pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param amount bpt token amount.
    @param user user address.
    @param userId user ID in YO system.
    */
    function withdrawFromPool(
        address poolAddress,
        uint256 amount,
        address user,
        string memory userId
    ) external onlyAdmin isActive(poolAddress) whenNotPaused {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            IERC20Upgradeable(pool.bptToken).balanceOf(address(this)) >= amount,
            Errors.NOT_ENOUGH_TOKENS
        );
        uint256 usdcExitAmount = pool.isExitInOneToken
            ? _withdrawFromPoolInOneToken(pool, amount)
            : _withdrawFromPoolInAllTokens(pool, amount);

        emit WithdrawFromPool(
            pool.poolId,
            pool.bptToken,
            usdcExitAmount,
            amount,
            user,
            userId
        );
    }

    /**
    @dev The function adds and configures a new pool to the YO contract.
    Only the owner or admin can call.
    @param _poolId pool id.
    @param _poolAddress pool contract address
    @param _depositToken pool deposit token.
    @param _exitToken pool withdraw token.
     @param _swapRouteForDepositToken swap route for swap deposit token.
    @param _swapRouteForExitToken swap route for swap exit token.
    @param _exitTokenIndex exit token index in tokens array.
    @param _isDepositInOneToken boolean value if true the deposits makes in one token, if false then in all pool tokens  
    @param _isExitInOneToken boolean value if true the withdrawals makes in one token, if false then in all pool tokens
    */
    function addPool(
        bytes32 _poolId,
        address _poolAddress,
        address _depositToken,
        address _exitToken,
        bytes32 _swapRouteForDepositToken,
        bytes32 _swapRouteForExitToken,
        bytes32[] memory _swapRoutes,
        uint256 _exitTokenIndex,
        bool _isDepositInOneToken,
        bool _isExitInOneToken
    ) external onlyAdmin whenNotPaused {
        Pool storage pool = poolInfo[_poolAddress];
        _require(pool.bptToken == address(0), Errors.POOL_IS_ADDED);

        (address[] memory poolTokens, , ) = IVault(vault).getPoolTokens(
            _poolId
        );
        _require(
            _swapRoutes.length == poolTokens.length,
            Errors.INVALID_ARRAY_LENGHTS
        );

        pool.tokens = poolTokens;
        pool.poolId = _poolId;
        pool.tokensWeights = IWeightedPool(_poolAddress).getNormalizedWeights();
        pool.depositToken = _depositToken;
        pool.exitToken = _exitToken;
        pool.swapRouteForDepositToken = _swapRouteForDepositToken;
        pool.swapRouteForExitToken = _swapRouteForExitToken;
        pool.bptToken = _poolAddress;
        pool.swapRoutes = _swapRoutes;
        pool.isActive = true;
        pool.exitTokenIndex = _exitTokenIndex;
        pool.isDepositInOneToken = _isDepositInOneToken;
        pool.isExitInOneToken = _isExitInOneToken;
        pool.isDefaultAllocations = true;

        Epoch storage epoch = poolRewards[_poolAddress][
            rewardsEpochCounter[_poolAddress]
        ];
        epoch.start = block.timestamp;
        pool.currentEpoch = rewardsEpochCounter[_poolAddress];
        IERC20Upgradeable(_poolAddress).approve(vault, type(uint256).max);
        for (uint256 i = 0; i < poolTokens.length; i++) {
            IERC20Upgradeable(poolTokens[i]).approve(vault, type(uint256).max);
        }
        emit AddPool(
            pool.bptToken,
            pool.poolId,
            pool.tokens,
            pool.tokensWeights
        );
    }

    /**
    @dev The function collects the swap fee from a certain pool and distributes it according to the specified allocation. 
    The number of bpt tokens that will be burned is calculated on the backend.
    Only the owner or admin can call.
    @param poolAddress pool contract address
    @param amount bpt tokens amount
    */
    function harvest(address poolAddress, uint256 amount)
        external
        onlyAdmin
        isActive(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            IERC20Upgradeable(pool.bptToken).balanceOf(address(this)) >= amount,
            Errors.NOT_ENOUGH_TOKENS
        );

        (uint256 reinvest, uint256 totalWithdrawAmount) = _calcHarvestAmount(
            poolAddress,
            amount
        );

        uint256 usdcExitAmount = pool.isExitInOneToken
            ? _withdrawFromPoolInOneToken(pool, totalWithdrawAmount)
            : _withdrawFromPoolInAllTokens(pool, totalWithdrawAmount);

        (uint256 commisions, uint256 rewards, uint256 treasury) = _allocate(
            poolAddress,
            usdcExitAmount
        );

        uint256[] memory amounts = IUniswapV2Router(swapRouter)
            .swapExactTokensForTokens(
                rewards,
                0,
                pathToJuku,
                address(this),
                block.timestamp
            );

        Epoch storage epoch = poolRewards[poolAddress][pool.currentEpoch];
        epoch.commisions = commisions;
        epoch.jukuRewards = amounts[1];
        epoch.treasuryRevenue = treasury;
        epoch.reinvestedBpt = reinvest;
        epoch.end = block.timestamp;

        ++rewardsEpochCounter[poolAddress];
        pool.currentEpoch = rewardsEpochCounter[poolAddress];
        Epoch storage newEpoch = poolRewards[poolAddress][pool.currentEpoch];
        newEpoch.start = block.timestamp;
        IERC20Upgradeable(usdcToken).safeTransfer(revenueRecipient, treasury);

        emit Harvest(
            poolAddress,
            pool.poolId,
            reinvest,
            commisions,
            treasury,
            amounts[1],
            block.timestamp
        );
    }

    /**
    @dev The function replenishes the setting contract. 
    The staking contract before each invest, withdraw and harvest calls it
    Only the staking smart contract can call.
    @param token replenish token address
    @param amount replenish token amount
    */
    function replenishStaking(address token, uint256 amount)
        external
        onlyStaking
        whenNotPaused
    {
        _withdraw(token, amount, staking);
        emit ReplenishStaking(token, amount, staking);
    }

    /**
    @dev The function updates the address of the staking smart contract
    Only the owner or admin can call.
    @param newStaking new staking address
    */
    function setStaking(address newStaking) external onlyAdmin {
        staking = newStaking;
        emit SetStaking(newStaking);
    }

    /**
    @dev The function updates the address that will receive platform revenue.
    Only the owner or admin can call.
    @param newRecipient address of revenue recipient
    */
    function updateRevenueRecipient(address newRecipient)
        external
        onlyOwner
        whenNotPaused
    {
        revenueRecipient = newRecipient;
        emit UpdateRevenueRecipient(newRecipient);
    }

    /**
    @dev The function configures the individual distribution of rewards for the pool. 
    reinvest must be between 0 and 10000, it was separated from other percentages for gas optimization.
    commissions + rewards + treasury should be equal to 10000(PRECISSION).
    Only the owner or admin can call.
    @param poolAddress pool contract address
    @param reinvest reinvest percent
    @param commisions commissions percent
    @param rewards rewards percent
    @param treasury treasury percent
    */
    function updatePoolAllocationPercents(
        address poolAddress,
        uint256 reinvest,
        uint256 commisions,
        uint256 rewards,
        uint256 treasury
    ) external onlyAdmin isAdded(poolAddress) whenNotPaused {
        _require(
            commisions + rewards + treasury == PRECISSION,
            Errors.INVALID_PERCENT
        );
        _require(reinvest <= PRECISSION, Errors.PERCENT_ERROR);
        Pool storage pool = poolInfo[poolAddress];
        pool.allocations.reinvestedPercent = reinvest;
        pool.allocations.commisionsPercent = commisions;
        pool.allocations.rewardsPercent = rewards;
        pool.allocations.treasuryPercent = treasury;
        pool.isDefaultAllocations = false;
        emit UpdateAllocation(
            poolAddress,
            reinvest,
            commisions,
            rewards,
            treasury
        );
    }

    /**
    @dev The function configures the default  distribution of rewards for all pools if pools havent individualallocations. 
    reinvest must be between 0 and 10000, it was separated from other percentages for gas optimization.
    commissions + rewards + treasury should be equal to 10000(PRECISSION).
    Only the owner or admin can call.
    @param reinvest reinvest percent
    @param commisions commissions percent
    @param rewards rewards percent
    @param treasury treasury percent
    */
    function updateDefaultAllocationPercents(
        uint256 reinvest,
        uint256 commisions,
        uint256 rewards,
        uint256 treasury
    ) external onlyAdmin whenNotPaused {
        _require(
            commisions + rewards + treasury == PRECISSION,
            Errors.INVALID_PERCENT
        );
        _require(reinvest <= PRECISSION, Errors.PERCENT_ERROR);
        defaultAllocations = Allocations({
            reinvestedPercent: reinvest,
            rewardsPercent: rewards,
            treasuryPercent: treasury,
            commisionsPercent: commisions
        });
        emit UpdateDefaultAllocation(reinvest, commisions, rewards, treasury);
    }

    /**
    @dev The function switches between default and individual reward distribution types
    @param poolAddress pool address
    @param isDefault if true pool use default allocations else if false pool use individual allocations
    */
    function changePoolAllocationType(address poolAddress, bool isDefault)
        external
        onlyAdmin
        isAdded(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            isDefault != pool.isDefaultAllocations,
            Errors.ALREADY_ASSIGNED
        );
        _require(
            pool.allocations.commisionsPercent +
                pool.allocations.rewardsPercent +
                pool.allocations.treasuryPercent ==
                PRECISSION,
            Errors.PERCENT_ERROR
        );
        pool.isDefaultAllocations = isDefault;
        emit UpdatePoolAllocationType(poolAddress, isDefault);
    }

    /**
    @dev The function updates the exit token index for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param exitIndex exit token index in pool tokens array.
    */
    function updateExitTokenIndex(address poolAddress, uint256 exitIndex)
        external
        onlyAdmin
        isAdded(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        _require(exitIndex < pool.tokens.length, Errors.INVALID_INDEX);
        pool.exitTokenIndex = exitIndex;
        emit UpdatePoolExitTokenIndex(poolAddress, pool.exitTokenIndex);
    }

    /**
    @dev The function updates the deposit type for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param depositInOneToken boolean value if true the deposits makes in one token, if false then in all pool tokens  .
    */
    function updatePoolDepositType(address poolAddress, bool depositInOneToken)
        external
        onlyAdmin
        isAdded(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            pool.isDepositInOneToken != depositInOneToken,
            Errors.ALREADY_ASSIGNED
        );
        pool.isDepositInOneToken = depositInOneToken;
        emit UpdatePoolDepositType(poolAddress, pool.isDepositInOneToken);
    }

    /**
    @dev The function updates the exit type for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param exitInOneToken boolean value if true the withdraw makes in one token, if false then in all pool tokens  .
    */
    function updatePoolExitType(address poolAddress, bool exitInOneToken)
        external
        onlyAdmin
        isAdded(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            pool.isExitInOneToken != exitInOneToken,
            Errors.ALREADY_ASSIGNED
        );
        pool.isExitInOneToken = exitInOneToken;
        emit UpdatePoolExitType(poolAddress, pool.isExitInOneToken);
    }

    /**
    @dev The function updates deposit tokens settings(deposit token address andswap route for deposit token) for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param depositTokenAddress new deposit token address
    @param newSwapRoute swap route for usdc to deposit token.
    */
    function updateDepositTokenSettings(
        address poolAddress,
        address depositTokenAddress,
        bytes32 newSwapRoute
    ) external onlyAdmin isAdded(poolAddress) whenNotPaused {
        Pool storage pool = poolInfo[poolAddress];
        pool.depositToken = depositTokenAddress;
        pool.swapRouteForDepositToken = newSwapRoute;
        emit UpdateDepositTokenSettings(
            poolAddress,
            newSwapRoute,
            depositTokenAddress
        );
    }

    /**
    @dev The function updates exit token settings(exit token address, exit token index 
    and swap route for exit token) for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param exitTokenAddress new exit token address
    @param newSwapRoute swap route for deposit token to usdc.
    @param exitIndex token index in array of pool tokens.
    */
    function updateExitTokenSettings(
        address poolAddress,
        address exitTokenAddress,
        bytes32 newSwapRoute,
        uint256 exitIndex
    ) external onlyAdmin isAdded(poolAddress) whenNotPaused {
        Pool storage pool = poolInfo[poolAddress];
        _require(exitIndex < pool.tokens.length, Errors.INVALID_INDEX);
        pool.exitToken = exitTokenAddress;
        pool.exitTokenIndex = exitIndex;
        pool.swapRouteForExitToken = newSwapRoute;
        emit UpdateExitTokenSettings(
            poolAddress,
            newSwapRoute,
            exitTokenAddress,
            exitIndex
        );
    }

    /**
    @dev The function updates the swap routes for pool tokens for a specific pool.
    Only the owner or admin can call.
    @param poolAddress pool address.
    @param newSwapRoutes swap routes for pool tokens.
    */
    function updatePoolSwapRoutes(
        address poolAddress,
        bytes32[] memory newSwapRoutes
    ) external onlyAdmin isAdded(poolAddress) whenNotPaused {
        Pool storage pool = poolInfo[poolAddress];
        _require(
            newSwapRoutes.length == pool.tokens.length,
            Errors.INVALID_ARRAY_LENGHTS
        );
        pool.swapRoutes = newSwapRoutes;
        emit UpdatePoolSwapRoutes(poolAddress, pool.swapRoutes);
    }

    /** 
    @dev The function acts as a switch, turning pool activity on and off.
    Only the owner or admin can call.
    @param poolAddress pool address.
    */
    function togglePoolActivity(address poolAddress)
        external
        onlyAdmin
        isAdded(poolAddress)
        whenNotPaused
    {
        Pool storage pool = poolInfo[poolAddress];
        pool.isActive = !pool.isActive;
        emit TogglePoolActivity(poolAddress, pool.isActive);
    }

    /** 
    @dev Function performs contract administrator updates. 
    Only the owner can call.
    @param newAdmin new admin wallet address.
    */
    function updateAdmin(address newAdmin) external onlyOwner whenNotPaused {
        _require(newAdmin != adminWallet, Errors.ALREADY_ASSIGNED);
        adminWallet = newAdmin;
        emit UpdateAdminWallet(newAdmin);
    }

    /** 
    @dev The function enables a pause on the contract in case the contract is hacked.
    Methods that use the whenNotPaused modifier will not work.
    Only the owner can call.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /** 
    @dev The function turns off the pause, the contract returns to the normal working state
    Only the owner can call.
    */
    function unPause() external onlyOwner {
        _unpause();
    }

    /**
    @dev External function for emergency withdrawing tokens from the YO.
    Only the owner or admin can call.
    @param token token address.
    @param amount withdraw token amount.
    @param recipient recipient wallet address.
    */
    function emergencyWithdraw(
        address token,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        _withdraw(token, amount, recipient);
        emit EmergencyWithdraw(token, amount, recipient);
    }

    //======================================================= Public Functions ========================================================
    /**
    @dev Public view function returns implementation address.
    */
    function getImplementation() public view returns (address) {
        address impl = _getImplementation();
        return impl;
    }

    /**
    @dev Public view function returns swap routes for pool tokens.
    @param poolAddress pool address.
    */
    function getPoolSwapRoutes(address poolAddress)
        external
        view
        returns (bytes32[] memory)
    {
        Pool storage pool = poolInfo[poolAddress];
        return pool.swapRoutes;
    }

    //======================================================= Internal Functions ========================================================

    /**
    @dev Helper internal function for withdrawing allowed tokens from Treasury contract.
    @param token withdraw token address
    @param amount withdraw token amount.
    @param user user wallet address.
    */
    function _withdraw(
        address token,
        uint256 amount,
        address user
    ) internal {
        if (token == address(0)) {
            _require(address(this).balance >= amount, Errors.NOT_ENOUGH_TOKENS);
            (bool sent, ) = user.call{value: amount}("");
            _require(sent, Errors.FAILED_SENT_ETHER);
        } else {
            uint256 balanceToken = IERC20Upgradeable(token).balanceOf(
                address(this)
            );
            _require(balanceToken >= amount, Errors.NOT_ENOUGH_TOKENS);
            IERC20Upgradeable(token).safeTransfer(user, amount);
        }
    }

    /**
    @dev internal function that performs investment in one token of the pool
    @param pool see struct Pool.
    @param amount deposit token amount.
    */
    function _investInOneToken(Pool memory pool, uint256 amount)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory outAmounts = new uint256[](pool.tokens.length);
        if (pool.depositToken == usdcToken) {
            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] == usdcToken) {
                    outAmounts[i] = amount;
                } else outAmounts[i] = 0;
            }
        } else {
            uint256 depositTokenAmount = _balancerSwap(
                pool.swapRouteForDepositToken,
                usdcToken,
                pool.depositToken,
                amount
            );

            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] == pool.depositToken) {
                    outAmounts[i] = depositTokenAmount;
                } else {
                    outAmounts[i] = 0;
                }
            }
        }
        return outAmounts;
    }

    /**
    @dev internal function that invests in all tokens of the pool according to their weight in the pool.
    @param pool see struct Pool.
    @param amount deposit token amount.
    */
    function _investInAllTokens(Pool memory pool, uint256 amount)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory outAmounts = new uint256[](pool.tokens.length);
        uint256[] memory giveAmounts = new uint256[](pool.tokens.length);

        if (pool.depositToken == usdcToken) {
            for (uint256 i = 0; i < pool.tokens.length; i++) {
                outAmounts[i] = (amount * pool.tokensWeights[i]) / 1e18;
            }
            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] != usdcToken) {
                    giveAmounts[i] = _balancerSwap(
                        pool.swapRoutes[i],
                        usdcToken,
                        pool.tokens[i],
                        outAmounts[i]
                    );
                } else {
                    giveAmounts[i] = outAmounts[i];
                }
            }
        } else {
            uint256 depositTokenAmount = _balancerSwap(
                pool.swapRouteForDepositToken,
                usdcToken,
                pool.depositToken,
                amount
            );

            for (uint256 i = 0; i < pool.tokens.length; i++) {
                outAmounts[i] =
                    (depositTokenAmount * pool.tokensWeights[i]) /
                    1e18;
            }

            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] != pool.depositToken) {
                    giveAmounts[i] = _balancerSwap(
                        pool.swapRoutes[i],
                        pool.depositToken,
                        pool.tokens[i],
                        outAmounts[i]
                    );
                } else {
                    giveAmounts[i] = outAmounts[i];
                }
            }
        }
        return giveAmounts;
    }

    /**
    @dev internal function that makes withdraw from pool in one token and swap this token to usdc.
    @param pool see struct Pool.
    @param bptAmount beethoven pool token amount.
    */
    function _withdrawFromPoolInOneToken(Pool memory pool, uint256 bptAmount)
        internal
        returns (uint256)
    {
        uint256[] memory outAmounts = new uint256[](pool.tokens.length);
        uint256 balanceBefore;
        uint256 balanceAfter;

        for (uint256 i = 0; i < pool.tokens.length; i++) {
            outAmounts[i] = 0;
        }
        balanceBefore = IERC20Upgradeable(pool.exitToken).balanceOf(
            address(this)
        );
        _balancerExitInOneToken(
            pool.poolId,
            pool.tokens,
            outAmounts,
            bptAmount,
            pool.exitTokenIndex
        );
        balanceAfter = IERC20Upgradeable(pool.exitToken).balanceOf(
            address(this)
        );
        uint256 exitBalance = balanceAfter - balanceBefore;

        uint256 usdcExitAmount;

        if (pool.exitToken == usdcToken) {
            usdcExitAmount = exitBalance;
        } else {
            usdcExitAmount = _balancerSwap(
                pool.swapRouteForExitToken,
                pool.exitToken,
                usdcToken,
                exitBalance
            );
        }
        return usdcExitAmount;
    }

    /**
    @dev internal function that makes withdraw from pool in all pool tokens and swap this tokens to usdc.
    @param pool see struct Pool.
    @param bptAmount beethoven pool token amount.
    */
    function _withdrawFromPoolInAllTokens(Pool memory pool, uint256 bptAmount)
        internal
        returns (uint256)
    {
        uint256[] memory outAmounts = new uint256[](pool.tokens.length);
        uint256[] memory balancesBefore = new uint256[](pool.tokens.length);
        uint256[] memory balancesAfter = new uint256[](pool.tokens.length);

        for (uint256 i = 0; i < pool.tokens.length; i++) {
            outAmounts[i] = 0;
        }

        balancesBefore = _checkBalances(pool.tokens);
        _balancerExitInAllTokens(
            pool.poolId,
            pool.tokens,
            outAmounts,
            bptAmount
        );
        balancesAfter = _checkBalances(pool.tokens);
        uint256[] memory exitBalances = _calcBalance(
            balancesBefore,
            balancesAfter
        );
        uint256 usdcExitAmount;
        if (pool.exitToken == usdcToken) {
            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] != usdcToken) {
                    usdcExitAmount += _balancerSwap(
                        pool.swapRoutes[i],
                        pool.tokens[i],
                        usdcToken,
                        exitBalances[i]
                    );
                } else {
                    usdcExitAmount += exitBalances[i];
                }
            }
        } else {
            uint256 exitTokenAmount;
            for (uint256 i = 0; i < pool.tokens.length; i++) {
                if (pool.tokens[i] != pool.exitToken) {
                    exitTokenAmount += _balancerSwap(
                        pool.swapRoutes[i],
                        pool.tokens[i],
                        pool.exitToken,
                        exitBalances[i]
                    );
                } else {
                    exitTokenAmount += exitBalances[i];
                }
            }
            usdcExitAmount = _balancerSwap(
                pool.swapRouteForExitToken,
                pool.exitToken,
                usdcToken,
                exitTokenAmount
            );
        }
        return usdcExitAmount;
    }

    /**
    @dev auxiliary function to calculate the balance of tokens on the contract.
    @param balancesBefore see struct Pool.
    @param balancesAfter beethoven pool token amount.
    */
    function _calcBalance(
        uint256[] memory balancesBefore,
        uint256[] memory balancesAfter
    ) internal pure returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](balancesBefore.length);
        for (uint256 i = 0; i < balancesBefore.length; i++) {
            balances[i] = balancesAfter[i] - balancesBefore[i];
        }
        return balances;
    }

    /**
    @dev The function exits the pool in all tokens. Creates a request and invokes the Beethoven X Vault contract.
    @param _poolId pool Id.
    @param _tokens array of pool tokens addresses.
    @param _amounts array of pool tokens amounts.
    @param bptAmount beethoven pool token amount
    */
    function _balancerExitInAllTokens(
        bytes32 _poolId,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 bptAmount
    ) internal {
        bytes memory userData = abi.encode(1, bptAmount);
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            _tokens,
            _amounts,
            userData,
            false
        );

        IVault(vault).exitPool(
            _poolId,
            address(this),
            payable(address(this)),
            request
        );
    }

    /**
    @dev The function exits the pool in one token. Creates a request and invokes the Beethoven X Vault contract.
    @param _poolId pool Id.
    @param _tokens array of pool tokens addresses.
    @param _amounts array of pool tokens amounts.
    @param bptAmount beethoven pool token amount.
    @param exitTokenIndex exit token index in pool tokens array.
    */
    function _balancerExitInOneToken(
        bytes32 _poolId,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 bptAmount,
        uint256 exitTokenIndex
    ) internal {
        bytes memory userData = abi.encode(0, bptAmount, exitTokenIndex);
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            _tokens,
            _amounts,
            userData,
            false
        );

        IVault(vault).exitPool(
            _poolId,
            address(this),
            payable(address(this)),
            request
        );
    }

    /**
    @dev The function performs a deposit to pool in one or all tokens in the pool.
    Depending on the number of tokens transferred. Creates a request and invokes the Beethoven X Vault contract.
    @param _poolId pool Id.
    @param _tokens array of pool tokens addresses.
    @param _amounts array of pool tokens amounts.
    */
    function _balancerJoin(
        bytes32 _poolId,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        bytes memory userData = abi.encode(1, _amounts, 1);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(
            _tokens,
            _amounts,
            userData,
            false
        );

        IVault(vault).joinPool(_poolId, address(this), address(this), request);
    }

    /**
    @dev The function performs a swap through Beethoven X pools. 
    It creates a request and calls the swap method.
    @param _poolId pool Id.
    @param _tokenIn token in.
    @param _tokenOut token out.
    @param _amountIn tokenIn amount
    */
    function _balancerSwap(
        bytes32 _poolId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
            _poolId,
            IVault.SwapKind.GIVEN_IN,
            _tokenIn,
            _tokenOut,
            _amountIn,
            ""
        );
        return IVault(vault).swap(singleSwap, funds, 1, block.timestamp);
    }

    /**
    @dev The function checks the balances of tokens transferred to it. 
    And returns an array of balances.
    @param tokens array of tokens adresses.
    */
    function _checkBalances(address[] memory tokens)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
        }
        return balances;
    }

    /**
    @dev An auxiliary function for calculating the amount of the transfer and which will be distributed between rewards, 
    commissions and treasury.
    @param poolAddress pool address
    @param amount bpt tokens amount
    */
    function _calcHarvestAmount(address poolAddress, uint256 amount)
        internal
        view
        returns (uint256 reinvest, uint256 totalWithdrawAmount)
    {
        Pool storage pool = poolInfo[poolAddress];
        if (!pool.isDefaultAllocations) {
            reinvest =
                (amount * pool.allocations.reinvestedPercent) /
                PRECISSION;
            totalWithdrawAmount = amount - reinvest;
        } else {
            reinvest =
                (amount * defaultAllocations.reinvestedPercent) /
                PRECISSION;
            totalWithdrawAmount = amount - reinvest;
        }
    }

    /**
    @dev 
    An auxiliary function for calculating the distribution of commissions, rewards and treasury parts.
    @param poolAddress pool address
    @param usdcAmount bpt tokens amount
    */
    function _allocate(address poolAddress, uint256 usdcAmount)
        internal
        view
        returns (
            uint256 commisions,
            uint256 rewards,
            uint256 treasury
        )
    {
        Pool storage pool = poolInfo[poolAddress];
        if (!pool.isDefaultAllocations) {
            commisions =
                (usdcAmount * pool.allocations.commisionsPercent) /
                PRECISSION;
            rewards =
                (usdcAmount * pool.allocations.rewardsPercent) /
                PRECISSION;
            treasury =
                (usdcAmount * pool.allocations.treasuryPercent) /
                PRECISSION;
        } else {
            commisions =
                (usdcAmount * defaultAllocations.commisionsPercent) /
                PRECISSION;
            rewards =
                (usdcAmount * defaultAllocations.rewardsPercent) /
                PRECISSION;
            treasury =
                (usdcAmount * defaultAllocations.treasuryPercent) /
                PRECISSION;
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity 0.8.17;

interface IUniswapV2Router {
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWETH.sol";
import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";

pragma solidity 0.8.17;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer)
        external
        view
        returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(
        address indexed relayer,
        address indexed sender,
        bool approved
    );

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(
        address indexed user,
        IERC20 indexed token,
        int256 delta
    );

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(
        IERC20 indexed token,
        address indexed sender,
        address recipient,
        uint256 amount
    );

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization)
        external
        returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(
        bytes32 indexed poolId,
        address indexed poolAddress,
        PoolSpecialization specialization
    );

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(
        bytes32 indexed poolId,
        IERC20[] tokens,
        address[] assetManagers
    );

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(
        IFlashLoanRecipient indexed recipient,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount
    );

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector()
        external
        view
        returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (address);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IWeightedPool {
    function getNormalizedWeights() external view returns (uint256[] memory);

    function name() external view returns (string memory);
}

pragma solidity 0.8.17;

interface IYieldOptimizerStaking {
    function usdcJukuPair() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "YO#" part is a known constant
        // (0x594f23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x594f23000000,add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // error if a zero amount is passed
    uint256 internal constant ZERO_AMOUNT = 0;

    // error if a zero address is passed
    uint256 internal constant ZERO_ADDRESS = 1; 

    // error if there are not enough tokens for the operation
    uint256 internal constant NOT_ENOUGH_TOKENS = 2;

    // error in case the pool is inactive
    uint256 internal constant NOT_ACTIVE = 3;

    // error in case there is an attempt to add a pull that has already been added
    uint256 internal constant POOL_IS_ADDED = 4;

    // error if an array with an incorrect length is passed
    uint256 internal constant INVALID_ARRAY_LENGHTS = 5;
    
    // error if a function is called on a non-existent pool
    uint256 internal constant POOL_NOT_ADDED = 6;

    // error in case there is an attempt to update the value with the same value
    uint256 internal constant ALREADY_ASSIGNED = 7;

    // error in the case of passing a non-existent array index to the contract
    uint256 internal constant INVALID_INDEX = 8;

    // error in case ftm trasfer failed
    uint256 internal constant FAILED_SENT_ETHER = 9;

    // error in case of calling a method to which it does not have access
    uint256 internal constant ACCESS_IS_DENIED = 10;

    // An error will occur if an incorrect percentage is passed
    uint256 internal constant INVALID_PERCENT = 11;

    // error in the event that the percentages are incorrectly updated
    uint256 internal constant PERCENT_ERROR = 12;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IVault.sol";
import "./IAuthorizer.sol";

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage)
        external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens)
        external
        view
        returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}