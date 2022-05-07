/**
 *Submitted for verification at FtmScan.com on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface LPIncentive {
    function getReward(address account) external;
    function earned(address account) external view returns (uint256) ;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract MSTHelper {
    //mdao
    LPIncentive lp = LPIncentive(0xc13926C5CB2636a29381Da874b1e2686163DC226);
    //spookyswap router
    IUniswapV2Router router = IUniswapV2Router(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    // mst/usdc pair
    IUniswapV2Pair pair =IUniswapV2Pair(0x1f5c5b104d6246B3d096135806cd6C6e53e206F1);

    //event
    event SellEvent(uint earned,uint8 path, uint amountOut);
    event ReinvestEvent(uint8 status);


    uint256 internal constant MINREWARDS = 1*10**18;
    uint112 reserve0;
    uint112 reserve1;
    uint32 lastTime;
    address public token_mst;
    address public token_usdc;
    address public token_weth;

    constructor(address _token0,address _token1,address _weth){
        token_mst = _token0;
        token_usdc = _token1;
        token_weth = _weth;
    }

    function reinvest() external {
        uint earned = lp.earned(msg.sender);
        
        if(earned > MINREWARDS) {
            
            address[] memory path1 = new address[](2);
            address[] memory path2 = new address[](3);

            path1[0]=token_mst;
            path1[1]=token_usdc;

            path2[0]=token_mst;
            path2[1]=token_weth;
            path2[2]=token_usdc;

            uint amountIn = earned / 2;
            uint[] memory result;

            uint[] memory amountOut1 = router.getAmountsOut(amountIn,path1);
            uint[] memory amountOut2 = router.getAmountsOut(amountIn,path2);

            require(amountOut1.length > 0 && amountOut2.length > 0);

            //sell half
            if(amountOut1[amountOut1.length-1] > amountOut2[amountOut2.length-1]){
                uint amountOutMin = amountOut1[amountOut1.length-1] * 98 / 100;
                result = router.swapExactTokensForTokens(amountIn,amountOutMin,path1,msg.sender,block.timestamp + 10);
                emit SellEvent(amountIn,1,result[result.length-1]);
            }else{
                uint amountOutMin = amountOut2[amountOut2.length-1] * 98 / 100;
                result = router.swapExactTokensForTokens(amountIn,amountOutMin,path2,msg.sender,block.timestamp + 10);
                emit SellEvent(amountIn,2,result[result.length-1]);
            }
           
            //reinvest
            router.addLiquidity(token_usdc,token_usdc,amountIn,result[result.length-1],amountIn*95/100,result[result.length-1]*95/100,msg.sender,block.timestamp + 10);
            emit ReinvestEvent(1);

        }
    }

}