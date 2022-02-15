/**
 *Submitted for verification at FtmScan.com on 2022-02-15
*/

pragma solidity 0.8.11;

interface IERC20 {
    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface IFactory {
    function getPair(
        address,
        address,
        bool
    ) external;
}

interface IRouter {
    function addLiquidity(
        address,
        address,
        bool,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external;
}

contract Payload {
    address public routerAddress = 0xa38cd27185a464914D3046f0AB9d43356B34829D;

    function depositTokens(
        address token0Address,
        address token1Address,
        uint256 amount0,
        uint256 amount1,
        bool stable
    ) external {
        IERC20(token0Address).approve(routerAddress, amount0);
        IERC20(token1Address).approve(routerAddress, amount1);
        IRouter(routerAddress).addLiquidity(
            token0Address,
            token1Address,
            stable,
            amount0,
            amount1,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }
}