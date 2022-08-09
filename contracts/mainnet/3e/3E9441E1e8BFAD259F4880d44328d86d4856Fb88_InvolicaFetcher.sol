// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import './interfaces/IInvolica.sol';
import './interfaces/IERC20Ext.sol';
import './Oracle.sol';

contract InvolicaFetcher {
    IInvolica public involica;
    Oracle public oracle;

    constructor(address _involica, address _oracle) {
        involica = IInvolica(_involica);
        oracle = Oracle(_oracle);
    }

    function fetchTokensData()
        public
        view
        returns (
            address[] memory tokens,
            uint256[] memory prices,
            address[][] memory routes
        )
    {
        tokens = involica.fetchAllowedTokens();
        prices = new uint256[](tokens.length);
        routes = new address[][](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (prices[i], routes[i]) = oracle.getPriceUsdc(tokens[i]);
        }
    }

    function fetchUserData(address _user)
        public
        view
        returns (
            bool userHasPosition,
            uint256 userTreasury,
            IInvolica.Position memory position,
            uint256 allowance,
            uint256 balance,
            uint256 dcasRemaining,
            IInvolica.UserTokenData[] memory userTokensData
        )
    {
        userTreasury = involica.fetchUserTreasury(_user);

        position = involica.fetchUserPosition(_user);

        userHasPosition = position.user == _user;

        // Fetch wallet allowance and balance
        if (userHasPosition) {
            allowance = IERC20(position.tokenIn).allowance(position.user, address(this));
            balance = IERC20(position.tokenIn).balanceOf(position.user);
            uint256 limitedValue = allowance < balance ? allowance : balance;
            dcasRemaining = position.amountDCA > 0 ? limitedValue / position.amountDCA : 0;
        }

        userTokensData = new IInvolica.UserTokenData[](involica.fetchAllowedTokens().length + 1);
        for (uint256 i = 0; i < userTokensData.length; i++) {
            userTokensData[i] = IInvolica.UserTokenData({
                token: involica.fetchAllowedToken(i),
                allowance: IERC20(involica.fetchAllowedToken(i)).allowance(_user, address(this)),
                balance: IERC20(involica.fetchAllowedToken(i)).balanceOf(_user)
            });
        }
        userTokensData[userTokensData.length - 1] = IInvolica.UserTokenData({
            token: involica.NATIVE_TOKEN(),
            allowance: type(uint256).max,
            balance: _user.balance
        });
    }

    function fetchPairRoute (address token0, address token1) public view returns (address[] memory) {
        return oracle.getRoute(token0, token1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IInvolica {
    // Data Structure

    struct Position {
        address user;
        address tokenIn;
        PositionOut[] outs;
        uint256 amountDCA;
        uint256 intervalDCA;
        uint256 lastDCA;
        uint256 maxGasPrice;
        bytes32 taskId;
        string finalizationReason;
    }
    struct PositionOut {
        address token;
        uint256 weight;
        address[] route;
        uint256 maxSlippage;
    }

    // Output Structure
    struct UserTokenData {
        address token;
        uint256 allowance;
        uint256 balance;
    }
    struct UserTx {
        uint256 timestamp;
        address tokenIn;
        uint256 txFee;
        UserTokenTx[] tokenTxs;
    }
    struct UserTokenTx {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        string err;
    }

    // Events
    event SetPosition(
        address indexed owner,
        address tokenIn,
        PositionOut[] outs,
        uint256 amountDCA,
        uint256 intervalDCA,
        uint256 maxGasPrice
    );
    event PositionUpdated(
        address indexed user,
        uint256 indexed amountDCA,
        uint256 indexed intervalDCA,
        uint256 maxSlippage,
        uint256 maxGasPrice
    );
    event ExitPosition(address indexed user);
    event DepositTreasury(address indexed user, uint256 indexed amount);
    event WithdrawTreasury(address indexed user, uint256 indexed amount);

    event InitializeTask(address indexed user, bytes32 taskId);
    event FinalizeTask(address indexed user, bytes32 taskId, string reason);

    event FinalizeDCA(
        address indexed user,
        address indexed tokenIn,
        uint256 indexed inAmount,
        address[] outTokens,
        uint256[] outAmounts,
        uint256 involicaTxFee
    );

    event SetInvolicaTreasury(address indexed treasury);
    event SetInvolicaTxFee(uint256 indexed txFee);
    event SetResolver(address indexed resolver);
    event SetPaused(bool indexed paused);
    event SetAllowedToken(address indexed token, bool indexed allowed);
    event SetBlacklistedPair(address indexed tokenA, address indexed tokenB, bool indexed blacklisted);
    event MinSlippageSet(uint256 indexed minSlippage);

    // Callable
    function executeDCA(address, uint256[] calldata) external;

    // Public
    function NATIVE_TOKEN() external view returns (address);
    
    function fetchAllowedTokens() external view returns (address[] memory);

    function fetchAllowedToken(uint256 i) external view returns (address);

    function fetchUserTreasury(address user) external view returns (uint256);

    function fetchUserPosition(address user) external view returns (Position memory);

    function fetchUserTxs(address user) external view returns (UserTx[] memory);
}

interface IInvolicaResolver {
    function checkPositionExecutable(address _user) external view returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Ext is IERC20 {
  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import './interfaces/IUniswapV2Router.sol';
import './interfaces/IERC20Ext.sol';

interface PriceRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract Oracle {
    address public wethAddress;
    address public usdcAddress;

    mapping(address => PriceRouter) public routerForFactory;
    PriceRouter public router;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(
        address _routerAddress,
        address _wethAddress,
        address _usdcAddress
    ) {
        router = PriceRouter(_routerAddress);
        usdcAddress = _usdcAddress;
        wethAddress = _wethAddress;
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256 price, address[] memory route) {
        if (tokenAddress == usdcAddress) return (1e6, new address[](0));
        return getPriceFromRouterUsdc(tokenAddress);
    }

    function getPriceFromRouterUsdc(address tokenAddress) public view returns (uint256 price, address[] memory route) {
        return getPriceFromRouter(tokenAddress, usdcAddress);
    }

    function getRoute(address token0Address, address token1Address) public view returns (address[] memory route) {
        (,route) = getPriceFromRouter(token0Address, token1Address);
    }

    function getPriceFromRouter(address token0Address, address token1Address)
        public
        view
        returns (uint256 price, address[] memory route)
    {
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = wethAddress;
        }
        if (token1Address == ethAddress) {
            token1Address = wethAddress;
        }

        address[] memory directPath = new address[](2);
        directPath[0] = token0Address;
        directPath[1] = token1Address;

        // Early exit with direct path if [token0, weth] or [weth, token1]
        if (token0Address == wethAddress || token1Address == wethAddress) {
            return (_amountOut(directPath), directPath);
        }

        // path = [token0, weth, token1] or [token0, token1]
        address[] memory throughWethPath = new address[](3);
        throughWethPath[0] = token0Address;
        throughWethPath[1] = wethAddress;
        throughWethPath[2] = token1Address;

        uint256 throughWethOut = _amountOut(throughWethPath);
        uint256 directOut = _amountOut(directPath);
        if (throughWethOut > directOut) {
            return (throughWethOut, throughWethPath);
        } else {
            return (directOut, directPath);
        }
    }

    function _amountOut(address[] memory path) internal view returns (uint256) {
        IERC20Ext token0 = IERC20Ext(path[0]);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);

        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 20; // .2% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * path.length));
        return amountOut;
    }
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
pragma solidity 0.8.12;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}