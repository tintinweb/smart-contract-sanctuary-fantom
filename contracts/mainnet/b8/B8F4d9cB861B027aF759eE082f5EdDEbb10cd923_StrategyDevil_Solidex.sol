// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StrategyDevil.sol";
import "./ISolidlyRouter.sol";

interface ILpDepositor {
    function deposit(address _lpToken, uint256 _amount) external;
    function withdraw(address _lpToken, uint256 _amount) external;
    function getReward(address[] calldata pools) external;
}

contract StrategyDevil_Solidex is StrategyDevil {

    address public earned0Address;
    address[] public earned0ToEarnedPath;
    bool isStable;

    constructor(
        address[] memory _addresses,
        address[] memory _tokenAddresses,
        bool _isStable,
        address[] memory _earnedToWFTMPath,
        address[] memory _WFTMToNATIVEPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        address[] memory _earned0ToEarnedPath,
        // uint256 _depositFeeFactor,
        uint256 _withdrawFeeFactor
        // uint256 _entranceFeeFactor
    ) public {
        nativeFarmAddress = _addresses[0];
        farmContractAddress = _addresses[1];
        govAddress = _addresses[2];
        uniRouterAddress = _addresses[3];
        buybackRouterAddress = _addresses[4];

        NATIVEAddress = _tokenAddresses[0];
        wftmAddress = _tokenAddresses[1];
        wantAddress = _tokenAddresses[2];
        earnedAddress = _tokenAddresses[3];
        earned0Address = _tokenAddresses[4];
        token0Address = _tokenAddresses[5];
        token1Address = _tokenAddresses[6];

        isStable = _isStable;
        isSingleVault = false;
        isAutoComp = true;

        earnedToWFTMPath = _earnedToWFTMPath;
        WFTMToNATIVEPath = _WFTMToNATIVEPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;
        earned0ToEarnedPath = _earned0ToEarnedPath;

        depositFeeFactor = 10000;
        withdrawFeeFactor = _withdrawFeeFactor;
        entranceFeeFactor = 10000;

        transferOwnership(nativeFarmAddress);
    }

    function _farm() internal override {
        require(isAutoComp, "!isAutoComp");
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        ILpDepositor(farmContractAddress).deposit(wantAddress, wantAmt);
    }

    function _unfarm(uint256 _wantAmt) internal override {
        ILpDepositor(farmContractAddress).withdraw(wantAddress, _wantAmt);
    }

    function earn() public override nonReentrant whenNotPaused {
        require(isAutoComp, "!isAutoComp");

        address[] memory wantAddresses = new address[](1);
        wantAddresses[0]=wantAddress;
        ILpDepositor(farmContractAddress).getReward(wantAddresses);

        // Converts farm tokens into want tokens
        
        uint256 earned0Amt = IERC20(earned0Address).balanceOf(address(this));

        if (earned0Amt > 0 && earned0Address != earnedAddress) {
            IERC20(earned0Address).safeIncreaseAllowance(
                uniRouterAddress,
                earned0Amt
            );

            _safeSwap(
                uniRouterAddress,
                earned0Amt,
                0,
                earned0ToEarnedPath,
                address(this),
                now + routerDeadlineDuration
            );
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);
        earnedAmt = buyBack(earnedAmt);

        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            earnedAmt
        );

        if (earnedAddress != token0Address) {
            // Swap half earned to token0
            _safeSwap(
                uniRouterAddress,
                earnedAmt.div(2),
                0,
                earnedToToken0Path,
                address(this),
                now + routerDeadlineDuration
            );
        }

        if (earnedAddress != token1Address) {
            // Swap half earned to token1
            _safeSwap(
                uniRouterAddress,
                earnedAmt.div(2),
                0,
                earnedToToken1Path,
                address(this),
                now + routerDeadlineDuration
            );
        }

        // Get want tokens, ie. add liquidity
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );
            ISolidlyRouter(uniRouterAddress).addLiquidity(
                token0Address,
                token1Address,
                isStable,
                token0Amt,
                token1Amt,
                0,
                0,
                address(this),
                now + routerDeadlineDuration
            );
        }

        lastEarnBlock = block.number;

        _farm();
    }

    function buyBack(uint256 _earnedAmt) internal override returns (uint256) {
        if (buyBackRate <= 0) {
            return _earnedAmt;
        }

        uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

        if (uniRouterAddress != buybackRouterAddress) {
            // Example case: LP token on ApeSwap and NATIVE token on PancakeSwap

            if (earnedAddress != wftmAddress) {
                IERC20(earnedAddress).safeIncreaseAllowance(
                    uniRouterAddress,
                    buyBackAmt
                );
                
                _safeSwap(
                    uniRouterAddress,
                    buyBackAmt,
                    0,
                    earnedToWFTMPath,
                    address(this),
                    now + routerDeadlineDuration
                );
            }

            // convert all wftm to Native and burn them
            uint256 wftmAmt = IERC20(wftmAddress).balanceOf(address(this));
            if (wftmAmt > 0) {
                IERC20(wftmAddress).safeIncreaseAllowance(
                    buybackRouterAddress,
                    wftmAmt
                );

                IXRouter02(buybackRouterAddress)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    wftmAmt,
                    0,
                    WFTMToNATIVEPath,
                    buyBackAddress,
                    now + routerDeadlineDuration
                );
            }
        } else {
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                buyBackAmt
            );

            _safeSwap(
                uniRouterAddress,
                buyBackAmt,
                0,
                earnedToNATIVEPath,
                buyBackAddress,
                now + routerDeadlineDuration
            );
        }

        return _earnedAmt.sub(buyBackAmt);
    }

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal override {
        route[] memory routes = new route[](_path.length.sub(1));
        for (uint i = 0; i < _path.length.sub(1); i++) {
            routes[i] = route(_path[i], _path[i+1], false);
        }

        ISolidlyRouter(_uniRouterAddress)
            .swapExactTokensForTokens(
            _amountIn,
            0,
            routes,
            _to,
            _deadline
        );
    }

    function convertDustToEarned() public override virtual whenNotPaused {}
}