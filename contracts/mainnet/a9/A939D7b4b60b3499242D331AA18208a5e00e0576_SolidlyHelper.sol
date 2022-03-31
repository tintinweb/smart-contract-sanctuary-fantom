/**
 *Submitted for verification at FtmScan.com on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVoter {
    function length() external view returns (uint256);
    function pools(uint256 index) external view returns (address);
    function gauges(address pool) external view returns (address);
    function bribes(address gauge) external view returns (address);
    function weights(address pool) external view returns (uint256);
}

interface IBribe {
    function DURATION() external view returns (uint256);
    function rewardsListLength() external view returns (uint256);
    function rewards(uint256 index) external view returns (address);
    function rewardRate(address token) external view returns (uint256);
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IPool is IERC20 {
    function stable() external view returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256,uint256,uint256);
}

contract SolidlyHelper {
    struct Token {
        address token;
        string symbol;
        string name;
        uint8 decimals;
        uint256 balance;
    }

    struct BribeReward {
        Token token;
        uint256 rewardRate;
    }

    struct Pool {
        address pool;
        address gauge;
        address bribe;
        bool stable;
        uint256 votes;
        Token token;
        Token token0;
        Token token1;
        uint256 duration;
        BribeReward[] bribes;
    }

    function length(address voter) public view returns (uint256) {
        return IVoter(voter).length();
    }

    function fetchPool(address _voter, address _pool) public view returns (Pool memory result) {
        return _fetchPool(IVoter(_voter), IPool(_pool));
    }

    function fetchPool(address _voter, uint256 index) public view returns 
        (Pool memory result) 
    {
        IVoter voter = IVoter(_voter);
        IPool pool = IPool(voter.pools(index));
        return _fetchPool(voter, pool);
    }

    function _fetchPool(IVoter voter, IPool pool) internal view returns (Pool memory result) {
        address gauge = voter.gauges(address(pool));
        IBribe bribe = IBribe(voter.bribes(gauge));

        uint256 rewardCount = bribe.rewardsListLength();

        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();

        result = Pool({
            pool: address(pool),
            gauge: gauge,
            bribe: address(bribe),
            stable: pool.stable(),
            votes: voter.weights(address(pool)),
            token: Token({
                token: address(pool),
                symbol: pool.symbol(),
                name: pool.name(),
                decimals: pool.decimals(),
                balance: 0
            }),
            token0: Token({
                token: pool.token0(),
                symbol: IERC20(pool.token0()).symbol(),
                name: IERC20(pool.token0()).name(),
                decimals: IERC20(pool.token0()).decimals(),
                balance: reserve0
            }),
            token1: Token({
                token: pool.token1(),
                symbol: IERC20(pool.token1()).symbol(),
                name: IERC20(pool.token1()).name(),
                decimals: IERC20(pool.token1()).decimals(),
                balance: reserve1
            }),
            duration: bribe.DURATION(),
            bribes: new BribeReward[](rewardCount)
        });

        for (uint256 i = 0; i < rewardCount; i++) {
            IERC20 token = IERC20(bribe.rewards(i));

            result.bribes[i] = BribeReward({
                token: Token({
                    token: address(token),
                    symbol: token.symbol(),
                    name: token.name(),
                    decimals: token.decimals(),
                    balance: 0
                }),
                rewardRate: bribe.rewardRate(address(token))
            });
        }
    }
}