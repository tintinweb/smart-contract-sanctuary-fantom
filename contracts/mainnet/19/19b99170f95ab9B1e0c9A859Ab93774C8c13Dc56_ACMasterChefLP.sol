// SPDX-License-Identifier: MIT

//// _____.___.__       .__       ._____      __      .__   _____  ////
//// \__  |   |__| ____ |  |    __| _/  \    /  \____ |  |_/ ____\ ////
////  /   |   |  |/ __ \|  |   / __ |\   \/\/   /  _ \|  |\   __\  ////
////  \____   |  \  ___/|  |__/ /_/ | \        (  <_> )  |_|  |    ////
////  / ______|__|\___  >____/\____ |  \__/\  / \____/|____/__|    ////
////  \/              \/           \/       \/                     ////

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './AutoCompoundVault.sol';

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

/**
 * @title AutoCompound MasterChef
 * @notice vault for auto-compounding LPs on pools using a standard MasterChef contract
 * @author YieldWolf
 */
contract ACMasterChefLP is AutoCompoundVault {
    IUniswapV2Router02 public immutable liquidityRouter; // router used for adding liquidity to the LP token
    IERC20 public immutable token0; // first token of the lp
    IERC20 public immutable token1; // second token of the lp

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pid,
        address[6] memory _addresses,
        IUniswapV2Router02 _liquidityRouter
    ) ERC20(_name, _symbol) AutoCompoundVault(_pid, _addresses) {
        token0 = IERC20(IUniswapV2Pair(_addresses[1]).token0());
        token1 = IERC20(IUniswapV2Pair(_addresses[1]).token1());
        liquidityRouter = _liquidityRouter;
        token0.approve(address(liquidityRouter), type(uint256).max);
        token1.approve(address(liquidityRouter), type(uint256).max);
    }

    function _earnToStake(uint256 _earnAmount) internal override {
        uint256 halfEarnAmount = _earnAmount / 2;
        if (earnToken != token0) {
            _safeSwap(halfEarnAmount, address(earnToken), address(token0));
        }
        if (earnToken != token1) {
            _safeSwap(_earnAmount - halfEarnAmount, address(earnToken), address(token1));
        }
        uint256 token0Amt = token0.balanceOf(address(this));
        uint256 token1Amt = token1.balanceOf(address(this));
        liquidityRouter.addLiquidity(
            address(token0),
            address(token1),
            token0Amt,
            token1Amt,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function _farmDeposit(uint256 amount) internal override {
        IFarm(masterChef).deposit(pid, amount);
    }

    function _farmWithdraw(uint256 amount) internal override {
        IFarm(masterChef).withdraw(pid, amount);
    }

    function _farmEmergencyWithdraw() internal override {
        IFarm(masterChef).emergencyWithdraw(pid);
    }

    function _totalStaked() internal view override returns (uint256 amount) {
        (amount, ) = IFarm(masterChef).userInfo(pid, address(this));
    }

    function _addAllawences() internal override {
        IERC20(stakeToken).approve(masterChef, type(uint256).max);
        token0.approve(address(liquidityRouter), type(uint256).max);
        token1.approve(address(liquidityRouter), type(uint256).max);
    }

    function _removeAllawences() internal override {
        IERC20(stakeToken).approve(masterChef, 0);
        token0.approve(address(liquidityRouter), 0);
        token1.approve(address(liquidityRouter), 0);
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

//// _____.___.__       .__       ._____      __      .__   _____  ////
//// \__  |   |__| ____ |  |    __| _/  \    /  \____ |  |_/ ____\ ////
////  /   |   |  |/ __ \|  |   / __ |\   \/\/   /  _ \|  |\   __\  ////
////  \____   |  \  ___/|  |__/ /_/ | \        (  <_> )  |_|  |    ////
////  / ______|__|\___  >____/\____ |  \__/\  / \____/|____/__|    ////
////  \/              \/           \/       \/                     ////

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/IYieldWolf.sol';
import '../route-oracle/interfaces/IRouteOracle.sol';

/**
 * @title Auto Compound Strategy
 * @notice handles deposits and withdraws on the underlying farm and auto-compound rewards
 * @author YieldWolf
 */
abstract contract AutoCompoundVault is ERC20, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IYieldWolf public immutable yieldWolf; // address of the YieldWolf staking contract
    address public immutable masterChef; // address of the farm staking contract
    uint256 public immutable pid; // pid of pool in the farm staking contract
    IERC20 public immutable stakeToken; // token staked on the underlying farm
    IERC20 public immutable earnToken; // reward token paid by the underlying farm
    address[] public extraEarnTokens; // some underlying farms can give rewards in multiple tokens
    mapping(address => bool) tokenRestricted; // these can never be used as an extra earn token or on tokenToEarn
    address immutable WNATIVE; // address of the network's wrapped native currency

    IRouteOracle public immutable routeOracle;

    bool public emergencyWithdrawn;

    uint256 constant PERFORMANCE_FEE = 300;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Earn();
    event Farm();
    event EmergencyWithdraw();
    event TokenToEarn(address token);
    event WrapNative();
    event SetExtraEarnTokens(address[] _extraEarnTokens);
    event SetTokenRestricted(address _address);

    modifier onlyOwner() {
        require(address(yieldWolf) == _msgSender(), 'onlyOwner: not allowed');
        _;
    }

    modifier onlyOperator() {
        require(yieldWolf.operators(msg.sender), 'onlyOperator: not allowed');
        _;
    }

    function _farmDeposit(uint256 depositAmount) internal virtual;

    function _farmWithdraw(uint256 withdrawAmount) internal virtual;

    function _earnToStake(uint256 _earnAmount) internal virtual;

    function _farmEmergencyWithdraw() internal virtual;

    function _totalStaked() internal view virtual returns (uint256);

    receive() external payable {}

    constructor(uint256 _pid, address[6] memory _addresses) {
        yieldWolf = IYieldWolf(_addresses[0]);
        stakeToken = IERC20(_addresses[1]);
        earnToken = IERC20(_addresses[2]);
        masterChef = _addresses[3];
        routeOracle = IRouteOracle(_addresses[4]);
        WNATIVE = _addresses[5];
        pid = _pid;
        IERC20(stakeToken).approve(masterChef, type(uint256).max);
        tokenRestricted[address(this)] = true;
        tokenRestricted[address(earnToken)] = true;
        tokenRestricted[address(stakeToken)] = true;
    }

    /**
     * @notice deposits stake tokens in the underlying farm
     * @dev can only be called by YieldWolf contract which performs the required validations
     * @param _user address
     * @param _depositAmount amount deposited by the user
     */
    function deposit(address _user, uint256 _depositAmount) external virtual onlyOwner whenNotPaused {
        uint256 stakeTokenAmount = stakeToken.balanceOf(address(this));
        uint256 totalStakedBefore = _totalStaked() + stakeTokenAmount - _depositAmount;
        _farmDeposit(stakeTokenAmount);
        uint256 totalStakedAfter = _totalStaked() + stakeToken.balanceOf(address(this));

        // adjust for deposit fees on the underlying farm and token transfer fees
        _depositAmount = totalStakedAfter - totalStakedBefore;

        uint256 sharesAdded = _depositAmount;
        uint256 _totalSupply = totalSupply();
        if (totalStakedBefore > 0 && _totalSupply > 0) {
            sharesAdded = (_depositAmount * _totalSupply) / totalStakedBefore;
        }

        _mint(_user, sharesAdded);
        emit Deposit(_user, _depositAmount);
    }

    /**
     * @notice unstake tokens from the underlying farm and transfers them to the given address
     * @dev can only be called by YieldWolf contract
     * @param _user address that will receive the stake tokens
     * @param _withdrawAmount number of vault tokens to withdraw
     */
    function withdraw(address _user, uint256 _withdrawAmount) external virtual onlyOwner nonReentrant {
        require(_withdrawAmount > 0, 'withdraw: cannot be zero');
        uint256 totalStakedOnFarm = _totalStaked();
        uint256 stakeAmountBefore = stakeToken.balanceOf(address(this));
        uint256 totalStake = totalStakedOnFarm + stakeAmountBefore;
        uint256 sharesTotal = totalSupply();
        uint256 userBalance = balanceOf(_user);

        require(userBalance > 0, 'withdraw: no shares');

        uint256 maxAmount = (userBalance * totalStake) / sharesTotal;
        if (_withdrawAmount > maxAmount) {
            _withdrawAmount = maxAmount;
        }

        // number of shares that the withdraw amount represents (rounded up)
        uint256 sharesRemoved = (_withdrawAmount * sharesTotal - 1) / totalStake + 1;

        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }

        if (totalStakedOnFarm > 0) {
            _farmWithdraw(_withdrawAmount);
            uint256 totalWithdrawn = stakeToken.balanceOf(address(this)) - stakeAmountBefore;
            if (_withdrawAmount > totalWithdrawn) {
                _withdrawAmount = totalWithdrawn;
            }
        }

        uint256 stakeBalance = stakeToken.balanceOf(address(this));
        if (_withdrawAmount > stakeBalance) {
            _withdrawAmount = stakeBalance;
        }

        _burn(_user, sharesRemoved);
        stakeToken.safeTransfer(_user, _withdrawAmount);
        emit Withdraw(_user, _withdrawAmount);
    }

    /**
     * @notice deposits the contract's balance of stake tokens in the underlying farm
     */
    function farm() external virtual nonReentrant whenNotPaused {
        _farm();
        emit Farm();
    }

    /**
     * @notice harvests earn tokens and deposits stake tokens in the underlying farm
     * @param _bountyHunter address that will get paid the bounty reward
     */
    function earn(address _bountyHunter) external virtual nonReentrant returns (uint256 bountyReward) {
        if (paused()) {
            return 0;
        }

        // harvest earn tokens
        uint256 earnAmountBefore = earnToken.balanceOf(address(this));
        _farmHarvest();

        for (uint256 i; i < extraEarnTokens.length; ) {
            address extraEarnToken = extraEarnTokens[i];
            uint256 balanceExtraEarn = IERC20(extraEarnToken).balanceOf(address(this));
            _trySafeSwap(balanceExtraEarn, extraEarnToken, address(earnToken));
            unchecked {
                i++;
            }
        }

        uint256 earnAmountAfter = earnToken.balanceOf(address(this));
        uint256 harvestAmount = earnAmountAfter - earnAmountBefore;

        uint256 platformFee;
        if (harvestAmount > 0) {
            (bountyReward, platformFee) = _distributeFees(harvestAmount, _bountyHunter);
        }
        uint256 earnAmount = earnAmountAfter - platformFee - bountyReward;

        _earnToStake(earnAmount);
        _farm();

        if (_bountyHunter != address(0)) {
            emit Earn();
        }
    }

    /**
     * @notice pauses the vault in case of emergency
     * @dev can only be called by the operator. Only in case of emergency.
     */
    function pause() external virtual onlyOperator {
        _removeAllawences();
        _pause();
    }

    /**
     * @notice unpauses the vault
     * @dev can only be called by the operator
     */
    function unpause() external virtual onlyOperator {
        require(!emergencyWithdrawn, 'unpause: cannot unpause after emergency withdraw');
        _addAllawences();
        _unpause();
    }

    /**
     * @notice updates the list of extra earn tokens
     * @dev can only be called by the operator
     */
    function setExtraEarnTokens(address[] calldata _extraEarnTokens) external virtual onlyOperator {
        require(_extraEarnTokens.length <= 5, 'setExtraEarnTokens: cap exceeded');

        for (uint256 i; i < _extraEarnTokens.length; i++) {
            require(
                !tokenRestricted[_extraEarnTokens[i]] &&
                    _extraEarnTokens[i] != address(earnToken) &&
                    _extraEarnTokens[i] != address(stakeToken),
                'setExtraEarnTokens: not allowed'
            );

            // erc20 sanity check
            IERC20(_extraEarnTokens[i]).balanceOf(address(this));
        }

        extraEarnTokens = _extraEarnTokens;
        emit SetExtraEarnTokens(_extraEarnTokens);
    }

    function setTokenRestricted(address _addr) external onlyOperator {
        tokenRestricted[_addr] = true;
        emit SetTokenRestricted(_addr);
    }

    /**
     * @notice converts any token in the contract into earn tokens
     * @dev can only be called by the operator
     */
    function tokenToEarn(address _token) external virtual nonReentrant whenNotPaused onlyOperator {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(!tokenRestricted[_token], 'tokenToEarn: not allowed');
        if (amount > 0) {
            _safeSwap(amount, _token, address(earnToken));
        }
        emit TokenToEarn(_token);
    }

    /**
     * @notice converts NATIVE into WNATIVE (e.g. ETH -> WETH)
     */
    function wrapNative() external virtual {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWETH(WNATIVE).deposit{value: balance}();
        }
        emit WrapNative();
    }

    function totalStakeTokens() external view virtual returns (uint256) {
        return _totalStaked() + stakeToken.balanceOf(address(this));
    }

    /**
     * @notice invokes the emergency withdraw function in the underlying farm
     * @dev can only be called by the operator. Only in case of emergency.
     */
    function emergencyWithdraw() external virtual onlyOperator {
        if (!paused()) {
            _pause();
        }
        emergencyWithdrawn = true;
        _farmEmergencyWithdraw();
        emit EmergencyWithdraw();
    }

    function _farm() internal virtual {
        uint256 depositAmount = stakeToken.balanceOf(address(this));
        _farmDeposit(depositAmount);
    }

    function _farmHarvest() internal virtual {
        _farmDeposit(0);
    }

    function _distributeFees(uint256 _amount, address _bountyHunter)
        internal
        virtual
        returns (uint256 bountyReward, uint256 platformFee)
    {
        platformFee = (_amount * PERFORMANCE_FEE) / 10000;
        if (_bountyHunter != address(0)) {
            bountyReward = platformFee / 10;
            unchecked {
                platformFee = platformFee - bountyReward;
            }
            earnToken.safeTransfer(_bountyHunter, bountyReward);
        }
        earnToken.safeTransfer(yieldWolf.feeAddress(), platformFee);
    }

    function _addAllawences() internal virtual {
        IERC20(stakeToken).approve(masterChef, type(uint256).max);
    }

    function _removeAllawences() internal virtual {
        IERC20(stakeToken).approve(masterChef, 0);
        for (uint256 i; i < extraEarnTokens.length; i++) {
            IERC20(extraEarnTokens[i]).approve(masterChef, 0);
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address _tokenFrom,
        address _tokenTo
    ) internal virtual {
        (address router, address nextToken, bytes memory sig) = routeOracle.resolveSwapExactTokensForTokens(
            _amountIn,
            _tokenFrom,
            _tokenTo,
            address(this)
        );
        require(router != address(this) && router != masterChef, '_safeSwap: invalid router');
        if (router == address(stakeToken)) {
            require(
                !(sig[0] == 0xa9 && sig[1] == 0x05 && sig[2] == 0x9c && sig[3] == 0xbb) &&
                    !(sig[0] == 0x23 && sig[1] == 0xb8 && sig[2] == 0x72 && sig[3] == 0xdd) &&
                    !(sig[0] == 0x09 && sig[1] == 0x5e && sig[2] == 0xa7 && sig[3] == 0xb3),
                '_safeSwap: not allowed'
            );
        }
        if (IERC20(_tokenFrom).allowance(address(this), router) < _amountIn) {
            IERC20(_tokenFrom).approve(router, type(uint256).max);
        }
        uint256 nextTokenBalanceBefore;
        if (nextToken != address(0)) {
            nextTokenBalanceBefore = IERC20(nextToken).balanceOf(address(this));
        }
        (bool success, ) = router.call(sig);
        require(success, '_safeSwap: swap failed');
        if (nextToken != address(0)) {
            uint256 nextTokenAmount = IERC20(nextToken).balanceOf(address(this)) - nextTokenBalanceBefore;
            _safeSwap(nextTokenAmount, nextToken, _tokenTo);
        }
    }

    function _trySafeSwap(
        uint256 _amountIn,
        address _tokenFrom,
        address _tokenTo
    ) internal virtual {
        (address router, address nextToken, bytes memory sig) = routeOracle.resolveSwapExactTokensForTokens(
            _amountIn,
            _tokenFrom,
            _tokenTo,
            address(this)
        );
        require(router != address(this) && router != masterChef, '_trySafeSwap: invalid router');
        if (router == address(stakeToken)) {
            require(
                !(sig[0] == 0xa9 && sig[1] == 0x05 && sig[2] == 0x9c && sig[3] == 0xbb) &&
                    !(sig[0] == 0x23 && sig[1] == 0xb8 && sig[2] == 0x72 && sig[3] == 0xdd) &&
                    !(sig[0] == 0x09 && sig[1] == 0x5e && sig[2] == 0xa7 && sig[3] == 0xb3),
                '_trySafeSwap: not allowed'
            );
        }
        if (IERC20(_tokenFrom).allowance(address(this), router) < _amountIn) {
            IERC20(_tokenFrom).approve(router, type(uint256).max);
        }
        uint256 nextTokenBalanceBefore;
        if (nextToken != address(0)) {
            nextTokenBalanceBefore = IERC20(nextToken).balanceOf(address(this));
        }
        (bool success, ) = router.call(sig);
        if (success && nextToken != address(0)) {
            uint256 nextTokenAmount = IERC20(nextToken).balanceOf(address(this)) - nextTokenBalanceBefore;
            _safeSwap(nextTokenAmount, nextToken, _tokenTo);
        }
    }
}

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IYieldWolf {
    function operators(address addr) external returns (bool);

    function feeAddress() external returns (address);

    function stakedTokens(uint256 pid, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRouteOracle {
    function resolveSwapExactTokensForTokens(
        uint256 amountIn,
        address tokenFrom,
        address tokenTo,
        address recipient
    )
        external
        view
        returns (
            address router,
            address nextToken,
            bytes memory sig
        );
}

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