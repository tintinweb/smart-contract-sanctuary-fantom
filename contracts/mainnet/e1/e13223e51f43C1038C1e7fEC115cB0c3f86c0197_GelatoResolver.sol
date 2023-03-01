/**
 *Submitted for verification at FtmScan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract GelatoResolver {
    
    function getPrice(address _pairAddress) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        
        // Normalize reserves
        uint256 normalizedReserve0 = uint256(reserve0) * 10 ** (18-6);
        
        // Calculate price
        uint256 price = (normalizedReserve0 * 10 ** 18) / reserve1;
        
        return price;
    }

    function sqrt(uint256 x) public pure returns (uint256) {
            if (x == 0) {
                return 0;
            }
            uint256 y = x;
            uint256 z = (y + 1) / 2;
            while (z < y) {
                y = z;
                z = (x / z + z) / 2;
            }
            return y;
        }

    function checker(address _pairAddressPrivate, address _pairAddressPublic) external view returns (bool canExec, bytes memory execCode)
    {
        // Calculate Public Price
        IUniswapV2Pair pairPublic = IUniswapV2Pair(_pairAddressPublic);
        (uint112 publicReserve0, uint112 publicReserve1, ) = pairPublic.getReserves();
        uint256 normPublicReserve0 = uint256(publicReserve0) * 10 ** (18-6);
        uint256 pricePublic = (normPublicReserve0 * 10 ** 18) / publicReserve1;
        
        // Calculate Private Price
        IUniswapV2Pair pairPrivate = IUniswapV2Pair(_pairAddressPrivate);
        (uint112 privateReserve0, uint112 privateReserve1, ) = pairPrivate.getReserves();
        uint256 normPrivateReserve0 = uint256(privateReserve0) * 10 ** (18-6);
        uint256 kPrivate = normPrivateReserve0 * privateReserve1;

        // Compare Price and encode input to ArbV3.dualDexTradeV2, (_index, _amount)
        canExec = (publicReserve0 > 0 && publicReserve1 > 0 && privateReserve0 > 0 && privateReserve1 > 0);
        //execCode = abi.encodeCall(ArbV3.dualDexTradeV2, (0, GelatoResolver.sqrt(kPrivate * pricePublic)));
        execCode = abi.encode(0, GelatoResolver.sqrt(kPrivate * pricePublic * 10 ** 18) / 10 ** 30);

        if(tx.gasprice > 3000 gwei) return (false, bytes("Gas price too high"));
        else return(canExec,execCode);
    }

}