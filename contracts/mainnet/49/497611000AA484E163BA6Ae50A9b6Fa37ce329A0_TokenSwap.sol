/**
 *Submitted for verification at FtmScan.com on 2022-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

interface IPancakePair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

library PancakeLibrary {

	using SafeMath for uint256;


        // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Library Sort: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Library Sort: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address pairAddress,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pairAddress).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }    
}

contract TokenSwap {

    event ValueChanged(uint oldValue, uint256 newValue);

    using SafeMath for uint;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
        
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    receive() external payable {}
    
    function sweep(address _tokenAddress) onlyOwner public {
        uint balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }
    
    // amountIn: (input amount in Wei)
    // path : (token addresses for swaps)  
    // pairs: (lp pairs from different DEX)
    // fees : (lp fee sample below)
    //     0.30% lp fee: 10000 - 30 = 9970
    //     0.20% lp fee: 10000 - 20 = 9980
    //     0.25% lp fee: 10000 - 25 = 9975
    
    // -- sample input 
    // Contract must have enough "Token1" for swap to execute
    // amountIn: 1000000000000000000
    // path: ['Token1', 'Token2', 'Token3', 'Token1']
    // pairs: [lp1, lp2, lp3]
    // fees:  [lp1_fee, lp2_fee, lp3_fee]
    function swap(uint amountIn, uint amountOutMin, address[] calldata path, address[] calldata pairs, uint[] calldata fees) external {
       
        uint[] memory amounts = getAmountsOut(amountIn, path, pairs, fees);

        require(amounts[amounts.length - 1] > amountOutMin, "ARF FAIL"); // ARF = ARB
        
        bool transfer = IERC20(path[0]).transfer(pairs[0], amounts[0]);

        require(transfer, "transfer failed");

        for (uint i; i < pairs.length; i++) {
            address to = i == pairs.length - 1 ? address(this) : pairs[i+1];
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            
            IPancakePair(pairs[i]).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    
    function getAmountsOut(uint amountIn, address[] memory path, address[] memory pair, uint[] memory fees) private view returns (uint[] memory amounts) {
		uint256 reserveIn;			  
		uint256 reserveOut;				   
        amounts = new uint[](pair.length+1);
        amounts[0] = amountIn;
        for (uint i; i < pair.length; i++) {
            (reserveIn, reserveOut) = PancakeLibrary.getReserves(
                            pair[i],
                            path[i],
                            path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fees[i]);
        }													 
    }

     // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 tenThousand = 10000;
        uint256 amountInWithFee = amountIn.mul(tenThousand.sub(fee));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

}