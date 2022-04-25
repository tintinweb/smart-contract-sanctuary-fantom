/**
 *Submitted for verification at FtmScan.com on 2022-04-22
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
interface IIceberg {
    
    function lockupRewards(
        address user, 
        uint256 shortLockupRewards, 
        uint256 longLockupRewards
    ) external;

    function claimShortLokcup(address user, uint32 index) external;

    function claimLongLockup(address user, uint32 index) external;

    function getShortLockupTime() external view returns(uint32);

    function getLongLockupTime() external view returns(uint32);

    function getShortPercentage() external view returns(uint256);
 
    function getLongPercentage() external view returns(uint256);
}
/**
 * @dev Interface of the ERC20 standard with mint and burn functions.
 */
interface Ignode {

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens from `msg.sender`, reducing the
     * total supply.
     *
     *
     * Requirements:
     *
     * - `msg.sender` must have at least `amount` tokens.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Burns `amount` tokens from `from`, reducing the
     * total supply.
     *
     * Requirements:
     *
     * - `from` must have at least `amount` tokens.
     * - `msg.sender` must have allowance over `from` tokens `amount`.
     */
    function burnFrom(address from, uint256 amount) external;


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

error CircuitBreakerActivated();
error CannotBeZeroAddress();
error TokenNotAccepted();
error TooEarlyToClaim();
error AlreadyHasNode();
error AmountTooSmall();
error DoenstHaveNode();
error BoostTooSmall();
error Unauthorized();
error AmountTooBig();
error TransferFrom();
error Transfer();
error Approve();

/// @title NodeFactory.
/// @author Ghost Nodes Protocol.
/// @notice The NodeFactory contract creates and manages user's node.
contract NodeFactory is Ownable, ReentrancyGuard {
    // <--------------------------------------------------------> //
    // <----------------------- METADATA -----------------------> //
    // <--------------------------------------------------------> //

    IUniswapV2Router02 internal router =
        IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

    address internal immutable wftm;   // WFTM token address.
    address internal immutable gnode;  // Official Ghost Nodes Protocol token.
    address internal immutable lockup; // Iceberg contract.
    address public immutable treasury; // Ghost Nodes Treasury.
    address public immutable research; // Ghost Nodes Research.

    constructor(
        address _wftm,
        address _gnode,
        address _treasury,
        address _research,
        address _lockup
    ) {
        if (_wftm == address(0)) revert CannotBeZeroAddress();
        if (_gnode == address(0)) revert CannotBeZeroAddress();
        if (_treasury == address(0)) revert CannotBeZeroAddress();
        if (_research == address(0)) revert CannotBeZeroAddress();
        if (_lockup == address(0)) revert CannotBeZeroAddress();

        wftm = _wftm;
        gnode = _gnode;
        treasury = _treasury;
        research = _research;
        lockup = _lockup;
    }

    // <--------------------------------------------------------> //
    // <----------------- NODE CONFIGURATION -----------------> //
    // <--------------------------------------------------------> //

    // Node Leagues.
    enum NodeLeague {
        league0,
        league1,
        league2,
        league3,
        league4
    }

    // Maximum amount to be part of leagues
    struct LeagueAmount {
        // Maximum amount to be part of league 0.
        uint256 league0Amount;
        // Maximum amount to be part of league 1.
        uint256 league1Amount;
        // Maximum amount to be part of league 2.
        uint256 league2Amount;
        // Maximum amount to be part of league 3.
        uint256 league3Amount;
    }

    // Internal configs
    struct InternalConfig {
        // Time you have to wait to colect rewards again.
        uint256 rewardsWaitTime;
        // Indicates if swaps are happening or not.
        bool allowTreasurySwap;
    }

    // Node's info.
    struct Node {
        bool exists; // node exists.
        uint256 lastClaimTime; // Last claim.
        uint256 uncollectedRewards; // All pending rewards.
        uint256 balance; // Total Deposited in the node.
        uint256 interestLength; // Last interestRates length.
        NodeLeague league; // Node league.
    }

    /// @notice mapping of all users node.
    mapping(address => Node) public usersNode;

    /// @notice Emitted when a node is created.
    /// @param user address, owner of the node.
    /// @param amount uint256, amount deposited in the node.
    /// @param timeWhenCreated uint256, time when node was created.
    event NodeCreated(
        address indexed user,
        uint256 amount,
        uint256 timeWhenCreated
    );

    /// @notice Emitted when user successfully deposit in his node.
    /// @param user address, user that initiated the deposit.
    /// @param amount uint256, amount that was deposited in the node.
    event SuccessfullyDeposited(address indexed user, uint256 amount);

    /// @notice Emitted when a node is liquidated.
    /// @param user address, owner of the node that was liquidated.
    event NodeLiquidated(address indexed user);

    /// @notice Emitted when the burn percentage is updated.
    /// @param percentage uint256, the new burn percentage.
    event BurnPercentUpdated(uint256 percentage);

    /// @notice Emitted when the minimum deposit required is updated.
    /// @param minDeposit uint256, the new minimum deposit.
    event MinNodeDepositUpdated(uint256 minDeposit);

    /// @notice Emitted when the network boost is updated.
    /// @param newBoost uint256, the new network boost.
    event NetworkBoostUpdated(uint256 newBoost);

    /// @notice Emitted when the liquidateNodePercent is updated.
    /// @param percentage uint256, the new liquidateNodePercent.
    event LiquidateNodePercentUpdated(uint256 percentage);

    /// @notice Emmited when the rewardsWaitTime is updated.
    /// @param time uint256, the re rewardsWaitTime.
    event RewardsWaitTimeUpdated(uint256 time);

    /// @notice Emitted when the treasurySwap is updated.
    /// @param allow bool, the new treasurySwap.
    event TreasurySwapUpdated(bool allow);

    /// @notice Emitted when the circuit breaker is activated.
    /// @param stop bool, true if activated, false otherwise.
    event CircuitBreakerUpdated(bool stop);

    /// @notice Emitted when the minimum amount to be part of a
    ///         certain league is changed.
    /// @param index uint256, the index of the league.
    /// @param amount uint256, the new amount.
    event LeagueAmountUpdated(uint256 index, uint256 amount);

    /// @notice Emmited when Liquidity fase is updated.
    event LiquidityAccumulationPhaseUpdated(bool action);

    /// @notice The minimum amount to deposit in the node.
    uint256 public minNodeDeposit;

    /// @notice Percentage burned when claiming rewards.
    uint256 public burnPercent;

    /// @notice Percetage of GNODE balance user will have after when liquidating node.
    uint256 public liquidateNodePercent;

    /// @notice Used to boost users GNODE.
    uint256 public networkBoost;

    // Used as a circuit breaker
    bool private stopped;

    // Where all league amounts are stored.
    LeagueAmount internal leagueAmounts;

    // Internal configs
    InternalConfig internal internalConfigs;

    /// @notice Updates the burn percentage.
    /// @param percentage uint256, the new burn percentage.
    function setBurnPercent(uint256 percentage) external onlyOwner {
        burnPercent = percentage;
        emit BurnPercentUpdated(percentage);
    }

    /// @notice Updates the minimum required to deposit in the node.
    /// @param minDeposit uint256, the new minimum deposit required.
    function setMinNodeDeposit(uint256 minDeposit) external onlyOwner {
        minNodeDeposit = minDeposit;
        emit MinNodeDepositUpdated(minDeposit);
    }

    /// @notice Updates the network boost.
    /// @param boost uint256, the new network boost.
    function setNetworkBoost(uint256 boost) external onlyOwner {
        if (boost < 1e18) revert BoostTooSmall();
        networkBoost = boost;
        emit NetworkBoostUpdated(boost);
    }

    /// @notice Updates the percentage of the total amount in the node
    ///         user will receive in GNODE when liquidating the vualt.
    /// @param  percentage uint256, the new percentage.
    function setLiquidateNodePercent(uint256 percentage) external onlyOwner {
        liquidateNodePercent = percentage;
        emit LiquidateNodePercentUpdated(percentage);
    }

    /// @notice Updates the time user will have to wait to claim rewards
    ///         again.
    /// @param time uint256, the new wait time.
    function setRewardsWaitTime(uint256 time) external onlyOwner {
        internalConfigs.rewardsWaitTime = time;
        emit RewardsWaitTimeUpdated(time);
    }

    /// @notice Updates the treasury swap status.
    /// @param allow bool, true to activate swap, false otherwise.
    function setTreasurySwap(bool allow) external onlyOwner {
        internalConfigs.allowTreasurySwap = allow;
        emit TreasurySwapUpdated(allow);
    }

    /// @notice Used to pause specific contract functions.
    /// @param stop bool, true to pause function, false otherwise.
    function setCircuitBreaker(bool stop) external onlyOwner {
        stopped = stop;
        emit CircuitBreakerUpdated(stop);
    }

    /// @notice Used to set maximum required to be part of a league.
    /// @param index uint256, the league we are modifing the maximum.
    /// @param amount uint256, the new maximum to be part of league `index`.
    function setLeagueAmount(uint256 index, uint256 amount) external onlyOwner {
        if (index == 0) {
            leagueAmounts.league0Amount = amount;
        } else if (index == 1) {
            leagueAmounts.league1Amount = amount;
        } else if (index == 2) {
            leagueAmounts.league2Amount = amount;
        } else if (index == 3) {
            leagueAmounts.league3Amount = amount;
        }

        emit LeagueAmountUpdated(index, amount);
    }

    // <--------------------------------------------------------> //
    // <------------------ NODES FUNCTIONALITY -----------------> //
    // <--------------------------------------------------------> //

    /// @notice Creates a node for the user.
    /// @param amount uint256, amount that will be deposited in the node.
    function createNode(uint256 amount) external nonReentrant {
        if (stopped) revert CircuitBreakerActivated();
        if (usersNode[msg.sender].exists) revert AlreadyHasNode();
        if (amount < minNodeDeposit) revert AmountTooSmall();

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        usersNode[msg.sender] = Node({
            exists: true,
            lastClaimTime: block.timestamp,
            uncollectedRewards: 0,
            balance: amountBoosted,
            interestLength: pastInterestRates.length,
            league: getNodeLeague(amountBoosted)
        });

        totalNodes += 1;

        emit NodeCreated(msg.sender, amountBoosted, block.timestamp);

        Ignode(gnode).transferFrom(msg.sender, address(this), amount);

        uint256 result = amount;

        if (internalConfigs.allowTreasurySwap) {
            // Swaps 66% of the amount deposit to FTM.
            uint256 swapAmount = mulDivDown(amount, 66e16, SCALE);
            swapGNODEforFTM(swapAmount);
            result -= swapAmount;
        }

        Ignode(gnode).transfer(treasury, result);
    }

    /// @notice Deposits `amount` of specified token in the node.
    /// @param amount uint256, amount that will be deposited in the node.
    function depositInNode(uint256 amount) external nonReentrant {
        Node memory userNode = usersNode[msg.sender];

        if (stopped) revert CircuitBreakerActivated();
        if (!userNode.exists) revert DoenstHaveNode();

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        uint256 totalBalance = userNode.balance + amountBoosted;

        uint256 interest;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != userNode.interestLength) {
            (
                interest,
                userNode.interestLength,
                userNode.lastClaimTime
            ) = getPastInterestRates(
                userNode.interestLength,
                userNode.lastClaimTime,
                userNode.balance
            );
        }

        // ((timeElapsed) * interestRate) / BASETIME
        uint256 rewardsPercent = mulDivDown(
            (block.timestamp - userNode.lastClaimTime),
            interestRate,
            BASETIME
        );

        interest += mulDivDown(userNode.balance, rewardsPercent, SCALE);

        // Update user's node info
        userNode.lastClaimTime = block.timestamp;
        userNode.uncollectedRewards += interest;
        userNode.balance = totalBalance;
        userNode.league = getNodeLeague(totalBalance);

        usersNode[msg.sender] = userNode;

        emit SuccessfullyDeposited(msg.sender, amountBoosted);

        // User needs to approve this contract to spend gnode.
        Ignode(gnode).transferFrom(msg.sender, address(this), amount);

        uint256 result = amount;

        if (internalConfigs.allowTreasurySwap) {
            // Swaps 66% of the amount deposit to FTM.
            uint256 swapAmount = mulDivDown(amount, 66e16, SCALE);
            swapGNODEforFTM(swapAmount);
            result -= swapAmount;
        }

        Ignode(gnode).transfer(treasury, result);
    }

    /// @notice Deletes user's node.
    /// @param user address, the user we are deliting the node.
    function liquidateNode(address user) external nonReentrant {
        Node memory userNode = usersNode[msg.sender];

        if (msg.sender != user) revert Unauthorized();
        if (!userNode.exists) revert DoenstHaveNode();

        // ((timeElapsed) * interestRate) / BASETIME
        uint256 rewardsPercent = mulDivDown(
            (block.timestamp - userNode.lastClaimTime),
            interestRate,
            BASETIME
        );

        uint256 claimableRewards = mulDivDown(
            userNode.balance,
            rewardsPercent,
            SCALE
        ) + userNode.uncollectedRewards;

        // Calculate liquidateNodePercent of user's node balance.
        uint256 gnodePercent = mulDivDown(
            userNode.balance,
            liquidateNodePercent,
            SCALE
        );

        // Delete user node.
        delete usersNode[user];

        protocolDebt += gnodePercent;
        totalNodes -= 1;

        emit NodeLiquidated(user);

        distributeRewards(claimableRewards, user);

        Ignode(gnode).mint(user, gnodePercent);
    }

    /// @notice Allows owner to create a node for a specific user.
    /// @param user address, the user the owner is creating the node for.
    /// @param amount uint256, the amount being deposited in the node.
    function createOwnerNode(address user, uint256 amount) external onlyOwner {
        if (usersNode[msg.sender].exists) revert AlreadyHasNode();
        if (amount < minNodeDeposit) revert AmountTooSmall();

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        usersNode[user] = Node({
            exists: true,
            lastClaimTime: block.timestamp,
            uncollectedRewards: 0,
            balance: amountBoosted,
            interestLength: pastInterestRates.length,
            league: getNodeLeague(amountBoosted)
        });

        totalNodes += 1;

        emit NodeCreated(user, amountBoosted, block.timestamp);

        Ignode(gnode).transferFrom(msg.sender, address(this), amount);

        Ignode(gnode).transfer(treasury, amount);
    }

    /// @notice Calculates the total interest generated based on past interest rates.
    /// @param userInterestLength uint256, the last interest length updated in users node.
    /// @param userLastClaimTime uint256,  the last time user claimed his rewards.
    /// @param userBalance uint256,        user balance in the node.
    /// @return interest uint256,           the total interest accumalted.
    /// @return interestLength uint256,     the updated version of users interest length.
    /// @return lastClaimTime uint256,      the updated version of users last claim time.
    function getPastInterestRates(
        uint256 userInterestLength,
        uint256 userLastClaimTime,
        uint256 userBalance
    )
        internal
        view
        returns (
            uint256 interest,
            uint256 interestLength,
            uint256 lastClaimTime
        )
    {
        interestLength = userInterestLength;
        lastClaimTime = userLastClaimTime;
        uint256 rewardsPercent;

        for (
            interestLength;
            interestLength < pastInterestRates.length;
            interestLength += 1
        ) {
            rewardsPercent = mulDivDown(
                (timeWhenChanged[interestLength] - lastClaimTime),
                pastInterestRates[interestLength],
                BASETIME
            );

            interest += mulDivDown(userBalance, rewardsPercent, SCALE);

            lastClaimTime = timeWhenChanged[interestLength];
        }
    }

    /// @notice Gets the league user is part of depending on the balance in his node.
    /// @param balance uint256, the balance in user's node.
    /// @return tempLeague NodeLeague, the league user is part of.
    function getNodeLeague(uint256 balance)
        public
        view
        returns (NodeLeague tempLeague)
    {
        LeagueAmount memory localLeagueAmounts = leagueAmounts;

        if (balance <= localLeagueAmounts.league0Amount) {
            tempLeague = NodeLeague.league0;
        } else if (
            balance > localLeagueAmounts.league0Amount &&
            balance <= localLeagueAmounts.league1Amount
        ) {
            tempLeague = NodeLeague.league1;
        } else if (
            balance > localLeagueAmounts.league1Amount &&
            balance <= localLeagueAmounts.league2Amount
        ) {
            tempLeague = NodeLeague.league2;
        } else if (
            balance > localLeagueAmounts.league2Amount &&
            balance <= localLeagueAmounts.league3Amount
        ) {
            tempLeague = NodeLeague.league3;
        } else {
            tempLeague = NodeLeague.league4;
        }
    }

    /// @notice swaps GNODE for FTM on ----. The Ghost Nodes Protocol will use the GNODE
    ///         in the treasury to make investments in subnets, and at a certain point the
    ///         team would have to sell its GNODE tokens to make this happen. To avoid
    ///         big dumps in the price, we decided to make a partial sell of the
    ///         GNODE everytime some GNODE goes to the treasury, this will help the team have
    ///         FTM ready to make the investments and will save the community from seeing
    ///         massive dumps in the price.
    /// @param swapAmount uint256, the amount of GNODE we are making the swap.
    function swapGNODEforFTM(uint256 swapAmount) private {
        address[] memory path;
        path = new address[](2);
        path[0] = address(gnode);
        path[1] = wftm;

        uint256 toTreasury = mulDivDown(swapAmount, 75e16, SCALE);
        uint256 toResearch = swapAmount - toTreasury;

        Ignode(gnode).approve(address(router), swapAmount);
        router.swapExactTokensForETH(
            toTreasury,
            0,
            path,
            treasury,
            block.timestamp
        );
        router.swapExactTokensForETH(
            toResearch,
            0,
            path,
            research,
            block.timestamp
        );
    }

    // <--------------------------------------------------------> //
    // <---------------- REWARDS  CONFIGURATION ----------------> //
    // <--------------------------------------------------------> //

    /// @notice Emmited when the reward percentage is updated.
    /// @param reward uint256, the new reward percentage.
    event InterestRateUpdated(uint256 reward);

    // The interestRate is represented as following:
    //   - 100% = 1e18
    //   -  10% = 1e17
    //   -   1% = 1e16
    //   - 0.1% = 1e15
    //   and so on..
    //
    // This allow us to have a really high level of granulatity,
    // and distributed really small amount of rewards with high
    // precision.

    /// @notice Interest rate (per `BASETIME`) i.e. 1e17 = 10% / `BASETIME`
    uint256 public interestRate;

    uint256[] internal pastInterestRates; // Past interest rates.
    uint256[] internal timeWhenChanged; // Last time the interest rate was valid.

    // The level of reward granularity, WAD
    uint256 internal constant SCALE = 1e18;

    // Base time used to calculate rewards.
    uint256 internal constant BASETIME = 365 days;

    /// @notice Updates the reward percentage distributed per `BASETIME`
    /// @param reward uint256, the new reward percentage.
    function setInterestRate(uint256 reward) external onlyOwner {
        if (interestRate != 0) {
            pastInterestRates.push(interestRate);
            timeWhenChanged.push(block.timestamp);
        }
        interestRate = reward;

        emit InterestRateUpdated(reward);
    }

    // <--------------------------------------------------------> //
    // <---------------- REWARDS  FUNCTIONALITY ----------------> //
    // <--------------------------------------------------------> //

    /// @notice Claims the available rewards from user's node.
    /// @param user address, who we are claiming rewards of.
    function claimRewards(address user) external nonReentrant {
        Node memory userNode = usersNode[user];

        uint256 localLastClaimTime = userNode.lastClaimTime;

        if (msg.sender != user) revert Unauthorized();
        if (!userNode.exists) revert DoenstHaveNode();
        if (
            (block.timestamp - localLastClaimTime) <
            internalConfigs.rewardsWaitTime
        ) revert TooEarlyToClaim();

        uint256 claimableRewards;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != userNode.interestLength) {
            (
                claimableRewards,
                userNode.interestLength,
                localLastClaimTime
            ) = getPastInterestRates(
                userNode.interestLength,
                localLastClaimTime,
                userNode.balance
            );
        }

        uint256 rewardsPercent = mulDivDown(
            (block.timestamp - localLastClaimTime),
            interestRate,
            BASETIME
        );

        claimableRewards +=
            mulDivDown(userNode.balance, rewardsPercent, SCALE) +
            userNode.uncollectedRewards;

        // Update user's node info
        userNode.lastClaimTime = block.timestamp;
        userNode.uncollectedRewards = 0;
        usersNode[msg.sender] = userNode;

        distributeRewards(claimableRewards, user);
    }

    /// @notice Distributes the claimable rewards to the user, obeying
    ///         protocol rules.
    /// @param claimableRewards uint256, the total amount of rewards the user is claiming.
    /// @param user address, who we are distributing rewards to.
    function distributeRewards(uint256 claimableRewards, address user) private {
        uint256 mintAmount = claimableRewards;

        (
            uint256 burnAmount,
            uint256 shortLockup,
            uint256 longLockup
        ) = calculateDistribution(claimableRewards);

        claimableRewards -= (burnAmount + shortLockup + longLockup);

        Ignode(gnode).mint(address(this), mintAmount);

        Ignode(gnode).burn(burnAmount); // Burn token

        // Approve and lock rewards.
        Ignode(gnode).approve(address(lockup), (shortLockup + longLockup));
        IIceberg(lockup).lockupRewards(user, shortLockup, longLockup); // Lockup tokens

        // Send immediate rewards to user.
        Ignode(gnode).transfer(user, claimableRewards); // Transfer token to users.
    }

    /// @notice Calculate the final value of the percentage based on the rewards amount.
    /// @param rewards uint256, the amount all the percentages are being calculated on top off.
    /// @return burnAmount uint256,     the amount being burned.
    /// @return shortLockup uint256,    the amount being locked for a shorter period of time.
    /// @return longLockup uint256,     the amount being locked for a longer period of time.
    function calculateDistribution(uint256 rewards)
        internal
        view
        returns (
            uint256 burnAmount,
            uint256 shortLockup,
            uint256 longLockup
        )
    {
        burnAmount = mulDivDown(rewards, burnPercent, SCALE);
        shortLockup = mulDivDown(
            rewards,
            IIceberg(lockup).getShortPercentage(),
            SCALE
        );
        longLockup = mulDivDown(
            rewards,
            IIceberg(lockup).getLongPercentage(),
            SCALE
        );
    }

    /// @notice Checks how much reward the User can get if he claim rewards.
    /// @param user address, who we are checking the pending rewards.
    /// @return pendingRewards uint256, rewards that user can claim at any time.
    /// @return shortLockup uint256, the rewards being locked for a shorter period of time.
    /// @return longLockup uint256, the rewards being locked for a longer period of time.
    function viewPendingRewards(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (!usersNode[user].exists) revert DoenstHaveNode();

        uint256 interestLength = usersNode[user].interestLength;

        uint256 balance = usersNode[user].balance;

        uint256 lastClaimTime = usersNode[user].lastClaimTime;

        uint256 pendingRewards;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != interestLength) {
            (pendingRewards, , lastClaimTime) = getPastInterestRates(
                interestLength,
                lastClaimTime,
                balance
            );
        }

        uint256 timeElapsed = block.timestamp - lastClaimTime;

        uint256 rewardsPercent = mulDivDown(
            timeElapsed,
            interestRate,
            BASETIME
        );

        pendingRewards +=
            mulDivDown(balance, rewardsPercent, SCALE) +
            usersNode[user].uncollectedRewards;

        (
            uint256 burnAmount,
            uint256 shortLockup,
            uint256 longLockup
        ) = calculateDistribution(pendingRewards);

        pendingRewards -= (burnAmount + shortLockup + longLockup);

        return (pendingRewards, shortLockup, longLockup);
    }

    // <--------------------------------------------------------> //
    // <---------------- PROTOCOL FUNCTIONALITY ----------------> //
    // <--------------------------------------------------------> //

    /// @notice Total nodes created.
    uint256 public totalNodes;

    /// @notice Total protocol debt from nodes liquidated.
    uint256 public protocolDebt;

    /// @notice Emitted when protocol debt is repaid.
    /// @param amount uint256, amount of debt that was repaid.
    event DebtReaid(uint256 amount);

    /// @notice Repay the debt created by liquidated vauts.
    /// @param amount uint256, the amount of debt being repaid.
    function repayDebt(uint256 amount) external onlyOwner {
        if (amount >= protocolDebt) revert AmountTooBig();

        protocolDebt -= amount;

        emit DebtReaid(amount);

        // Treasury needs to give permission to this contract.
        Ignode(gnode).burnFrom(msg.sender, amount);
    }

    /// @notice mulDiv rounding down - (x*y)/denominator.
    /// @dev    from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    /// @param x uint256, first operand.
    /// @param y uint256, second operand.
    /// @param denominator uint256, SCALE number.
    /// @return z uint256, result of the mulDiv operation.
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        // solhint-disable-next-line
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    // <--------------------------------------------------------> //
    // <------------------ VIEW FUNCTIONALITY ------------------> //
    // <--------------------------------------------------------> //

    /// @notice Checks if user can claim rewards.
    /// @param user address, the user we are checking if he can claim rewards or not.
    /// @return True if user can claim rewards, false otherwise.
    function canClaimRewards(address user) external view returns (bool) {
        if (!usersNode[user].exists) revert DoenstHaveNode();

        uint256 lastClaimTime = usersNode[user].lastClaimTime;

        if (
            (block.timestamp - lastClaimTime) >= internalConfigs.rewardsWaitTime
        ) return true;

        return false;
    }

    function getPastInterestRatesLength() external view returns (uint256) {
        return pastInterestRates.length;
    }
}