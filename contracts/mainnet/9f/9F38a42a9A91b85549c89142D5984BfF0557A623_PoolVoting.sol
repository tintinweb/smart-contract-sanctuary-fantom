/**
 *Submitted for verification at FtmScan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDepositor {
    function receiveLP(address from, address _pool, uint256 amount, uint256 currentBalance) external;
    function withdrawLP(address from, address _pool, uint256 amount, uint256 currentBalance) external;

    function claimSolidRewards(address _user, address[] calldata _pools, uint256[] calldata _currentBalances) external;
    function vote(address[] memory pools, int256[] memory weights) external;

    function whitelist(address _token, int256 _votes) external;

    function extendLockTime() external;
}

pragma solidity 0.8.15;

interface IRadialVoting {
    function balanceOfLP(address user) external returns(uint256);
    function receiveLP(address from, uint256 amount) external;
    function withdrawLP(address _from, uint256 _amount) external;
    function receiveRDL(address user, uint256 amount) external;
    function withdrawRDL(address user, uint256 amount) external;
    function getVotingPower(address user) external returns(uint256);
}

pragma solidity ^0.8.15;

interface ISolidlyVoter {
    function gauges(address pool) external returns(address);
}

contract PoolVoting {
    struct PoolData {
        uint64 index; // index in pool list
        uint64 week;
        uint128 topVotesIndex;
    }

    uint256 constant MAX_POOLS_TO_VOTE = 50;
    uint256 constant WEEK = 60*60*24*7;
    uint256 immutable START_TIME;
    IRadialVoting immutable RADIAL_VOTING;
    IDepositor immutable DEPOSITOR;
    ISolidlyVoter immutable SOLIDLY_VOTER;
    address immutable FIXED_VOTE_POOL;

    // user -> pool -> week -> votes
    mapping(address => mapping(address => mapping(uint256 => int256))) public userVotes;
    // user -> week -> votes
    mapping(address => mapping(uint256 => uint256)) userWeeklyVotes;
    // week -> votes
    mapping(uint256 => uint256) totalWeeklyVotes;

    // pool -> week -> votes
    mapping(address => mapping(uint256 => int256)) public poolVotes;
    // pool -> week -> votes
    mapping(address => mapping(uint256 => int256)) public poolRewardWeight;
    // pool -> index in poolList
    mapping(address => PoolData) public poolData;
    // week -> topVotes id 24, votes 40
    mapping(uint256 => uint64[MAX_POOLS_TO_VOTE]) public topVotes;
    address[] public poolList;
    uint256 presentWeek;
    uint256 public topVotesSize;
    uint256 public minTopVotes;
    uint256 minTopVoteIndex;

    event Voted(address indexed user, uint256 indexed week, address[] pools, int256[] votes);
    event VoteOnSolidlyGauges(address[] _pools, int256[] _weights, uint256 _currentWeek);

    constructor(uint256 _startTime, address _radialVoting, address _depositor, address _solidlyVoter, address _fixedVotePool) {
        START_TIME = _startTime;
        RADIAL_VOTING = IRadialVoting(_radialVoting);
        DEPOSITOR = IDepositor(_depositor);
        SOLIDLY_VOTER = ISolidlyVoter(_solidlyVoter);
        FIXED_VOTE_POOL = _fixedVotePool;
        poolList.push(address(0));
    }

    function getUserVoteData(address _user, address _pool, uint256 _week) public view returns(int256, int256) {
        return (userVotes[_user][_pool][_week], poolRewardWeight[_pool][_week]);
    }

    function getWeeklyVoteData(address _user, uint256 _week) public view returns(uint256, uint256) {
        return (userWeeklyVotes[_user][_week], totalWeeklyVotes[_week]);
    }

    function vote(address[] memory _pools, int256[] memory _votes) public {
        require(_pools.length == _votes.length, "Invalid inputs");
        require(_pools.length != 0, "No pool to vote");

        uint256 _minTopVotes = minTopVotes;
        uint256 _topVotesSize = topVotesSize;
        uint256 _minTopVoteIndex = minTopVoteIndex;
        uint256 _currentWeek = getWeek();
        uint64[MAX_POOLS_TO_VOTE] memory _topVotes = topVotes[_currentWeek];

        // If presentWeek is not updated, update it and reset topVote vars
        if(_currentWeek > presentWeek) {
            _minTopVotes = 0;
            _topVotesSize = 0;
            presentWeek = _currentWeek;
        }

        uint256 _votingPower = RADIAL_VOTING.getVotingPower(msg.sender);
        uint256 _votesThisWeek = userWeeklyVotes[msg.sender][_currentWeek];

        // iterate votes and update the top votes accordingly
        for(uint256 i = 0; i < _pools.length; i++) {
            require(_votes[i] != 0, "No vote");

            address _pool = _pools[i];
            int256 _vote = _votes[i];
            {
                uint256 _absVotes = abs(_vote);

                require(_votingPower >= _absVotes + _votesThisWeek, "votes more than voting power");
                totalWeeklyVotes[_currentWeek] += _absVotes;
                _votesThisWeek += _absVotes;
            }

            int256 _poolVotesThisWeek = poolVotes[_pool][_currentWeek];
            uint256 _poolIndex = poolData[_pool].index;

            if(_poolVotesThisWeek == 0 || poolData[_pool].week < _currentWeek) {
                require(SOLIDLY_VOTER.gauges(_pool) != address(0), "Pool doesnt have gauge");
                if(_poolIndex == 0) {
                    _poolIndex = poolList.length;
                    poolList.push(_pool);
                }
                poolData[_pool] = PoolData(uint64(_poolIndex), uint64(_currentWeek), 0);
            }

            _poolVotesThisWeek += _vote;
            uint256 _absPoolVotesThisWeek = abs(_poolVotesThisWeek);
            assert(_absPoolVotesThisWeek < 2**39); // max positive value for int40 is 2**39
            poolVotes[_pool][_currentWeek] = _poolVotesThisWeek;

            // update user votes and net reward weights
            _updateUserVotes(_pool, _vote, _currentWeek);

            if(poolData[_pool].topVotesIndex != 0) {
                // pool is among ones with top votes
                uint256 _topVotesIndex = poolData[_pool].topVotesIndex - 1;

                if(_poolVotesThisWeek == 0) {
                    // remove pool from top votes as weight is 0
                    poolData[_pool] = PoolData(uint64(_poolIndex), 0, 0);
                    _topVotesSize--;

                    if(_topVotesIndex == _topVotesSize) {
                        delete _topVotes[_topVotesIndex];
                    } else {
                        _topVotes[_topVotesIndex] = _topVotes[_topVotesSize];
                        uint256 _poolTopVoteIndex = _topVotes[_topVotesIndex] >> 40; // remove size of the value
                        poolData[poolList[_poolTopVoteIndex]].topVotesIndex = uint128(_topVotesIndex + 1);
                        delete _topVotes[_topVotesSize];
                        if(_minTopVoteIndex > _topVotesSize) {
                            _minTopVoteIndex = _topVotesIndex + 1;
                            continue;
                        }
                    }
                } else {
                    _topVotes[_topVotesIndex] = _pack(_poolIndex, _poolVotesThisWeek);
                    if(_absPoolVotesThisWeek < _minTopVotes) {
                        _minTopVotes = _absPoolVotesThisWeek;
                        _minTopVoteIndex = _topVotesIndex + 1;
                        continue;
                    }
                }
                // if deleted entry was min, then find new min
                if(_topVotesIndex == _minTopVoteIndex - 1) {
                    (_minTopVotes, _minTopVoteIndex) = _findMinTopVote(_topVotes, _topVotesSize);
                }
            } else if(_topVotesSize < MAX_POOLS_TO_VOTE) {
                _topVotes[_topVotesSize] = _pack(_poolIndex, _poolVotesThisWeek);
                _topVotesSize++;
                poolData[_pool].topVotesIndex = uint128(_topVotesSize);
                if(_absPoolVotesThisWeek < minTopVotes || minTopVotes == 0) {
                    _minTopVotes = _absPoolVotesThisWeek;
                    _minTopVoteIndex = uint128(_topVotesSize);
                }
            } else if(_absPoolVotesThisWeek > _minTopVotes) {
                uint256 _minPoolIndex = _topVotes[_minTopVoteIndex] >> 40; // remove size of the value

                poolData[poolList[_poolIndex]] = PoolData(uint64(_minPoolIndex), 0, uint128(_minTopVoteIndex));
                _topVotes[_minTopVoteIndex - 1] = _pack(_minPoolIndex, _poolVotesThisWeek);

                (_minTopVotes, _minTopVoteIndex) = _findMinTopVote(_topVotes, MAX_POOLS_TO_VOTE);
            }
        }

        userWeeklyVotes[msg.sender][_currentWeek] = _votesThisWeek;
        topVotes[_currentWeek] = _topVotes;
        topVotesSize = _topVotesSize;
        minTopVotes = _minTopVotes;
        minTopVoteIndex = _minTopVoteIndex;

        emit Voted(msg.sender, _currentWeek, _pools, _votes);
    }

    function _updateUserVotes(address _pool, int256 _vote, uint256 _currentWeek) internal {
        int256 _prevUserVotes = userVotes[msg.sender][_pool][_currentWeek];
        int256 _newUserVotes = _prevUserVotes + _vote;
        userVotes[msg.sender][_pool][_currentWeek] = _newUserVotes;
        int256 _poolRewardWeight = poolRewardWeight[_pool][_currentWeek];
        if(_prevUserVotes < 0 && _newUserVotes > 0) {
            _poolRewardWeight += _newUserVotes;
        } else if(_prevUserVotes > 0 && _newUserVotes < 0) {
            _poolRewardWeight -= _prevUserVotes;
        } else if(_prevUserVotes >= 0 && _newUserVotes >= 0) {
            _poolRewardWeight += _vote;
        }
        poolRewardWeight[_pool][_currentWeek] = _poolRewardWeight;
    }

    function submitVotes() external {
        (address[] memory _pools, int256[] memory _weights) = _currentWeekVotes();
        DEPOSITOR.vote(_pools,_weights);
        emit VoteOnSolidlyGauges(_pools, _weights, getWeek());
    }

    function _currentWeekVotes() public view returns(address[] memory _pools, int256[] memory _weights){
        uint256 _currentWeek = getWeek();
        uint256 _votingSize = 1;
        if (_currentWeek == presentWeek) {
            _votingSize += topVotesSize;
        }

        uint256[MAX_POOLS_TO_VOTE] memory _voteWeights;
        _pools = new address[](_votingSize);
        _weights = new int256[](_votingSize);

        for(uint256 i; i < _votingSize - 1; i++)  {
            (uint256 _poolIndex, int256 _poolWeight) = _unpack(topVotes[_currentWeek][i]);
            _pools[i] = poolList[_poolIndex];
            _weights[i] = _poolWeight;
            _voteWeights[i] = abs(_poolWeight);
        }

        uint256 _totalWeight;
        uint256 _fixedVoteId;
        address _fixedVotePool = FIXED_VOTE_POOL;
        for (uint256 i = 0; i < _votingSize; i++) {
            _totalWeight += _voteWeights[i];
            if (_pools[i] == _fixedVotePool) _fixedVoteId = i + 1;
        }

        int256 _fixedWeight = int256(_totalWeight/9);
        if(_fixedWeight == 0) _fixedWeight = 1;

        if(_fixedVoteId == 0) {
            _pools[_votingSize - 1] = _fixedVotePool;
            _weights[_votingSize - 1] = _fixedWeight;
        } else {
            _weights[_fixedVoteId - 1] += _fixedWeight;
            _votingSize--;
            assembly {
                mstore(_pools, _votingSize)
                mstore(_weights, _votingSize)
            }
        }

        return (_pools, _weights);
    }

    function _findMinTopVote(uint64[MAX_POOLS_TO_VOTE] memory _topVotes, uint256 _size) internal pure returns(uint256, uint256) {
        uint256 _minTopVote = type(uint256).max;
        uint256 _minTopVoteIndex;

        for(uint256 i; i < _size; i++) {
            uint256 _value = _topVotes[i] % (2**39);
            if(_value < _minTopVote) {
                _minTopVote = _value;
                _minTopVoteIndex = i+1;
            }
        }
        return (_minTopVote, _minTopVoteIndex);
    }

    function _pack(uint256 index, int256 votes) internal pure returns(uint64) {
        uint64 _value = uint64((index << 40) + abs(votes));
        if(votes < 0) _value += 2**39;
        return _value;
    }

    function _unpack(uint256 value) internal pure returns(uint256, int256) {
        uint256 _index = (value >> 40);
        int256 _votes = int256(value %2**40);
        if (_votes > 2**39) _votes = -(_votes % 2**39);
        return (_index, _votes);
    }

    // ////Imported from OZ SignedMath https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/math/SignedMath.sol#L37
    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - START_TIME) / WEEK;
    }
}