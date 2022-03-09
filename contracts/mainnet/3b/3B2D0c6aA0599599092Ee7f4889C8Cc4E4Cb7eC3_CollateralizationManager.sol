// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import { Ownable } from "../roles/Ownable.sol";
import { IContractRegistry } from "../interfaces/IContractRegistry.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { ITokenRegistry } from "../interfaces/ITokenRegistry.sol";
import { IStakingManager } from "../interfaces/IStakingManager.sol";
import { Ratio, ICollateralizationManager } from "../interfaces/ICollateralizationManager.sol";


contract CollateralizationManager is ICollateralizationManager, Ownable
{
  IContractRegistry private constant _REGISTRY = IContractRegistry(0x06Eeb1B35361687f10909902AD4704AC7d09e0E7);
  address private constant _KAE = 0x65Def5029A0e7591e46B38742bFEdd1Fb7b24436;

  uint256 private constant _BASIS_POINT = 10000;


  mapping(address => Ratio) private _ratio;

  event NewRatio(address token, uint256 init, uint256 liquidation);


  function getRatio (address token) external view override returns (Ratio memory)
  {
     return _ratio[token];
  }

  function setRatios (address[] calldata tokens, Ratio[] calldata ratios) external onlyOwner
  {
    require(tokens.length == ratios.length, "!=");


    for (uint256 i = 0; i < ratios.length; i++)
    {
      Ratio memory ratio = ratios[i];
      address token = tokens[i];

      require(token != address(0), "0 addr");
      require(ratio.init >= 13000, "!valid init");
      require(ratio.liquidation >= 12500 && ratio.liquidation < ratio.init && ratio.liquidation <= 14500, "!valid liq");


      _ratio[token] = ratio;


      emit NewRatio(token, ratio.init, ratio.liquidation);
    }
  }


  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }


  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view override returns (bool)
  {
    require(debtToken != _KAE && debtToken != collateralToken && ITokenRegistry(tokenRegistry).isValidPair(debtToken, collateralToken), "!valid pair");


    return collateral >= _calcPercentOf(debtInCollateralToken, _ratio[collateralToken].init);
  }

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view override returns (bool, uint256)
  {
    uint256 ratio = _ratio[collateralToken].liquidation;

    if (IStakingManager(_REGISTRY.stakingManager()).isDiscountedForDebts(borrower) && !ITokenRegistry(_REGISTRY.tokenRegistry()).isStable(collateralToken))
    {
      ratio -= _calcPercentOf(ratio, 350);
    }


    uint256 debtInCollateralTokenAtLiqRatio = IOracle(_REGISTRY.oracle()).convert(debtToken, collateralToken, _calcPercentOf(debt, ratio));


    return (collateral > debtInCollateralTokenAtLiqRatio, (collateral / (debtInCollateralTokenAtLiqRatio / ratio) ));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


contract Ownable
{
  bool private _delaying;

  address private _owner;
  address private _newOwner;

  uint256 private _transferableTimestamp;


  event InitiateTransfer(address indexed currentOwner, address indexed newOwner, uint256 transferableTimestamp);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event CancelTransfer();


  modifier onlyOwner ()
  {
    require(msg.sender == _owner, "!owner");
    _;
  }

  constructor ()
  {
    _owner = msg.sender;


    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner () public view returns (address)
  {
    return _owner;
  }

  function transferInfo () public view returns (bool, address, uint256)
  {
    return (_delaying, _newOwner, _transferableTimestamp);
  }


  function renounceOwnership () public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));


    _owner = address(0);
  }


  function activateDelay () public onlyOwner
  {
    require(!_delaying, "delaying");


    _delaying = true;
  }

  function initiateTransfer (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");
    require(_transferableTimestamp == 0, "transferring");


    _newOwner = newOwner;
    _transferableTimestamp = block.timestamp + 2 days;


    emit InitiateTransfer(msg.sender, newOwner, _transferableTimestamp);
  }

  function cancelTransfer () public onlyOwner
  {
    require(_transferableTimestamp != 0, "!transferring");


    _transferableTimestamp = 0;
    _newOwner = address(0);


    emit CancelTransfer();
  }

  function transferOwnership (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");


    if (_delaying)
    {
      require(newOwner == _newOwner, "!=");
      require(_transferableTimestamp > 0 && block.timestamp > _transferableTimestamp, "!transferable");


      _transferableTimestamp = 0;
      _newOwner = address(0);
    }


    emit OwnershipTransferred(_owner, newOwner);


    _owner = newOwner;
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