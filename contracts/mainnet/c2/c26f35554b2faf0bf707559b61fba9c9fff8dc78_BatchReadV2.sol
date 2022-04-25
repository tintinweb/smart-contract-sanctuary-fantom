/**
 *Submitted for verification at FtmScan.com on 2022-04-25
*/

/**
 *Submitted for verification at FtmScan.com on 2021-12-27
 */

/**
 *Submitted for verification at FtmScan.com on 2021-12-27
 */

/**
 *Submitted for verification at FtmScan.com on 2021-12-20
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import all dependencies and interfaces:

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IB {
    /* @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' balances changed.
     *
     * The order of the tokens array is the same order that will be used in joinPool, exitPool, as well as in all
     * Pool hooks (where applicable). Calls to registerTokens and deregisterTokens may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to registerTokens.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use getPoolTokenInfo
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

interface IUniswapV2Factory {
    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

interface IMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TCSs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTCSPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTCSPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IUniswapV2Pair lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. TCSs to distribute per block.
        uint256 lastRewardTime; // Last block time that TCSs distribution occurs.
        uint256 accTCSPerShare; // Accumulated TCSs per share, times 1e12. See below.
    }

    function totalAllocPoint() external view returns (uint256);

    function startTime() external view returns (uint256);

    function tcsPerSecond() external view returns (uint256);

    function poolLength() external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    // View function to see pending TCSs on frontend.
    function pendingTCS(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolInfo(uint256) external view returns (PoolInfo memory);

    function userInfo(uint256, address) external view returns (UserInfo memory);

    function tcs() external view returns (address);
}

interface IERC20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract BatchReadV2 {
    IUniswapV2Router public default_router;
    IUniswapV2Factory public default_factory;
    IB public beethoven_contract;
    uint8 MAINTAINER_FEE_MULTIPLIER = 0;
    address WFTM;
    address FTM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IMasterChef public default_masterchef;

    address public Owner;

    constructor(address _WFTM) {
        default_router = IUniswapV2Router(
            0xc784BFac74F0319b662D02Ad2E68217601c8041F
        );
        default_factory = IUniswapV2Factory(default_router.factory());
        default_masterchef = IMasterChef(
            0x5512CDfbbcdE24f591C1A2cC8d463054c61D227d
        );
        WFTM = _WFTM;
        default_masterchef.tcsPerSecond();
        beethoven_contract = IB(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);
        MAINTAINER_FEE_MULTIPLIER = 2;
        Owner = msg.sender;
    }

    function change_defaults(
        address _default_router,
        address _default_masterchef,
        address _WFTM
    ) public {
        require(msg.sender == Owner, "Only Owner ....");
        default_router = IUniswapV2Router(_default_router);
        default_factory = IUniswapV2Factory(default_router.factory());
        default_masterchef = IMasterChef(_default_masterchef);
        WFTM = _WFTM;
        default_masterchef.tcsPerSecond();
    }

    function change_owner(address new_owner) public {
        require(msg.sender == Owner, "Only Owner ....");
        Owner = new_owner;
    }

    function multiGetReserves(address[] memory pairs)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 count = pairs.length;
        uint256[] memory reservesA = new uint256[](count);
        uint256[] memory reservesB = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            (reservesA[i], reservesB[i], ) = IUniswapV2Pair(pairs[i])
                .getReserves();
        }
        return (reservesA, reservesB);
    }

    uint256 MAX_INT_VALUE = 2**255;
    uint256 public DIV_PERCISION = 10**6;

    struct ShareOfPool {
        address pair_address; // Pair Address ( same as LP token address )
        address token0;
        uint256 share0; // Rough Number of tokens user have of token0
        address token1;
        uint256 share1; // Rough Number of tokens user have of token1
        uint256 share; // Divide by 10 ^ 18 and yu will have users share of pool
        uint256 balance; // balance of LPs user have on this pair
        uint256 totalSupply; // Total LP s made for this perticular pair
        // uint256 tcsPerDay; // Amount of Tcss will be rewarded in 24hours for the pool farmers.
        // uint256 p_id; // FarmId
    }

    struct BeethovenPoolReserves {
        bytes32 poolid;
        uint256[] reserves;
        IERC20[] tokens;
        uint256 lastChangeBlock;
    }

    struct PairObj {
        address pair_address;
        address token0;
        address token1;
    }

    struct walletInfo {
        address token;
        uint256 balance;
        uint256 allowance;
    }

    struct LP_balance {
        address LP_token;
        uint256 balance;
    }
    struct FarmInfo {
        uint256 poolid;
        ShareOfPool lpSharenfo;
        uint256 totalLockedSupply; // Balance of lp locked in this farm
        uint256 totalSupply; // total lp this pair has
        uint256 allocPoint; // How many allocation points assigned to this pool. TCSs to distribute per block.
        uint256 tcsPerDay;
        uint256 lastRewardTime; // Last block time that TCSs distribution occurs.
    }

    // Considering the fact that for Each there is only one pool in the masterchef
    struct WalletDetail {
        uint256 poolid;
        IUniswapV2Pair lpToken; // Address of LP token contract.
        string name;
        IERC20 token0;
        IERC20 token1;
        uint256 totalSupply; // total lp this pair has
        uint256 totalLockedSupply; // Balance of lp locked in this farm
        uint256 allocPoint; // How many allocation points assigned to this pool. TCSs to distribute per block.
        uint256 lastRewardTime; // Last block time that TCSs distribution occurs.
        // Wallet related Information
        uint256 accTCSPerShare;
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 balanceLptoken; // Wallet balance of this lp token
        uint256 reward; // amount harvset user can do
    }

    function multiGetInfo(
        address[] memory tokens,
        address spender,
        address wallet_address
    ) public view returns (walletInfo[] memory) {
        uint256 count = tokens.length;
        walletInfo[] memory result = new walletInfo[](count + 1);
        for (uint16 i = 0; i < count; i++) {
            walletInfo memory res = walletInfo(
                tokens[i],
                IERC20(tokens[i]).balanceOf(wallet_address),
                IERC20(tokens[i]).allowance(wallet_address, spender)
            );
            result[i] = res;
        }
        result[count] = walletInfo(FTM, wallet_address.balance, 2**254);

        return result;
    }

    function getAllFactoryPairsSkipLimit(
        IUniswapV2Factory factory,
        uint256 skip,
        uint256 limit
    ) public view returns (PairObj[] memory) {
        uint256 count = factory.allPairsLength();
        limit += skip;
        limit = count > limit ? limit : count;
        PairObj[] memory pairs = new PairObj[](limit - skip);
        uint256 j = 0;
        for (uint256 i = skip; i < limit; i++) {
            address pair_address = factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            pairs[j] = PairObj(
                pair_address,
                pair_obj.token0(),
                pair_obj.token1()
            );
            j++;
        }
        return pairs;
    }

    function getAllFactoryPairsDefaultFactorySkipLimit(
        uint256 skip,
        uint256 limit
    ) public view returns (PairObj[] memory) {
        return getAllFactoryPairsSkipLimit(default_factory, skip, limit);
    }

    function beethovenReserves(bytes32[] calldata poolsId)
        public
        view
        returns (BeethovenPoolReserves[] memory)
    {
        uint256 count = poolsId.length;
        BeethovenPoolReserves[] memory result = new BeethovenPoolReserves[](
            count
        );
        for (uint256 i = 0; i < count; i++) {
            (
                IERC20[] memory tokens,
                uint256[] memory balances,
                uint256 lastChangeBlock
            ) = beethoven_contract.getPoolTokens(poolsId[i]);
            result[i] = BeethovenPoolReserves(
                poolsId[i],
                balances,
                tokens,
                lastChangeBlock
            );
        }
        return result;
    }

    function multiGetLPBalancesSkipLimit(
        address wallet_address,
        uint256 skip,
        uint256 limit
    ) public view returns (LP_balance[] memory) {
        LP_balance[] memory lp_balances = new LP_balance[](limit);
        limit += skip;
        uint256 j = 0;
        for (uint256 i = skip; i < limit; i++) {
            address pair_address = default_factory.allPairs(i);
            lp_balances[j] = LP_balance(
                pair_address,
                IERC20(pair_address).balanceOf(wallet_address)
            );
            j++;
        }
        return lp_balances;
    }

    function multiGetLPBalances(address wallet_address)
        public
        view
        returns (LP_balance[] memory)
    {
        uint256 count = default_factory.allPairsLength();
        LP_balance[] memory lp_balances = new LP_balance[](count);
        for (uint256 i = 0; i < count; i++) {
            address pair_address = default_factory.allPairs(i);
            lp_balances[i] = LP_balance(
                pair_address,
                IERC20(pair_address).balanceOf(wallet_address)
            );
        }
        return lp_balances;
    }

    function _calculatePriceImpact(
        address[] memory selectedPath,
        uint256 amountIn,
        uint256 amount_out
    ) public view returns (uint256 price, int256 priceImpact) {
        uint256 count = selectedPath.length - 1;
        uint256[][] memory path_reserves = new uint256[][](count);
        (uint256 decimal_token_in, uint256 decimal_token_out) = (0, 0);
        // (uint256 r0, uint256 r1, uint256 _r0, uint256 _r1) = (0, 0, 0, 0);
        if (selectedPath[0] == selectedPath[selectedPath.length - 1]) {
            price = DIV_PERCISION;
        } else {
            decimal_token_in = IERC20(selectedPath[0]).decimals();
            decimal_token_out = IERC20(selectedPath[selectedPath.length - 1])
                .decimals();
            for (uint256 i = 0; i < count; i++) {
                // uint256[] memory
                address token0 = selectedPath[i];
                address token1 = selectedPath[i + 1];

                IUniswapV2Pair tokenAtokenBPair = IUniswapV2Pair(
                    default_factory.getPair(token0, token1)
                );

                (uint256 _r0, uint256 _r1, ) = tokenAtokenBPair.getReserves();
                (_r0, _r1) = token0 < token1 ? (_r0, _r1) : (_r1, _r0);
                uint256[] memory _reserve = new uint256[](2);
                _reserve[0] = _r0;
                _reserve[1] = _r1;
                path_reserves[i] = _reserve;
            }
            (uint256 numerator, uint256 dominator) = (1, 1);
            for (uint256 i = 0; i < count; i++) {
                numerator *= path_reserves[i][1];
                dominator *= path_reserves[i][0];
            }

            price =
                (numerator * DIV_PERCISION * 10**decimal_token_in) /
                (dominator * 10**decimal_token_out);
        }
        int256 initialValue = int256(amountIn * price * 10**decimal_token_out);
        int256 resultValue = int256(
            amount_out * DIV_PERCISION * 10**decimal_token_in
        );
        int256 tmpDominator = int256(initialValue / int256(DIV_PERCISION));
        int256 tmpNomerator = (initialValue - resultValue) /
            int256(10**decimal_token_out);
        priceImpact = tmpNomerator / tmpDominator;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "UNISWAPLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                IUniswapV2Pair(default_factory.getPair(path[i], path[i + 1])),
                path[i],
                path[i + 1]
            );
            if (
                amounts[i] == 0 ||
                reserveIn < amounts[i] + 10 ||
                reserveOut < 10
            ) break;
            amounts[i + 1] = default_router.getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "PaintLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                IUniswapV2Pair(default_factory.getPair(path[i - 1], path[i])),
                path[i - 1],
                path[i]
            );
            if (amounts[i] == 0 || reserveOut < amounts[i] || reserveIn < 10)
                break;
            else {
                amounts[i - 1] = default_router.getAmountIn(
                    amounts[i],
                    reserveIn,
                    reserveOut
                );
            }
        }
    }

    function getAmountsOutMulti(uint256 amountIn, address[][] memory path)
        public
        view
        returns (
            uint256,
            address[] memory,
            int256,
            uint256
        )
    {
        uint256 count = path.length;
        uint256 max = 0;
        uint256 index = 0;
        uint256[] memory amountsOut;
        uint256 amountOut = 0;

        for (uint256 i = 0; i < count; i++) {
            if (path[i][0] == WFTM && path[i][path[i].length - 1] == WFTM) {
                address[] memory result_path = new address[](1);
                result_path[0] = WFTM;
                return (amountIn, result_path, 0, DIV_PERCISION);
            }
            amountsOut = getAmountsOut(amountIn, path[i]);
            amountOut = amountsOut[amountsOut.length - 1]; // get the last element
            if (amountOut > max) {
                index = i;
                max = amountOut;
            }
        }

        (uint256 price, int256 priceImpact) = _calculatePriceImpact(
            path[index],
            amountIn,
            max
        );

        return (max, path[index], priceImpact, price);
    }

    function getAmountsInMulti(uint256 amountOut, address[][] memory path)
        public
        view
        returns (
            uint256,
            address[] memory,
            int256,
            uint256
        )
    {
        uint256 count = path.length;
        uint256 _min = MAX_INT_VALUE;
        uint256 index = 0;
        uint256[] memory amountsIn;
        uint256 amountIn = 0;
        for (uint256 i = 0; i < count; i++) {
            amountsIn = getAmountsIn(amountOut, path[i]);
            amountIn = amountsIn[0];
            if (amountIn > 1 && amountIn < _min) {
                index = i;
                _min = amountIn;
            }
        }
        if (_min != MAX_INT_VALUE) {
            (uint256 price, int256 priceImpact) = _calculatePriceImpact(
                path[index],
                _min,
                amountOut
            );
            return (_min, path[index], priceImpact, price);
        } else {
            address[] memory empty_res = new address[](0);
            return (0, empty_res, 0, 0);
        }
    }

    function _getShare(IUniswapV2Pair pair_obj, address wallet_address)
        internal
        view
        returns (ShareOfPool memory)
    {
        (uint256 r0, uint256 r1, ) = pair_obj.getReserves();
        uint256 wallet_LP_balance = pair_obj.balanceOf(wallet_address);
        uint256 totalSupply = pair_obj.totalSupply();
        if (totalSupply == 0) {
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                0,
                pair_obj.token1(),
                0,
                0,
                0,
                0
            );

            return share;
        }
        uint256 share_with_percision = (wallet_LP_balance * DIV_PERCISION) /
            totalSupply;
        if (share_with_percision > 1) {
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                (r0 * share_with_percision) / DIV_PERCISION,
                pair_obj.token1(),
                (r1 * share_with_percision) / DIV_PERCISION,
                share_with_percision,
                wallet_LP_balance,
                totalSupply
            );

            return share;
        } else {
            ShareOfPool memory share = ShareOfPool(
                address(pair_obj),
                pair_obj.token0(),
                0,
                pair_obj.token1(),
                0,
                share_with_percision,
                wallet_LP_balance,
                totalSupply
            );

            return share;
        }
    }

    function getShareMulti(address wallet_address)
        public
        view
        returns (ShareOfPool[] memory)
    {
        uint256 count = default_factory.allPairsLength();
        ShareOfPool[] memory shares = new ShareOfPool[](count);
        for (uint256 i = 0; i < count; i++) {
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            shares[i] = _getShare(pair_obj, wallet_address);
        }
        return shares;
    }

    function getShareMultiSkipLimit(
        address wallet_address,
        uint256 skip,
        uint256 limit
    ) public view returns (ShareOfPool[] memory) {
        uint256 count = default_factory.allPairsLength();

        limit += skip;
        limit = count > limit ? limit : count;
        ShareOfPool[] memory shares = new ShareOfPool[](limit - skip);

        uint256 j = 0;
        for (uint256 i = skip; i < limit; i++) {
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);
            shares[j] = _getShare(pair_obj, wallet_address);
            j++;
        }
        return shares;
    }

    function getShareMultiExactToken(
        address wallet_address,
        address token_address
    ) public view returns (ShareOfPool[] memory, uint256 result) {
        uint256 count = default_factory.allPairsLength();
        ShareOfPool[] memory shares = new ShareOfPool[](count);
        bool[] memory token_share_indecies = new bool[](count);
        uint256 token_pairs_count = 0;
        result = 0;
        for (uint256 i = 0; i < count; i++) {
            address pair_address = default_factory.allPairs(i);
            IUniswapV2Pair pair_obj = IUniswapV2Pair(pair_address);

            if (pair_obj.token0() == token_address) {
                ShareOfPool memory share = _getShare(pair_obj, wallet_address);
                shares[i] = share;
                result += share.share0;
                token_pairs_count += 1;
                token_share_indecies[i] = true;
            } else if (pair_obj.token1() == token_address) {
                ShareOfPool memory share = _getShare(pair_obj, wallet_address);
                shares[i] = share;
                result += share.share1;
                token_pairs_count += 1;
                token_share_indecies[i] = true;
            }
        }
        ShareOfPool[] memory token_shares = new ShareOfPool[](
            token_pairs_count
        );
        uint256 j = 0;
        for (uint256 i = 0; i < count; i++) {
            if (token_share_indecies[i] == true) {
                token_shares[j] = shares[i];
                j++;
            }
        }
        return (token_shares, result);
    }

    function circulatingSupply(
        address token_address,
        address[] memory locked_walltes
    ) public view returns (uint256 result) {
        IERC20 token_obj = IERC20(token_address);
        result = token_obj.totalSupply();
        for (uint256 i = 0; i < locked_walltes.length; i++) {
            result -= token_obj.balanceOf(locked_walltes[i]);
        }
    }

    function getReserves(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function maintanerLpCountInPair(address pair_address)
        public
        view
        returns (uint256 liquidity)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        (uint256 _r0, uint256 _r1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        address feeTo = default_factory.feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = pair.kLast(); // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_r0) * (_r1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = (rootK * MAINTAINER_FEE_MULTIPLIER) +
                        (rootKLast);
                    liquidity = numerator / denominator;
                }
            } else {
                liquidity = 0;
            }
        } else {
            liquidity = 0;
        }
    }

    function maintanerLpCount(address pair_address)
        public
        view
        returns (uint256 liquidity)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        liquidity =
            pair.balanceOf(default_factory.feeTo()) +
            maintanerLpCountInPair(pair_address);
    }

    function mintAmount(
        uint256 totalSupply,
        uint256 amount0,
        uint256 amount1,
        uint256 MINIMUM_LIQUIDITY,
        uint256 _reserve0,
        uint256 _reserve1
    ) public pure returns (uint256 liquidity) {
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - (MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }
    }

    function getAmountOutAddLiquidity(
        uint256 amountIn,
        address tokenA,
        address tokenB
    )
        public
        view
        returns (
            uint256 amountOut,
            uint256 share,
            uint256 lpCount,
            uint256 totalSupply,
            address pairAddress,
            uint256 rA,
            uint256 rB
        )
    {
        pairAddress = default_factory.getPair(tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        totalSupply = pair.totalSupply();
        (rA, rB) = getReserves(pair, tokenA, tokenB);
        amountOut = (amountIn * rB) / rA;
        lpCount = mintAmount(
            totalSupply,
            amountIn,
            amountOut,
            pair.MINIMUM_LIQUIDITY(),
            rA,
            rB
        );
        share = 0;
        uint256 newTS = totalSupply + lpCount;
        uint256 tmp = lpCount * DIV_PERCISION;
        share = tmp / newTS;
    }

    function getAmountInAddLiquidity(
        uint256 amountOut,
        address tokenA,
        address tokenB
    )
        public
        view
        returns (
            uint256 amountIn,
            uint256 share,
            uint256 lpCount,
            uint256 totalSupply,
            address pairAddress,
            uint256 rA,
            uint256 rB
        )
    {
        pairAddress = default_factory.getPair(tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        totalSupply = pair.totalSupply();
        (rA, rB) = getReserves(pair, tokenA, tokenB);
        amountIn = (amountOut * rA) / rB;
        lpCount = mintAmount(
            totalSupply,
            amountIn,
            amountOut,
            pair.MINIMUM_LIQUIDITY(),
            rA,
            rB
        );
        share = 0;
        uint256 newTS = totalSupply + lpCount;
        uint256 tmp = lpCount * DIV_PERCISION;
        share = tmp / newTS;
    }

    // function poolList
    /// Pair related information

    function userDetails(address wallet_address)
        public
        view
        returns (WalletDetail[] memory)
    {
        uint256 count = default_masterchef.poolLength();
        WalletDetail[] memory walletDetails = new WalletDetail[](count);
        for (uint256 i = 0; i < count; i++) {
            IMasterChef.PoolInfo memory pool = default_masterchef.poolInfo(i);
            IMasterChef.UserInfo memory user = default_masterchef.userInfo(
                i,
                wallet_address
            );
            IERC20 token0 = IERC20(pool.lpToken.token0());
            IERC20 token1 = IERC20(pool.lpToken.token1());
            string memory name = string(
                abi.encodePacked(token0.symbol(), "-", token1.symbol())
            );
            uint256 lpBalance = pool.lpToken.balanceOf(wallet_address);
            walletDetails[i] = WalletDetail(
                i,
                pool.lpToken,
                name,
                token0,
                token1,
                pool.lpToken.totalSupply(),
                pool.lpToken.balanceOf(address(default_masterchef)),
                pool.allocPoint,
                pool.lastRewardTime,
                pool.accTCSPerShare,
                user.amount,
                user.rewardDebt,
                lpBalance,
                (user.amount * pool.accTCSPerShare) - user.rewardDebt
            );
        }
        return walletDetails;
    }


    function burn_rate(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) public returns (uint256 pre_balance, uint256 post_balance) {
        pre_balance = token.balanceOf(recipient);
        token.transferFrom(sender, recipient, amount);
        post_balance = token.balanceOf(recipient);
    }

    function has_permit(
        IERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (uint256) {
        token.permit(owner, spender, amount, deadline, v, r, s);
        return token.allowance(owner, spender);
    }
}