/**
 *Submitted for verification at FtmScan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface ILp {
    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function burn(address) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IMultiRewards {
    function rewardTokensLength() external view returns (uint256);
}

interface IOxLens {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address oxPoolAddress;
        address solidPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    function oxPoolBySolidPool(address) external view returns (address);

    function stakingPoolsPositions(
        address
    ) external view returns (PositionStakingPool[] memory);

    function stakingPoolPosition(
        address,
        address
    ) external view returns (PositionStakingPool memory);

    function stakingRewardsBySolidPool(address) external view returns (address);
}

/**
 * @title 0xDao Sunset Claimer
 * @notice Allow legacy 0xDAO users to claim their LP share positions in one place
 *
 * Sunset rules:
 *   - No new LP token deposits allowed (oxPool tokens can be transferred and withdrawn but not minted)
 *   - No new veNFT deposits allowed (oxSOLID can be transferred, but not minted)
 *   - Staking pools must be frozen before migration (no new deposits or withdrawals)
 *   - oxPool tokens must be forefeitted to claim
 *
 * Claimable positions
 *   - User proxy oxPool stakes
 *   - Direct oxPool stakes
 *   - Unstaked oxPool tokens
 */
contract OxDaoSunsetClaimer {
    mapping(address => uint256) public amountStoredByLp;
    mapping(address => mapping(address => uint256)) tokenAmountStoredByLp;
    address voterProxyAssets = 0xDA00eA1c3813658325243e7ABb1f1Cac628Eb582;
    IOxLens oxLens = IOxLens(0xDA00137c79B30bfE06d04733349d98Cf06320e69);
    address public constant deadAddress =
        0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Transfer LP from voterProxy assets to sunet claimer, store the amount and break up the LP
     * @notice Requires approval from voterProxyAssets as well as frozen staking pool
     */
    function migrateLp(address solidPoolAddress) external {
        // One time migration, protocol is sunset
        require(amountStoredByLp[solidPoolAddress] == 0, "Already  migrated");

        // Staking pool must be frozen to prevent double claims
        require(
            stakingPoolFrozenForLp(solidPoolAddress),
            "Staking pool must be frozen to migrate"
        );

        // Migrate LP
        ILp lp = ILp(solidPoolAddress);
        uint256 amount = lp.balanceOf(voterProxyAssets);

        lp.transferFrom(voterProxyAssets, address(lp), amount);
        amountStoredByLp[solidPoolAddress] = amount;

        // Save before balances
        IERC20 token0 = IERC20(lp.token0());
        IERC20 token1 = IERC20(lp.token1());
        uint256 token0BalanceBefore = token0.balanceOf(address(this));
        uint256 token1BalanceBefore = token1.balanceOf(address(this));

        // Withdraw LP
        lp.burn(address(this));

        // Save after balanes and delta
        uint256 token0BalanceAfter = token0.balanceOf(address(this));
        uint256 token1BalanceAfter = token1.balanceOf(address(this));
        uint256 token0BalanceDelta = token0BalanceAfter - token0BalanceBefore;
        uint256 token1BalanceDelta = token1BalanceAfter - token1BalanceBefore;
        tokenAmountStoredByLp[solidPoolAddress][
            address(token0)
        ] = token0BalanceDelta;
        tokenAmountStoredByLp[solidPoolAddress][
            address(token1)
        ] = token1BalanceDelta;
    }

    /**
     * @notice If the user has a user proxy (majority of users) they can claim all with one click
     * @notice Most users should use this method
     */
    function claimByUserProxyStakes() external {
        // Find all stakes
        IOxLens.PositionStakingPool[] memory positions = oxLens
            .stakingPoolsPositions(msg.sender);
        for (
            uint256 positionIdx;
            positionIdx < positions.length;
            positionIdx++
        ) {
            IOxLens.PositionStakingPool memory position = positions[
                positionIdx
            ];
            _redeem(position.balanceOf, position.solidPoolAddress);
        }
    }

    /**
     * @notice Allow claiming of individual user proxy staked pools
     * @notice Prevent out of gas in the event user has many staking pools
     */
    function claimByUserProxyStake(address solidPoolAddress) external {
        address stakingPoolAddress = oxLens.stakingRewardsBySolidPool(
            solidPoolAddress
        );
        IOxLens.PositionStakingPool memory position = oxLens
            .stakingPoolPosition(msg.sender, stakingPoolAddress);
        _redeem(position.balanceOf, position.solidPoolAddress);
    }

    /**
     * @notice Direct stakes can claim one pool at a time
     */
    function claimByDirectStake(address solidPoolAddress) external {
        address stakingPoolAddress = oxLens.stakingRewardsBySolidPool(
            solidPoolAddress
        );
        uint256 amount = IERC20(stakingPoolAddress).balanceOf(msg.sender);
        _redeem(amount, solidPoolAddress);
    }

    /**
     * @notice Unstaked oxPool tokens can be burned for stored LP share
     */
    function claimByOxPoolBurn(address solidPoolAddress) external {
        IERC20 oxPool = IERC20(oxLens.oxPoolBySolidPool(solidPoolAddress));
        uint256 amount = oxPool.balanceOf(msg.sender);
        oxPool.transferFrom(msg.sender, address(this), amount);
        oxPool.transfer(deadAddress, amount);
        _redeem(amount, solidPoolAddress);
    }

    /**
     * @notice Process redemptions
     */
    function _redeem(uint256 amountOwed, address solidPoolAddress) internal {
        // Determine amount owed and stored
        uint256 amountStored = amountStoredByLp[solidPoolAddress];

        // Redeem shares
        if (amountOwed > 0 && amountStored > 0) {
            uint256 userShareRatio = (amountOwed * 1e18) / amountStored;
            ILp lp = ILp(solidPoolAddress);
            IERC20 token0 = IERC20(lp.token0());
            IERC20 token1 = IERC20(lp.token1());

            uint256 token0Amount = (tokenAmountStoredByLp[solidPoolAddress][
                address(token0)
            ] * userShareRatio) / 10 ** 18;
            uint256 token1Amount = (tokenAmountStoredByLp[solidPoolAddress][
                address(token1)
            ] * userShareRatio) / 10 ** 18;

            token0.transfer(msg.sender, token0Amount);
            token1.transfer(msg.sender, token1Amount);
        }
    }

    /**
     * @notice Check to see if a multirewards pool is frozen
     * @dev Each staking token added adds 41,527 gas to the withdraw method
     * @dev Initial exit cost without any rewards is 10,113
     * @dev To achieve out of gas on fantom we need exit to exceed 8m gas (10m from within a node)
     * @dev 10,000,000 / 41,527 = 241, so, we choose a reward pool with token length of 250 to enforce OOG on exit
     * @dev This prevents preventing double claims on oxPools without requiring the user to unstake
     * @dev Staked LP tokens (both user proxy stakes and direct stakes) can only be redeemed from this contract
     */
    function stakingPoolFrozenForLp(
        address solidPoolAddress
    ) internal view returns (bool) {
        uint256 threshold = 250;
        address stakingPoolAddress = oxLens.stakingRewardsBySolidPool(
            solidPoolAddress
        );
        require(
            IMultiRewards(stakingPoolAddress).rewardTokensLength() >= threshold,
            "Staking rewards not frozen"
        );
        return true;
    }
}