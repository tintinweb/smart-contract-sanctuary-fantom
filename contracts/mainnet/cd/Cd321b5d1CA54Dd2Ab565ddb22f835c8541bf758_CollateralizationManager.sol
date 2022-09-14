// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IContractRegistry } from "../interfaces/IContractRegistry.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { ITokenRegistry } from "../interfaces/ITokenRegistry.sol";
import { IStakingManager } from "../interfaces/IStakingManager.sol";
import { Ratio, ICollateralizationManager } from "../interfaces/ICollateralizationManager.sol";


contract CollateralizationManager is ICollateralizationManager, ReentrancyGuard
{
  IContractRegistry private constant _REGISTRY = IContractRegistry(0x06Eeb1B35361687f10909902AD4704AC7d09e0E7);
  address private constant _KAE = 0x65Def5029A0e7591e46B38742bFEdd1Fb7b24436;

  uint256 private constant _BASIS_POINT = 10000;


  mapping(address => Ratio) private _ratio;


  function getRatio (address token) external view override returns (Ratio memory)
  {
     return _ratio[token];
  }

  function setRatios (address[] calldata tokens, Ratio[] calldata ratios) external nonReentrant
  {
    require(tokens.length == ratios.length, "!=");
    require(_ratio[_KAE].init == 0, "set");


    for (uint256 i; i < ratios.length; i++)
    {
      Ratio memory ratio = ratios[i];
      address token = tokens[i];

      require(token != address(0), "0 addr");
      require(ratio.init >= 13000, "!valid init");
      require(ratio.liquidation >= 12500, "!valid liq");


      _ratio[token] = ratio;
    }


    _ratio[_KAE] = Ratio({ init: _BASIS_POINT, liquidation: _BASIS_POINT });
  }


  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }

  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view override returns (bool)
  {
    require(debtToken != collateralToken && ITokenRegistry(tokenRegistry).isValidPair(debtToken, collateralToken), "!valid pair");


    return collateral >= _calcPercentOf(debtInCollateralToken, _ratio[collateralToken].init);
  }

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view override returns (bool, uint256)
  {
    uint256 ratio = _ratio[collateralToken].liquidation;

    if (IStakingManager(_REGISTRY.stakingManager()).isDiscountedForDebts(borrower) && !ITokenRegistry(_REGISTRY.tokenRegistry()).isStable(collateralToken))
    {
      ratio -= _calcPercentOf(ratio, 350);
    }


    uint256 liqRatioDebt = IOracle(_REGISTRY.oracle()).convert(debtToken, collateralToken, _calcPercentOf(debt, ratio));


    return (collateral > liqRatioDebt, (collateral / (liqRatioDebt / ratio) ));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


struct Contracts
{
  address oracle;
  address tokenRegistry;
  address coordinator;
  address stakingManager;
  address feeManager;
  address collateralizationManager;
  address rewardManager;
}


interface IContractRegistry
{
  function getContract (bytes32 key) external view returns (address);


  function borrowContracts () external view returns (Contracts memory);


  function oracle () external view returns (address);

  function tokenRegistry () external view returns (address);

  function vault () external view returns (address);

  function coordinator () external view returns (address);

  function depositManager () external view returns (address);

  function borrowManager () external view returns (address);

  function stakingManager () external view returns (address);

  function feeManager () external view returns (address);

  function collateralizationManager () external view returns (address);

  function rewardManager () external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


interface IOracle
{
  function getConversionRate (address fromToken, address toToken) external view returns (uint256);

  function convertFromUSD (address toToken, uint256 amount) external view returns (uint256);

  function convertToUSD (address fromToken, uint256 amount) external view returns (uint256);

  function convert (address fromToken, address toToken, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


interface ITokenRegistry
{
  function isWhitelisted (address token) external view returns (bool);

  function isStable (address token) external view returns (bool);

  function isValidPair (address debtToken, address collateralToken) external view returns (bool);

  function getWhitelisted () external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


interface IStakingManager
{
  function isStakingForDeposits (address account) external view returns (bool);

  function isDiscountedForDeposits (address account) external view returns (bool);


  function isStakingForDebts (address account) external view returns (bool);

  function isDiscountedForDebts (address account) external view returns (bool);


  function increaseExpectedForDeposits (address depositor, uint256 depositInUSD, uint256 interestRate) external;

  function decreaseExpectedForDeposits (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;


  function increaseExpectedForDebts (address borrower, uint256 debtInUSD, uint256 dueTimestamp) external;

  function decreaseExpectedForDebts (address borrower, address debtToken, uint256 debt) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


struct Ratio
{
  uint256 init;
  uint256 liquidation;
}

interface ICollateralizationManager
{
  function getRatio (address token) external view returns (Ratio memory);

  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view returns (bool);

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view returns (bool, uint256);
}