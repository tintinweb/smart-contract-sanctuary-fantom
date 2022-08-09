// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IInvolica, IInvolicaResolver} from "./interfaces/IInvolica.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";

contract InvolicaResolver is IInvolicaResolver {
    IInvolica public involica;
    IUniswapV2Router public uniRouter;

    address public owner;

    constructor(address _involica, address _uniRouter) {
        involica = IInvolica(_involica);
        uniRouter = IUniswapV2Router(_uniRouter);
        owner = msg.sender;
    }


    function checkPositionExecutable(address _user)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IInvolica.Position memory position = involica.fetchUserPosition(_user);

        if (position.user != _user || position.taskId == bytes32(0)) return (false, bytes("User doesnt have a position"));
        if (block.timestamp < (position.lastDCA + position.intervalDCA)) return (false, bytes("DCA not mature"));
        if (position.maxGasPrice > 0 && tx.gasprice > position.maxGasPrice) return (false, bytes("Gas too expensive"));
        canExec = true;

        uint256[] memory amounts;
        uint256[] memory swapsAmountOutMin = new uint256[](position.outs.length);
        for (uint256 i = 0; i < position.outs.length; i++) {
            amounts = uniRouter.getAmountsOut(
                position.amountDCA * position.outs[i].weight / 10_000,
                position.outs[i].route
            );
            swapsAmountOutMin[i] = amounts[amounts.length - 1] * (10_000 - position.outs[i].maxSlippage) / 10_000;
        }

        execPayload = abi.encodeWithSelector(
            IInvolica.executeDCA.selector,
            _user,
            swapsAmountOutMin
        );
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