// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBribe {
    function addReward(address rewardToken) external;
    function balanceOf(address account) external view returns (uint256);
    function _deposit(uint amount, address account) external;
    function _withdraw(uint amount, address account) external;
    function getRewardForOwner(address account) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function getRewardTokens() external view returns (address[] memory);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address _rewardsToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGauge {
    function addReward(address rewardToken) external;
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account) external;
    function claimVotingFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address reward) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPlugin {
    function getUnderlyingTokenName() external view returns (string memory);
    function getUnderlyingTokenSymbol() external view returns (string memory);
    function getUnderlyingTokenAddress() external view returns (address);
    function getProtocol() external view returns (string memory);
    function getBribe() external view returns (address);
    function getTokensInUnderlying() external view returns (address[] memory);
    function getBribeTokens() external view returns (address[] memory);
    function getVoter() external view returns (address);
    function price() external view returns (uint);
    function claimAndDistribute() external;
    function setGauge(address _gauge) external;
    function setBribe(address _bribe) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewarder {
    function addReward(address rewardToken) external;
    function _deposit(uint amount, address account) external;
    function _withdraw(uint amount, address account) external;
    function getReward() external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function getRewardTokens() external view returns (address[] memory);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address _rewardsToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ITOKEN {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function mint(address, uint) external;
    function treasury() external view returns (address);
    function VTOKEN() external view returns (address);
    function fees() external view returns (address);
    function debt(address account) external view returns (uint256);
    function borrowCreditBASE(address account) external view returns (uint256);
    function currentPrice() external view returns (uint256);
    function floorPrice() external view returns (uint256);
    function OTOKENPrice() external view returns (uint256);
    function sellMax() external view returns (uint256);
    function tvl() external view returns (uint256);
    function frBASE() external view returns (uint256);
    function mrvBASE() external view returns (uint256);
    function mrrBASE() external view returns (uint256);
    function mrrTOKEN() external view returns (uint256);
    function marketMaxTOKEN() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVoter {
    function VTOKEN() external view returns (address);
    function usedWeights(address account) external view returns (uint256);
    function pools(uint256 index) external view returns (address);
    function getPools() external view returns (address[] memory);
    function gauges(address pool) external view returns (address);
    function bribes(address pool) external view returns (address);
    function weights(address pool) external view returns (uint256);
    function totalWeight() external view returns (uint256);
    function emitDeposit(address account, uint amount) external;
    function emitWithdraw(address account, uint amount) external;
    function notifyRewardAmount(uint amount) external;
    function distribute(address _gauge) external;
    function treasury() external view returns (address);
    function votes(address account, address pool) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVTOKEN {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalSupplyTOKEN() external view returns (uint256);
    function notifyRewardAmount(address reward, uint256 amount) external;
    function balanceOfTOKEN(address account) external view returns (uint256);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address _rewardsToken) external view returns (uint256);
    function rewarder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IERC20.sol';
import 'contracts/interfaces/IPlugin.sol';

import 'contracts/interfaces/IVoter.sol';
import 'contracts/interfaces/IGauge.sol';
import 'contracts/interfaces/IBribe.sol';

import 'contracts/interfaces/ITOKEN.sol';
import 'contracts/interfaces/IVTOKEN.sol';
import 'contracts/interfaces/IRewarder.sol';

interface IOracle {
    function latestAnswer() external view returns (int256);
}

contract Multicall {

    address public constant BASE = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public constant PRICE_ORACLE_BASE = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
    uint256 public constant FEE = 20;
    uint256 public constant DIVISOR = 1000;

    address public voter;
    address public TOKEN;
    address public VTOKEN;
    address public OTOKEN;
    address public rewarder;

    struct SwapCard {
        uint256 frBASE;
        uint256 mrvBASE;
        uint256 mrrBASE;
        uint256 mrrTOKEN;
        uint256 marketMaxTOKEN;
    }

    struct BondingCurve {
        uint256 priceBASE; // Base token like FTM or OP in USD
        uint256 priceTOKEN; // Price of GLOVE and xGLOVE in USD
        uint256 priceOTOKEN; // Price of POWER in USD
        uint256 maxMarketSell;

        uint256 tvl;
        uint256 supplyTOKEN; // supply of GLOVE
        uint256 supplyVTOKEN; // supply of xGLOVE
        uint256 apr;
        uint256 ltv;
        uint256 ratio;

        uint256 accountBASE; // OP or FTM amount that account has
        uint256 accountTOKEN; // user balance of GLOVE
        uint256 accountOTOKEN; // user balance of POWER

        uint256 accountEarnedBASE; // Base token rewards like OP and FTM
        uint256 accountEarnedTOKEN; // GLOVE rewards
        uint256 accountEarnedOTOKEN; // POWER rewards

        uint256 accountVTOKEN; // user balance of xGLOVE
        uint256 accountVotingPower;
        uint256 accountUsedWeights;

        uint256 accountBorrowCredit; // amount of base (OP or FTM) a user can borrow
        uint256 accountBorrowDebt; // amount of base (OP or FTM) a user owess
        uint256 accountMaxWithdraw; // max amount of GLOVE a user can unstake from xGLOVE
    }

    struct GaugeCard {
        string protocol;
        string symbol;
        address[] tokensInUnderlying;

        uint256 pluginPrice;
        uint256 priceOTOKEN;

        uint256 apr;
        uint256 tvl;
        uint256 votingWeight;

        uint256 accountUnderlyingTokens;
        uint256 accountUnstakedTokens;
        uint256 accountStakedTokens;
        uint256 accountEarnedOTOKEN;
    }

    struct BribeCard {
        string protocol;
        string symbol;

        address[] rewardTokens;
        uint256[] rewardsPerToken;
        uint256[] accountRewardsEarned;

        uint256 voteWeight;
        uint256 votePercent;

        uint256 accountVotePercent;
    }

    constructor(address _voter,address _TOKEN, address _VTOKEN, address _OTOKEN) {
        voter = _voter;
        TOKEN = _TOKEN;
        VTOKEN = _VTOKEN;
        OTOKEN = _OTOKEN;
        rewarder = IVTOKEN(_VTOKEN).rewarder();
    }

    function quoteBuyIn(uint256 input, uint256 slippageTolerance) external view returns (uint256 output, uint256 slippage, uint256 minOutput) {
        uint256 feeBASE = input * FEE / DIVISOR;
        uint256 oldMrBASE = ITOKEN(TOKEN).mrvBASE() + ITOKEN(TOKEN).mrrBASE();
        uint256 newMrBASE = oldMrBASE + input - feeBASE;
        uint256 oldMrTOKEN = ITOKEN(TOKEN).mrrTOKEN();
        output = oldMrTOKEN - (oldMrBASE * oldMrTOKEN / newMrBASE);

        return (output, 100 * (1e18 - (output * 1e18 / (input * 1e18 / ITOKEN(TOKEN).currentPrice()))), (input * 1e18 / ITOKEN(TOKEN).currentPrice()) * slippageTolerance / DIVISOR);
    }

    function quoteBuyOut(uint256 input, uint256 slippageTolerance) external view returns (uint256 output, uint256 slippage, uint256 minOutput) {
        uint256 oldMrBASE = ITOKEN(TOKEN).mrvBASE() + ITOKEN(TOKEN).mrrBASE();
        output = DIVISOR * ((oldMrBASE * ITOKEN(TOKEN).mrrTOKEN() / (ITOKEN(TOKEN).mrrTOKEN() - input)) - oldMrBASE) / (DIVISOR - FEE);

        return (output, 100 * (1e18 - (input * 1e18 / (output * 1e18 / ITOKEN(TOKEN).currentPrice()))), input * slippageTolerance / DIVISOR);
    }

    function quoteSellIn(uint256 input, uint256 slippageTolerance) external view returns (uint256 output, uint256 slippage, uint256 minOutput) {
        uint256 feeTOKEN = input * FEE / DIVISOR;
        uint256 oldMrTOKEN = ITOKEN(TOKEN).mrrTOKEN();
        uint256 newMrTOKEN = oldMrTOKEN + input - feeTOKEN;
        require(newMrTOKEN <= ITOKEN(TOKEN).marketMaxTOKEN(), 'Exceeds Market Reserves');

        uint256 oldMrBASE = ITOKEN(TOKEN).mrvBASE() + ITOKEN(TOKEN).mrrBASE();
        output = oldMrBASE - (oldMrBASE * oldMrTOKEN / newMrTOKEN);

        return (output, 100 * (1e18 - (output * 1e18 / (input * ITOKEN(TOKEN).currentPrice() / 1e18))), (input * ITOKEN(TOKEN).currentPrice() / 1e18) * slippageTolerance / DIVISOR);
    }

    function quoteSellOut(uint256 input, uint256 slippageTolerance) external view returns (uint256 output, uint256 slippage, uint256 minOutput) {
        require(input <= ITOKEN(TOKEN).marketMaxTOKEN(), 'Exceeds Market Reserves');
        uint256 oldMrBASE = ITOKEN(TOKEN).mrvBASE() + ITOKEN(TOKEN).mrrBASE();
        output = DIVISOR * ((oldMrBASE * ITOKEN(TOKEN).mrrTOKEN() / (oldMrBASE - input)) - ITOKEN(TOKEN).mrrTOKEN()) / (DIVISOR - FEE);

        return (output, 100 * (1e18 - (input * 1e18 / (output * ITOKEN(TOKEN).currentPrice() / 1e18))), input * slippageTolerance / DIVISOR);
    }

    function getPools() external view returns (address[] memory) {
        return IVoter(voter).getPools();
    }

    function pool(uint256 index) external view returns (address) {
        return IVoter(voter).pools(index);
    }

    function swapCardData() external view returns (SwapCard memory swapCard) {
        swapCard.frBASE = ITOKEN(TOKEN).frBASE();
        swapCard.mrvBASE = ITOKEN(TOKEN).mrvBASE();
        swapCard.mrrBASE = ITOKEN(TOKEN).mrrBASE();
        swapCard.mrrTOKEN = ITOKEN(TOKEN).mrrTOKEN();
        swapCard.marketMaxTOKEN = ITOKEN(TOKEN).marketMaxTOKEN();
        swapCard.marketMaxTOKEN = 0;

        return swapCard;
    }

    function bondingCurveData(address account) external view returns (BondingCurve memory bondingCurve) {
        bondingCurve.priceBASE = uint256(IOracle(PRICE_ORACLE_BASE).latestAnswer()) * 1e18 / 1e8;
        bondingCurve.priceTOKEN = ITOKEN(TOKEN).currentPrice() * bondingCurve.priceBASE / 1e18;
        bondingCurve.priceOTOKEN = ITOKEN(TOKEN).OTOKENPrice() * bondingCurve.priceBASE / 1e18;
        bondingCurve.maxMarketSell = ITOKEN(TOKEN).sellMax();

        bondingCurve.tvl = ITOKEN(TOKEN).tvl() * bondingCurve.priceBASE / 1e18;
        bondingCurve.supplyTOKEN = ITOKEN(TOKEN).totalSupply();
        bondingCurve.supplyVTOKEN = IVTOKEN(VTOKEN).totalSupply();
        bondingCurve.apr = ((IRewarder(rewarder).rewardPerToken(BASE) * bondingCurve.priceBASE / 1e18) +  (IRewarder(rewarder).rewardPerToken(TOKEN) * bondingCurve.priceTOKEN / 1e18) + 
                           (IRewarder(rewarder).rewardPerToken(OTOKEN) * bondingCurve.priceOTOKEN / 1e18)) * 365 * 100 * 1e18 / (7 * bondingCurve.priceTOKEN);
        bondingCurve.ltv = 100 * ITOKEN(TOKEN).floorPrice() * 1e18 / ITOKEN(TOKEN).currentPrice();
        bondingCurve.ratio = ITOKEN(TOKEN).currentPrice() * 1e18 / ITOKEN(TOKEN).floorPrice();

        bondingCurve.accountBASE = (account == address(0) ? 0 : IERC20(BASE).balanceOf(account));
        bondingCurve.accountTOKEN = (account == address(0) ? 0 : IERC20(TOKEN).balanceOf(account));
        bondingCurve.accountOTOKEN = (account == address(0) ? 0 : IERC20(OTOKEN).balanceOf(account));

        bondingCurve.accountEarnedBASE = (account == address(0) ? 0 : IRewarder(rewarder).earned(account, BASE));
        bondingCurve.accountEarnedTOKEN = (account == address(0) ? 0 : IRewarder(rewarder).earned(account, TOKEN));
        bondingCurve.accountEarnedOTOKEN = (account == address(0) ? 0 : IRewarder(rewarder).earned(account, OTOKEN));

        bondingCurve.accountVTOKEN = (account == address(0) ? 0 : IVTOKEN(VTOKEN).balanceOfTOKEN(account));
        bondingCurve.accountVotingPower = (account == address(0) ? 0 : IVTOKEN(VTOKEN).balanceOf(account));
        bondingCurve.accountUsedWeights = (account == address(0) ? 0 : IVoter(voter).usedWeights(account));

        bondingCurve.accountBorrowCredit = (account == address(0) ? 0 : ITOKEN(TOKEN).borrowCreditBASE(account));
        bondingCurve.accountBorrowDebt = (account == address(0) ? 0 : ITOKEN(TOKEN).debt(account));
        bondingCurve.accountMaxWithdraw = (account == address(0) ? 0 : (IVoter(voter).usedWeights(account) > 0 ? 0 : bondingCurve.accountVTOKEN - bondingCurve.accountBorrowDebt));

        return bondingCurve;
    }

    function gaugeCardData(address plugin, address account) external view returns (GaugeCard memory gaugeCard) {
        gaugeCard.protocol = IPlugin(plugin).getProtocol();
        gaugeCard.symbol = IERC20(plugin).symbol();
        gaugeCard.tokensInUnderlying = IPlugin(plugin).getTokensInUnderlying();

        gaugeCard.pluginPrice = IPlugin(plugin).price();
        gaugeCard.priceOTOKEN = ITOKEN(TOKEN).OTOKENPrice() * (uint256(IOracle(PRICE_ORACLE_BASE).latestAnswer()) * 1e18 / 1e8) / 1e18;
        
        gaugeCard.apr = IGauge(IVoter(voter).gauges(plugin)).rewardPerToken(OTOKEN) * gaugeCard.priceOTOKEN * 365 * 100 / 7 / gaugeCard.pluginPrice;
        gaugeCard.tvl = IGauge(IVoter(voter).gauges(plugin)).totalSupply() * gaugeCard.pluginPrice / 1e18;
        gaugeCard.votingWeight = 100 * IVoter(voter).weights(plugin) * 1e18 / IVoter(voter).totalWeight();

        gaugeCard.accountUnderlyingTokens = (account == address(0) ? 0 : IERC20(IPlugin(plugin).getUnderlyingTokenAddress()).balanceOf(account));
        gaugeCard.accountUnstakedTokens = (account == address(0) ? 0 : IERC20(plugin).balanceOf(account));
        gaugeCard.accountStakedTokens = (account == address(0) ? 0 : IGauge(IVoter(voter).gauges(plugin)).balanceOf(account));
        gaugeCard.accountEarnedOTOKEN = (account == address(0) ? 0 : IGauge(IVoter(voter).gauges(plugin)).earned(account, OTOKEN));

        return gaugeCard;
    }

    function bribeCardData(address plugin, address account) external view returns (BribeCard memory bribeCard) {
        bribeCard.protocol = IPlugin(plugin).getProtocol();
        bribeCard.symbol = IERC20(plugin).symbol();
        bribeCard.rewardTokens = IBribe(IVoter(voter).bribes(plugin)).getRewardTokens();

        uint[] memory _rewardsPerToken = new uint[](bribeCard.rewardTokens.length);
        for (uint i = 0; i < bribeCard.rewardTokens.length; i++) {
            _rewardsPerToken[i] = IBribe(IVoter(voter).bribes(plugin)).rewardPerToken(bribeCard.rewardTokens[i]);
        }
        bribeCard.rewardsPerToken = _rewardsPerToken;

        uint[] memory _accountRewardsEarned = new uint[](bribeCard.rewardTokens.length);
        for (uint i = 0; i < bribeCard.rewardTokens.length; i++) {
            _accountRewardsEarned[i] = (account == address(0) ? 0 : IBribe(IVoter(voter).bribes(plugin)).earned(account, bribeCard.rewardTokens[i]));
        }
        bribeCard.accountRewardsEarned = _accountRewardsEarned;

        bribeCard.voteWeight = IVoter(voter).weights(plugin);
        bribeCard.votePercent = 100 * IVoter(voter).weights(plugin) * 1e18 / IVoter(voter).totalWeight();

        bribeCard.accountVotePercent = (account == address(0) ? 0 : (IVoter(voter).usedWeights(account) == 0 ? 0 : 100 * IVoter(voter).votes(account, plugin) * 1e18 / IVoter(voter).usedWeights(account)));

        return bribeCard;
    }

}