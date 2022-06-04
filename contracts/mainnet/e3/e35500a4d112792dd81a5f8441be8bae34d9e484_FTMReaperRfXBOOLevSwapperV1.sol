/**
 *Submitted for verification at FtmScan.com on 2022-06-04
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @sushiswap/core/contracts/uniswapv2/interfaces/[email protected]



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


// File @sushiswap/core/contracts/uniswapv2/interfaces/[email protected]



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


// File contracts/swappers/Leverage/TombFtmLevSwapper.sol


pragma solidity 0.8.4;



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IBentoBoxV1 {
    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);
}

interface CurvePool is IERC20 {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;
}

interface IVault is IERC20 {
    function deposit(uint _amount) external;
}

interface IUniswapV2Factory {
    function swapFee() external view returns (uint);
}

contract FTMReaperRfXBOOLevSwapperV1 {
    
    IBentoBoxV1 public constant DEGENBOX = IBentoBoxV1(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    CurvePool public constant MIM3POOL = CurvePool(0x075C1D1d7E9E1aF077B0b6117C6eA06CD0a260b5);

    IUniswapV2Router01 public constant ROUTER = IUniswapV2Router01(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    
    uint256 private constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000; // ~ placeholder for swap deadline

    IERC20 public constant MIM = IERC20(0x2126be94443334Fd71428dBa3c638fB722d1838e);

    IERC20 public constant WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 public constant USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 public constant BOO = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);

    IVault constant public booVault = IVault(0xFC550BAD3c14160CBA7bc05ee263b3F060149AFF); 

    constructor() {
        BOO.approve(address(booVault), type(uint256).max);
        booVault.approve(address(DEGENBOX), type(uint256).max);
        USDC.approve(address(ROUTER), type(uint256).max);
        MIM.approve(address(MIM3POOL), type(uint256).max);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        
        uint256 amountIntermediate;

        {
            (uint256 amountFrom, ) = DEGENBOX.withdraw(MIM, address(this), address(this), 0, shareFrom);

            uint256 amountIntermediate_usdc = MIM3POOL.exchange_underlying(0, 2, amountFrom, 0, address(this));

            address[] memory path = new address[](3);
            path[0] = address(USDC);
            path[1] = address(WFTM);
            path[2] = address(BOO);
            // address[3] memory path = [address(USDC),address(WFTM),address(BOO)];

            uint[] memory amounts = ROUTER.getAmountsOut(amountIntermediate_usdc, path);

            uint[] memory swap_amounts = ROUTER.swapExactTokensForTokens(
                amountIntermediate_usdc,
                amounts[2],
                path,
                address(this),
                DEADLINE
            );

            amountIntermediate = swap_amounts[2];
        }

        booVault.deposit(amountIntermediate);
        uint256 amountTo = booVault.balanceOf(address(this));

        (, shareReturned) = DEGENBOX.deposit(booVault, address(this), recipient, amountTo, 0);
        extraShare = shareReturned - shareToMin;
    }
}