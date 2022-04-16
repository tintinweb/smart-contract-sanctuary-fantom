// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/ISFC.sol";

library SFCPenalty {
    uint256 public constant DECIMAL_UNIT = 1e18;
    uint256 public constant UNLOCKED_REWARD_RATIO = (30 * DECIMAL_UNIT) / 100;
    uint256 public constant MAX_LOCKUP_DURATION = 86400 * 365;

    struct Rewards {
        uint256 lockupExtraReward;
        uint256 lockupBaseReward;
        uint256 unlockedReward;
    }

    function getUnlockPenalty(
        ISFC SFC,
        address payable vault,
        uint256 toValidatorID,
        uint256 unlockAmount,
        uint256 totalAmount
    ) public view returns (uint256) {
        (uint256 lockupExtraReward, uint256 lockupBaseReward, ) = SFC
            .getStashedLockupRewards(vault, toValidatorID);

        (
            uint256 newLockupExtraReward,
            uint256 newLockupBaseReward,

        ) = _newRewards(SFC, vault, toValidatorID);

        uint256 lockupExtraRewardShare = ((lockupExtraReward +
            newLockupExtraReward) * unlockAmount) / totalAmount;
        uint256 lockupBaseRewardShare = ((lockupBaseReward +
            newLockupBaseReward) * unlockAmount) / totalAmount;
        uint256 penalty = lockupExtraRewardShare + lockupBaseRewardShare / 2;

        if (penalty > unlockAmount) {
            penalty = unlockAmount;
        }

        return penalty;
    }

    function _highestPayableEpoch(ISFC SFC, uint256 validatorID)
        internal
        view
        returns (uint256)
    {
        (, , uint256 deactivatedEpoch, , , , ) = SFC.getValidator(validatorID);

        uint256 currentSealedEpoch = SFC.currentSealedEpoch();

        if (deactivatedEpoch != 0) {
            if (currentSealedEpoch < deactivatedEpoch) {
                return currentSealedEpoch;
            }
            return deactivatedEpoch;
        }
        return currentSealedEpoch;
    }

    function _epochEndTime(ISFC SFC, uint256 epoch)
        internal
        view
        returns (uint256)
    {
        (uint256 endTime, , , , , , ) = SFC.getEpochSnapshot(epoch);

        return endTime;
    }

    function _isLockedUpAtEpoch(
        ISFC SFC,
        address delegator,
        uint256 toValidatorID,
        uint256 epoch
    ) internal view returns (bool) {
        (, uint256 fromEpoch, uint256 endTime, ) = SFC.getLockupInfo(
            delegator,
            toValidatorID
        );

        return fromEpoch <= epoch && _epochEndTime(SFC, epoch) <= endTime;
    }

    function _highestLockupEpoch(
        ISFC SFC,
        address delegator,
        uint256 validatorID
    ) internal view returns (uint256) {
        (, uint256 fromEpoch, , ) = SFC.getLockupInfo(delegator, validatorID);

        uint256 l = fromEpoch;
        uint256 r = SFC.currentSealedEpoch();
        if (_isLockedUpAtEpoch(SFC, delegator, validatorID, r)) {
            return r;
        }
        if (!_isLockedUpAtEpoch(SFC, delegator, validatorID, l)) {
            return 0;
        }
        if (l > r) {
            return 0;
        }
        while (l < r) {
            uint256 m = (l + r) / 2;
            if (_isLockedUpAtEpoch(SFC, delegator, validatorID, m)) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        if (r == 0) {
            return 0;
        }
        return r - 1;
    }

    function _newRewardsOf(
        ISFC SFC,
        uint256 stakeAmount,
        uint256 toValidatorID,
        uint256 fromEpoch,
        uint256 toEpoch
    ) internal view returns (uint256) {
        if (fromEpoch >= toEpoch) {
            return 0;
        }

        uint256 stashedRate = SFC.getEpochAccumulatedRewardPerToken(
            fromEpoch,
            toValidatorID
        );
        uint256 currentRate = SFC.getEpochAccumulatedRewardPerToken(
            toEpoch,
            toValidatorID
        );
        return ((currentRate - stashedRate) * stakeAmount) / DECIMAL_UNIT;
    }

    function _scaleLockupReward(uint256 fullReward, uint256 lockupDuration)
        internal
        pure
        returns (Rewards memory reward)
    {
        reward = Rewards(0, 0, 0);
        if (lockupDuration != 0) {
            uint256 maxLockupExtraRatio = DECIMAL_UNIT - UNLOCKED_REWARD_RATIO;
            uint256 lockupExtraRatio = (maxLockupExtraRatio * lockupDuration) /
                MAX_LOCKUP_DURATION;
            uint256 totalScaledReward = (fullReward *
                (UNLOCKED_REWARD_RATIO + lockupExtraRatio)) / DECIMAL_UNIT;
            reward.lockupBaseReward =
                (fullReward * UNLOCKED_REWARD_RATIO) /
                DECIMAL_UNIT;
            reward.lockupExtraReward =
                totalScaledReward -
                reward.lockupBaseReward;
        } else {
            reward.unlockedReward =
                (fullReward * UNLOCKED_REWARD_RATIO) /
                DECIMAL_UNIT;
        }
        return reward;
    }

    function _newRewards(
        ISFC SFC,
        address delegator,
        uint256 toValidatorID
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 stashedUntil = SFC.stashedRewardsUntilEpoch(
            delegator,
            toValidatorID
        );
        uint256 payableUntil = _highestPayableEpoch(SFC, toValidatorID);
        uint256 lockedUntil = _highestLockupEpoch(
            SFC,
            delegator,
            toValidatorID
        );
        if (lockedUntil > payableUntil) {
            lockedUntil = payableUntil;
        }
        if (lockedUntil < stashedUntil) {
            lockedUntil = stashedUntil;
        }

        (uint256 lockedStake, , , uint256 duration) = SFC.getLockupInfo(
            delegator,
            toValidatorID
        );

        uint256 wholeStake = SFC.getStake(delegator, toValidatorID);

        Rewards memory result = _genResult(
            SFC,
            toValidatorID,
            wholeStake,
            lockedStake,
            stashedUntil,
            lockedUntil,
            payableUntil,
            duration
        );

        return (
            result.lockupExtraReward,
            result.lockupBaseReward,
            result.unlockedReward
        );
    }

    function _genResult(
        ISFC SFC,
        uint256 toValidatorID,
        uint256 wholeStake,
        uint256 lockedStake,
        uint256 stashedUntil,
        uint256 lockedUntil,
        uint256 payableUntil,
        uint256 duration
    ) internal view returns (Rewards memory) {
        uint256 unlockedStake = wholeStake - lockedStake;
        uint256 fullReward;
        // count reward for locked stake during lockup epochs
        fullReward = _newRewardsOf(
            SFC,
            lockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory plReward = _scaleLockupReward(fullReward, duration);
        // count reward for unlocked stake during lockup epochs
        fullReward = _newRewardsOf(
            SFC,
            unlockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory puReward = _scaleLockupReward(fullReward, 0);
        // count lockup reward for unlocked stake during unlocked epochs
        fullReward = _newRewardsOf(
            SFC,
            wholeStake,
            toValidatorID,
            lockedUntil,
            payableUntil
        );
        Rewards memory wuReward = _scaleLockupReward(fullReward, 0);

        return _sumRewards(plReward, puReward, wuReward);
    }

    function _sumRewards(Rewards memory a, Rewards memory b)
        internal
        pure
        returns (Rewards memory)
    {
        return
            Rewards(
                a.lockupExtraReward + b.lockupExtraReward,
                a.lockupBaseReward + b.lockupBaseReward,
                a.unlockedReward + b.unlockedReward
            );
    }

    function _sumRewards(
        Rewards memory a,
        Rewards memory b,
        Rewards memory c
    ) internal pure returns (Rewards memory) {
        return _sumRewards(_sumRewards(a, b), c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISFC {
    function currentEpoch() external view returns (uint256);

    function currentSealedEpoch() external view returns (uint256);

    function getValidator(uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    function getEpochSnapshot(uint256 epoch)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getLockupInfo(address delegator, uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getWithdrawalRequest(
        address delegator,
        uint256 toValidatorID,
        uint256 wrID
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getStake(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function getStashedLockupRewards(address delegator, uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getLockedStake(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function pendingRewards(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function isSlashed(uint256 toValidatorID) external view returns (bool);

    function slashingRefundRatio(uint256 toValidatorID)
        external
        view
        returns (uint256);

    function getEpochAccumulatedRewardPerToken(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function stashedRewardsUntilEpoch(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function isLockedUp(address delegator, uint256 toValidatorID)
        external
        view
        returns (bool);

    function delegate(uint256 toValidatorID) external payable;

    function lockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function relockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function restakeRewards(uint256 toValidatorID) external;

    function claimRewards(uint256 toValidatorID) external;

    function undelegate(
        uint256 toValidatorID,
        uint256 wrID,
        uint256 amount
    ) external;

    function unlockStake(uint256 toValidatorID, uint256 amount)
        external
        returns (uint256);

    function withdraw(uint256 toValidatorID, uint256 wrID) external;
}