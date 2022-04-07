/**
 *Submitted for verification at FtmScan.com on 2022-04-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IDEXTax {
    struct RouteItem
    {
        address router;
        address[] path;
    }

    function swapETHForExactTokens(RouteItem[] calldata route, uint amountOut, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(RouteItem[] calldata route, uint amountOutMin, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
    external returns (uint[] memory amounts);
    function swapExactTokensForETH(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
    external returns (uint[] memory amounts);
    function swapExactTokensForTokens(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
    external returns (uint[] memory amounts);
    function swapTokensForExactTokens(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
    external returns (uint[] memory amounts);
}

interface IEverscale {
    struct EverscaleAddress {
        int128 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

interface IVaultBasic is IEverscale {
    struct WithdrawalParams {
        EverscaleAddress sender;
        uint256 amount;
        address recipient;
        uint32 chainId;
    }

    function bridge() external view returns (address);
    function configuration() external view returns (EverscaleAddress memory);
    function withdrawalIds(bytes32) external view returns (bool);
    function rewards() external view returns (EverscaleAddress memory);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function token() external view returns (address);
    function targetDecimals() external view returns (uint256);
    function tokenDecimals() external view returns (uint256);

    function depositFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);

    function emergencyShutdown() external view returns (bool);

    function apiVersion() external view returns (string memory api_version);

    function setDepositFee(uint _depositFee) external;
    function setWithdrawFee(uint _withdrawFee) external;

    function setConfiguration(EverscaleAddress memory _configuration) external;
    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;
    function setEmergencyShutdown(bool active) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    ) external;

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) external view returns(WithdrawalParams memory);

    function sweep(address _token) external;

    // Events
    event Deposit(
        uint256 amount,
        int128 wid,
        uint256 addr
    );

    event InstantWithdrawal(
        bytes32 payloadId,
        address recipient,
        uint256 amount
    );

    event UpdateBridge(address bridge);
    event UpdateConfiguration(int128 wid, uint256 addr);
    event UpdateTargetDecimals(uint256 targetDecimals);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateDepositFee(uint256 fee);
    event UpdateWithdrawFee(uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);
}

interface IVault is IVaultBasic {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalSkim;
        uint256 totalLoss;
        address rewardsManager;
        EverscaleAddress rewards;
    }

    struct PendingWithdrawalParams {
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function initialize(
        address _token,
        address _bridge,
        address _governance,
        uint _targetDecimals,
        EverscaleAddress memory _rewards
    ) external;

    function withdrawGuardian() external view returns (address);

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawals(
        address user,
        uint id
    ) external view returns (PendingWithdrawalParams memory);
    function pendingWithdrawalsTotal() external view returns (uint);

    function managementFee() external view returns (uint256);
    function performanceFee() external view returns (uint256);

    function strategies(
        address strategyId
    ) external view returns (StrategyParams memory);
    function withdrawalQueue() external view returns (address[20] memory);

    function withdrawLimitPerPeriod() external view returns (uint256);
    function undeclaredWithdrawLimit() external view returns (uint256);
    function withdrawalPeriods(
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);

    function depositLimit() external view returns (uint256);
    function debtRatio() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function lastReport() external view returns (uint256);
    function lockedProfit() external view returns (uint256);
    function lockedProfitDegradation() external view returns (uint256);

    function setWithdrawGuardian(address _withdrawGuardian) external;
    function setStrategyRewards(
        address strategyId,
        EverscaleAddress memory _rewards
    ) external;
    function setLockedProfitDegradation(uint256 degradation) external;
    function setDepositLimit(uint256 limit) external;
    function setPerformanceFee(uint256 fee) external;
    function setManagementFee(uint256 fee) external;
    function setWithdrawLimitPerPeriod(uint256 _withdrawLimitPerPeriod) external;
    function setUndeclaredWithdrawLimit(uint256 _undeclaredWithdrawLimit) external;
    function setWithdrawalQueue(address[20] memory queue) external;
    function setPendingWithdrawalBounty(uint256 id, uint256 bounty) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount,
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;
    function deposit(
        EverscaleAddress memory recipient,
        uint256[] memory amount,
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;
    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    ) external;

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    ) external returns (
        bool instantWithdrawal,
        PendingWithdrawalId memory pendingWithdrawalId
    );

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    ) external;

    function withdraw(
        uint256 id,
        uint256 amountRequested,
        address recipient,
        uint256 maxLoss,
        uint bounty
    ) external returns(uint256);

    function addStrategy(
        address strategyId,
        uint256 _debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 _performanceFee
    ) external;

    function updateStrategyDebtRatio(
        address strategyId,
        uint256 _debtRatio
    )  external;

    function updateStrategyMinDebtPerHarvest(
        address strategyId,
        uint256 minDebtPerHarvest
    ) external;

    function updateStrategyMaxDebtPerHarvest(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) external;

    function updateStrategyPerformanceFee(
        address strategyId,
        uint256 _performanceFee
    ) external;

    function migrateStrategy(
        address oldVersion,
        address newVersion
    ) external;

    function revokeStrategy(
        address strategyId
    ) external;
    function revokeStrategy() external;


    function totalAssets() external view returns (uint256);
    function debtOutstanding(address strategyId) external view returns (uint256);
    function debtOutstanding() external view returns (uint256);

    function creditAvailable(address strategyId) external view returns (uint256);
    function creditAvailable() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);
    function expectedReturn(address strategyId) external view returns (uint256);

    function report(
        uint256 profit,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function skim(address strategyId) external;

    function forceWithdraw(
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;


    event PendingWithdrawalUpdateBounty(address recipient, uint256 id, uint256 bounty);
    event PendingWithdrawalCancel(address recipient, uint256 id, uint256 amount);
    event PendingWithdrawalForce(address recipient, uint256 id);
    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes32 payloadId
    );
    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 requestedAmount,
        uint256 redeemedAmount
    );
    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        ApproveStatus approveStatus
    );

    event UpdateWithdrawLimitPerPeriod(uint256 withdrawLimitPerPeriod);
    event UpdateUndeclaredWithdrawLimit(uint256 undeclaredWithdrawLimit);
    event UpdateDepositLimit(uint256 depositLimit);

    event UpdatePerformanceFee(uint256 performanceFee);
    event UpdateManagementFee(uint256 managenentFee);

    event UpdateWithdrawGuardian(address withdrawGuardian);
    event UpdateWithdrawalQueue(address[20] queue);

    event StrategyUpdateDebtRatio(address indexed strategy, uint256 debtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 minDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 maxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 performanceFee);
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
    event StrategyRevoked(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event StrategyAddedToQueue(address indexed strategy);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalSkim,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );

    event StrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    );
    event StrategyUpdateRewards(
        address strategyId,
        int128 wid,
        uint256 addr
    );
    event UserDeposit(
        address sender,
        int128 recipientWid,
        uint256 recipientAddr,
        uint256 amount,
        address withdrawalRecipient,
        uint256 withdrawalId,
        uint256 bounty
    );
    event FactoryDeposit(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes1 separator,
        bytes level3
    );

}

     struct SwapData {
        IDEXTax.RouteItem[] route;
        uint amountIn;
        uint amountOut;
        uint deadline;
    }

    struct DepositData {
        address vault;
        int8 wid;
        uint256 user;
        uint256 creditor;
        uint256 recipient;
        uint128 tonAmount;
        uint8 swapType;
        uint128 slippageNumerator;
        uint128 slippageDenominator;
        bytes level3;
    }

interface IEverSwap {
    function swapETHForExactTokens(SwapData calldata swapData, DepositData calldata depositData) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(SwapData calldata swapData, DepositData calldata depositData) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(SwapData calldata swapData, DepositData calldata depositData) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(SwapData calldata swapData, DepositData calldata depositData) external returns (uint[] memory amounts);
}


contract EverSwap is IEverSwap {

    address dexTax;
    constructor(address _dexTax) {
        dexTax = _dexTax;
    }

    function safeTransfer(address to, uint256 value) internal
    {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function approve(address token, address spender, uint amount) internal
    {
        uint256 allowed = IERC20(token).allowance(address(this), spender);
        if (allowed < amount)
        {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function deposit(address token, DepositData calldata data) internal {
        uint128 amount = uint128(IERC20(token).balanceOf(address(this)));
        approve(token, data.vault, amount);
        IVault(data.vault).depositToFactory(
            amount,
            data.wid,
            data.user,
            data.creditor,
            data.recipient,
            0,
            data.tonAmount,
            data.swapType,
            data.slippageNumerator,
            data.slippageDenominator,
            data.level3
        );
    }

    function getOutToken(SwapData calldata swapData) internal pure returns (address) {
        IDEXTax.RouteItem memory route = swapData.route[swapData.route.length-1];
        return route.path[route.path.length -1];
    }

    function swapETHForExactTokens(SwapData calldata swapData, DepositData calldata depositData) override external payable returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapETHForExactTokens{value : swapData.amountIn}(swapData.route, swapData.amountOut, address(this), swapData.deadline);
        safeTransfer(msg.sender, msg.value - amounts[0]);
        deposit(getOutToken(swapData), depositData);
    }

    function swapExactETHForTokens(SwapData calldata swapData, DepositData calldata depositData) override external payable returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapExactETHForTokens{value : swapData.amountIn}(swapData.route, swapData.amountOut, address(this), swapData.deadline);
        safeTransfer(msg.sender, msg.value - amounts[0]);
        deposit(getOutToken(swapData), depositData);
    }

    function swapTokensForExactTokens(SwapData calldata swapData, DepositData calldata depositData) override external returns (uint[] memory amounts) {
        IERC20(swapData.route[0].path[0]).transferFrom(msg.sender, address(this), swapData.amountIn);
        approve(swapData.route[0].path[0], dexTax, swapData.amountIn);
        amounts = IDEXTax(dexTax).swapTokensForExactTokens(swapData.route, swapData.amountOut, swapData.amountIn, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }
    function swapExactTokensForTokens(SwapData calldata swapData, DepositData calldata depositData) override external returns (uint[] memory amounts) {
        IERC20(swapData.route[0].path[0]).transferFrom(msg.sender, address(this), swapData.amountIn);
        approve(swapData.route[0].path[0], dexTax, swapData.amountIn);
        amounts = IDEXTax(dexTax).swapExactTokensForTokens(swapData.route, swapData.amountIn, swapData.amountOut, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }

}