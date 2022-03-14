// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IGauge.sol";
import "./interfaces/ILpDepositor.sol";
import "./interfaces/IBoostMaxxer.sol";
import "./interfaces/IBaseV1Pair.sol";
import "./interfaces/IPoolToken.sol";
import "./interfaces/IOxLens.sol";
import "./interfaces/IOxMultiRewards.sol";

contract TarotStrategyHelperSolidlyV2 {
    IBaseV1Pair public constant vamm_xTAROT_TAROT = IBaseV1Pair(0x4FE782133af0f7604B9B89Bf95893ADDE265FEFD);
    IGauge public constant gauge = IGauge(0xA0813bcCc899589B4E7d9Ac42193136D0313F4Eb);
    IBoostMaxxer public constant boostMaxxer = IBoostMaxxer(0xe21ca4536e447C13C79B807C0Df4f511A21Db6c7);
    ILpDepositor public constant lpDepositor = ILpDepositor(0x26E1A0d851CF28E697870e1b7F053B605C8b060F);
    IOxLens public constant oxLens = IOxLens(0xDA00137c79B30bfE06d04733349d98Cf06320e69);
    IOxMultiRewards public constant oxMultiRewards = IOxMultiRewards(0xE28Ad06576546c1d5953AB2871F22CC6C13285Fb);
    IPoolToken public constant oxVaultToken = IPoolToken(0x7A2edc2041E130d61e18eB93a32bB13c331067A0);
    IPoolToken public constant oxCollateral = IPoolToken(0x6f488A8743b390c893345edcdfbD670D4527841e);
    IPoolToken public constant solidexVaultToken = IPoolToken(0xF1234dBdce04C8F26E53E33d53010862Dd775D28);
    IPoolToken public constant solidexCollateral = IPoolToken(0xB98B00eD7C4F68C0d6218298748b78296B03945F);
    address public constant oxVaultTokenUserProxyAddress = 0xaF73d1Afb44eA75db5124748d17A41Deb1523c4d;

    constructor() {}

    function getTarotLpBalance(
        address _user,
        IPoolToken collateral,
        IPoolToken vaultToken,
        address lpAt,
        address lpAtAddress
    ) public view returns (uint256 amount) {
        uint256 collateralBalance = collateral.balanceOf(_user);
        uint256 collateralTotalSupply = collateral.totalSupply();
        uint256 collateralVaultTokenBalance = vaultToken.balanceOf(address(collateral));
        uint256 collateralExchangeRate = 1e18;
        if (collateralTotalSupply > 0 && collateralVaultTokenBalance > 0) {
            collateralExchangeRate = (collateralVaultTokenBalance * 1e18) / collateralTotalSupply;
        }
        uint256 vaultTokenBalance = (collateralBalance * collateralExchangeRate) / 1e18;
        uint256 vaultTokenTotalSupply = vaultToken.totalSupply();
        uint256 vaultTokenLpBalance;
        if (lpAt == address(oxMultiRewards)) {
            vaultTokenLpBalance = IOxMultiRewards(lpAt).balanceOf(lpAtAddress);
        }
        if (lpAt == address(lpDepositor)) {
            vaultTokenLpBalance = ILpDepositor(lpAt).userBalances(lpAtAddress, address(vamm_xTAROT_TAROT));
        }
        uint256 vaultTokenExchangeRate = 1e18;
        if (vaultTokenTotalSupply > 0 && vaultTokenLpBalance > 0) {
            vaultTokenExchangeRate = (vaultTokenLpBalance * 1e18) / vaultTokenTotalSupply;
        }
        amount = (vaultTokenBalance * vaultTokenExchangeRate) / 1e18;
    }

    function getLpBalance(address _user) public view returns (uint256 amount) {
        uint256 oxTarotLpBalance = getTarotLpBalance(
            _user,
            oxCollateral,
            oxVaultToken,
            address(oxMultiRewards),
            oxVaultTokenUserProxyAddress
        );
        uint256 solidexTarotLpBalance = getTarotLpBalance(
            _user,
            solidexCollateral,
            solidexVaultToken,
            address(lpDepositor),
            address(solidexVaultToken)
        );
        amount =
            oxTarotLpBalance +
            solidexTarotLpBalance +
            oxMultiRewards.balanceOf(oxLens.userProxyByAccount(_user)) +
            boostMaxxer.userDepositedAmountInfo(address(vamm_xTAROT_TAROT), _user) +
            lpDepositor.userBalances(_user, address(vamm_xTAROT_TAROT)) +
            gauge.balanceOf(_user) +
            vamm_xTAROT_TAROT.balanceOf(_user);
    }

    function getVotes(address _user) public view returns (uint256 amount) {
        (uint256 reserve0, , ) = vamm_xTAROT_TAROT.getReserves();
        uint256 lpTotalSupply = vamm_xTAROT_TAROT.totalSupply();
        if (lpTotalSupply > 0) {
            amount = (reserve0 * getLpBalance(_user)) / lpTotalSupply;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IGauge {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ILpDepositor {
    function userBalances(address user, address pool) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBoostMaxxer {
    function userDepositedAmountInfo(address pool, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBaseV1Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function balanceOf(address) external view returns (uint);
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPoolToken {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOxLens {
    function userProxyByAccount(address account) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOxMultiRewards {
    function balanceOf(address account) external view returns (uint256);
}