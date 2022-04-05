// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface IWFTM 
{
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract DEXTax
{
    address beneficiary;
    address public immutable WFTM;
    address public immutable yoshiRouter;
    address public immutable yoshiFactory;

    struct RouteItem
    {
        address router;
        address[] path;
    }

    constructor (address _beneficiary, address _WFTM, address _yoshiRouter, address _yoshiFactory) 
        payable
    {
        beneficiary = _beneficiary;
        WFTM = _WFTM;
        yoshiRouter = _yoshiRouter;
        yoshiFactory = _yoshiFactory;
    }

    receive() external payable {}

    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender, "Ownable: caller is not the beneficiary");
        _;
    }

    function setBeneficiary(address _beneficiary) 
        public onlyBeneficiary 
    {
        beneficiary = _beneficiary;
    }

    function Fee(uint amountIn) 
        internal pure returns (uint fee)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        fee = amountIn * 15 / 10000;

        require(fee > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function amountMFee(uint amountIn) 
        internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        amountOut = amountIn - Fee(amountIn);

        require(amountOut > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function amountPFee(uint amountIn) 
        internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        amountOut = amountIn + Fee(amountIn);

        require(amountOut > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function safeTransfer(address to, uint256 value) 
        internal
    {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function sendFTM(address to, uint amount) 
        external payable onlyBeneficiary
    {
        (bool success,) = to.call{value : amount}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function send(address token, address to, uint amount) 
        public onlyBeneficiary
    {
        IERC20(token).transfer(to, amount);
    }

    function approve(address token, address spender, uint amount) 
        internal
    {
        uint256 allowed = IERC20(token).allowance(address(this), spender);
        if (allowed < amount)
        {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function takeFee(address token0, address token1) 
        internal    
    {
        uint token0amount = IERC20(token0).balanceOf(address(this));
        uint token1amount = IERC20(token1).balanceOf(address(this));
    
        if (IUniswapV2Factory(yoshiFactory).getPair(token0, token1) == address(0)) 
        {
            IERC20(token0).transfer(beneficiary, token0amount);
            IERC20(token1).transfer(beneficiary, token1amount);
        }
        else
        {
            approve(token0, yoshiRouter, token0amount);
            approve(token1, yoshiRouter, token1amount);
            IUniswapV2Router02(yoshiRouter).addLiquidity(token0, token1, token0amount, token1amount, 0, 0, beneficiary, block.timestamp);
        }
    }

    function calcRouteLength(RouteItem[] calldata route) 
        internal pure returns (uint result)
    {
        result = 0;
        for (uint i = 0; i < route.length; i++)
        {
            result += route[i].path.length;
        }
    }

    function getAmountsOut(RouteItem[] calldata route, uint amountIn)
        public view returns (uint[] memory amounts)
    {
        amounts = new uint[](calcRouteLength(route));

        uint stepAmountIn = amountMFee(amountIn);
        uint outPos = 0;
        
        for (uint i = 0; i < route.length; i++)
        {
            uint[] memory stepAmounts = IUniswapV2Router02(route[i].router).getAmountsOut(stepAmountIn, route[i].path);
            for (uint j = 0; j < route[i].path.length; j++)
            {
                amounts[outPos++] = stepAmounts[j];
            }

            stepAmountIn = stepAmounts[stepAmounts.length - 1];
        }

        amounts[0] = amountIn;      
        amounts[amounts.length - 1] = amountMFee(amounts[amounts.length - 1]);
    }

    function getAmountsIn(RouteItem[] calldata route, uint amountOut)
        public view returns (uint[] memory amounts, uint value)
    {
        uint routeLength = calcRouteLength(route);
        amounts = new uint[](routeLength);

        uint stepAmountOut = amountPFee(amountOut);
        uint outPos = routeLength;
        
        for (uint i = route.length; i > 0; i--)
        {
            uint[] memory stepAmounts = IUniswapV2Router02(route[i - 1].router).getAmountsIn(stepAmountOut, route[i - 1].path);
            for (uint j = route[i - 1].path.length; j > 0; j--)
            {
				outPos -= 1;
                amounts[outPos] = stepAmounts[j - 1];
            }

            stepAmountOut = stepAmounts[0];
        }

		value = amounts[0];
        amounts[0] = amountPFee(amounts[0]);
        amounts[amounts.length - 1] = amountOut;
    }

    function doSwaps(RouteItem[] calldata route, uint amount, uint deadline) 
        internal returns (uint amountOut)
    {
        uint[] memory amounts;

        for (uint i = 0; i < route.length; i++)
        {
            approve(route[i].path[0], route[i].router, amount);
            amounts = IUniswapV2Router02(route[i].router).swapExactTokensForTokens(amount, 0, route[i].path, address(this), deadline);

            amount = amounts[amounts.length - 1];
        }

        amountOut = amount;
    }

    function getLastToken(RouteItem[] calldata route) 
        internal pure returns(address)
    {
        return route[route.length - 1].path[route[route.length - 1].path.length - 1];
    }

    function doSwapsForTokens(RouteItem[] calldata route, uint amountIn, address to, uint deadline)
        internal
    {
        uint amountOut = doSwaps(route, amountIn, deadline);

        address token1 = getLastToken(route);
        IERC20(token1).transfer(to, amountMFee(amountOut));

        takeFee(route[0].path[0], token1);
    }

    function doSwapsForETH(RouteItem[] calldata route, uint amountIn, address to, uint deadline)
        internal
    {
        uint amountOut = doSwaps(route, amountIn, deadline);
        uint amountOutMFee = amountMFee(amountOut);

        IWFTM(WFTM).withdraw(amountOutMFee);
        safeTransfer(to, amountOutMFee);

        takeFee(route[0].path[0], WFTM);
    }

    function swapExactTokensForTokens(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
        external returns (uint[] memory amounts)
    {
        amounts = getAmountsOut(route, amountIn);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amountIn);
        doSwapsForTokens(route, amountMFee(amountIn), to, deadline);
    }

    function swapTokensForExactTokens(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
        external returns (uint[] memory amounts)
    {
		uint value;
        (amounts,  value) = getAmountsIn(route, amountOut);
        require(amounts[0] <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amounts[0]);
        doSwapsForTokens(route, value, to, deadline);
    }

    function swapExactETHForTokens(RouteItem[] calldata route, uint amountOutMin, address to, uint deadline)
        external payable returns (uint[] memory amounts)
    {
        require(route[0].path[0] == WFTM, "INVALID_PATH");
        amounts = getAmountsOut(route, msg.value);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        IWFTM(WFTM).deposit{value: amounts[0]}();
        doSwapsForTokens(route, amountMFee(amounts[0]), to, deadline);
    }

    function swapTokensForExactETH(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
        external returns (uint[] memory amounts)    
    {
        require(getLastToken(route) == WFTM, "INVALID_PATH");
		uint value;
        (amounts, value) = getAmountsIn(route, amountOut);
        require(amounts[0] <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amounts[0]);
        doSwapsForETH(route, value, to, deadline);
    }

    function swapExactTokensForETH(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
        external returns (uint[] memory amounts)
    {
        require(getLastToken(route) == WFTM, "INVALID_PATH");
        amounts = getAmountsOut(route, amountIn);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amountIn);
        doSwapsForETH(route, amountMFee(amountIn), to, deadline);
    }

    function swapETHForExactTokens(RouteItem[] calldata route, uint amountOut, address to, uint deadline)
        external payable returns (uint[] memory amounts)
    {
        require(route[0].path[0] == WFTM, "INVALID_PATH");
		uint value;
        (amounts, value) = getAmountsIn(route, amountOut);
        require(amounts[0] <= msg.value, "EXCESSIVE_INPUT_AMOUNT");

        IWFTM(WFTM).deposit{value: amounts[0]}();
        doSwapsForTokens(route, value, to, deadline);

        if (msg.value > amounts[0])
        {
            safeTransfer(msg.sender, msg.value - amounts[0]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
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