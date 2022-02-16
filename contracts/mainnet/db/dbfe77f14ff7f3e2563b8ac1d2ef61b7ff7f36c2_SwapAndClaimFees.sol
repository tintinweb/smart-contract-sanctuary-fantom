/**
 *Submitted for verification at FtmScan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
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

    function swapExactTokensForTokensSimple(
        uint256,
        uint256,
        address,
        address,
        bool,
        address,
        uint256
    ) external;

    function pairFor(
        address,
        address,
        bool
    ) external view returns (address);

    struct route {
        address from;
        address to;
        bool stable;
    }

    function getAmountsOut(uint256, route[] memory)
        external
        view
        returns (uint256[] memory);

    function removeLiquidity(
        address,
        address,
        bool,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external;
}

interface IPair {
    function claimFees() external;

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;
}

contract SwapAndClaimFees {
    function depositTokens(
        address routerAddress,
        address token0Address,
        address token1Address,
        uint256 amount0,
        uint256 amount1,
        bool stable
    ) external {
        // Allow router to spend tokens
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        token0.approve(routerAddress, amount0 * 2);
        token1.approve(routerAddress, amount1 * 2);

        // Add liquidity (this should be done via flashloan to maximize fee claim)
        IRouter router = IRouter(routerAddress);
        router.addLiquidity(
            token0Address,
            token1Address,
            stable,
            amount0,
            amount1,
            0,
            0,
            address(this),
            block.timestamp
        );
        IRouter.route[] memory routes = new IRouter.route[](1);
        routes[0] = IRouter.route({
            from: token0Address,
            to: token1Address,
            stable: stable
        });
        uint256[] memory expectedOutput = router.getAmountsOut(amount0, routes);

        // Swap
        {
            uint256 token1BalanceBefore = token1.balanceOf(address(this));
            router.swapExactTokensForTokensSimple(
                amount0,
                expectedOutput[1],
                token0Address,
                token1Address,
                stable,
                address(this),
                block.timestamp
            );
            uint256 token1BalanceAfter = token1.balanceOf(address(this));
            assert(token1BalanceAfter > token1BalanceBefore);
        }

        // Claim fees from swap
        address pairAddress = router.pairFor(
            token0Address,
            token1Address,
            stable
        );
        IPair pair = IPair(pairAddress);
        {
            uint256 token0BalanceBefore = token0.balanceOf(address(this));
            pair.claimFees();
            uint256 token0BalanceAfter = token0.balanceOf(address(this));
            assert(token0BalanceAfter > token0BalanceBefore);
        }

        // Remove liquidity
        uint256 liquidity = pair.balanceOf(address(this));
        pair.approve(routerAddress, liquidity);
        router.removeLiquidity(
            token0Address,
            token1Address,
            stable,
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}