// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Ownable } from "../roles/Ownable.sol";
import { IContractRegistry } from "../interfaces/IContractRegistry.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IStakingManager } from "../interfaces/IStakingManager.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";


contract FeeManager is IFeeManager, Ownable
{
  IContractRegistry private constant _REGISTRY = IContractRegistry(0x06Eeb1B35361687f10909902AD4704AC7d09e0E7);

  uint256 private constant _DECIMALS = 1e18;
  uint256 private constant _BASIS_POINT = 10000;


  struct Fee
  {
    uint256 deposit;
    uint256 borrow;
    uint256 defaulted;
  }

  Fee private _fee;
  address private _burner;


  event NewBurner(address burner);
  event NewFee(uint256 deposit, uint256 borrow, uint256 defaulted);


  function updateFee (Fee calldata fee) external onlyOwner
  {
    require(fee.deposit > 0 && fee.borrow > 0 && fee.defaulted > 0, "!valid values");
    require(fee.deposit <= 1500 && fee.borrow <= 125 && fee.defaulted <= 700, "high");


    _fee = fee;


    emit NewFee(fee.deposit, fee.borrow, fee.defaulted);
  }

  function getFee () external view returns (Fee memory)
  {
    return _fee;
  }

  function getBurner () external view override returns (address)
  {
    return _burner;
  }

  function setBurner (address burner) external onlyOwner
  {
    require(burner != address(0), "0 addr");


    _burner = burner;


    emit NewBurner(burner);
  }


  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }


  function calcDepositFeeOnInterest (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external view returns (uint256)
  {
    uint256 interest = _calcPercentOf(deposit, interestRate);
    uint256 oneUSDOfDepositToken = IOracle(_REGISTRY.oracle()).convertFromUSD(depositToken, 1e18);

    uint256 fee = _calcPercentOf(interest, IStakingManager(_REGISTRY.stakingManager()).isDiscountedForDeposits(depositor) ? _calcPercentOf(_fee.deposit, 7500) : _fee.deposit);


    return Math.max(fee, oneUSDOfDepositToken);
  }

  function calcBorrowFeeOnDebt (address borrower, address debtToken, uint256 debt, address collateralToken) external view returns (uint256)
  {
    uint256 fee = IStakingManager(_REGISTRY.stakingManager()).isDiscountedForDebts(borrower) ? _calcPercentOf(_fee.borrow, 7500) : _fee.borrow;


    return _calcPercentOf(IOracle(_REGISTRY.oracle()).convert(debtToken, collateralToken, debt), fee);
  }


  function getDepositFeeOnInterest (uint256 deposit, uint256 depositInUSD, uint256 interest, bool isDiscountedForDeposits) external view override returns (uint256, address)
  {
    uint256 oneUSDOfDepositToken = (deposit * _DECIMALS) / depositInUSD;

    uint256 fee = _calcPercentOf(interest, isDiscountedForDeposits ? _calcPercentOf(_fee.deposit, 7500) : _fee.deposit);


    return (Math.max(fee, oneUSDOfDepositToken), _burner);
  }

  function getBorrowFeeOnDebt (uint256 debtInCollateralToken, bool isDiscountedForDebts) external view override returns (uint256, address)
  {
    return (_calcPercentOf(debtInCollateralToken, isDiscountedForDebts ? _calcPercentOf(_fee.borrow, 7500) : _fee.borrow), _burner);
  }

  function getDefaultFee (uint256 collateral) external view override returns (uint256, address)
  {
    return (_calcPercentOf(collateral, _fee.defaulted), _burner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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


interface IFeeManager
{
  function getBurner () external view returns (address);

  function getDefaultFee (uint256 collateral) external view returns (uint256, address);

  function getDepositFeeOnInterest (uint256 deposit, uint256 depositInUSD, uint256 interest, bool isDiscountedForDeposits) external view returns (uint256, address);

  function getBorrowFeeOnDebt (uint256 debtInCollateralToken, bool isDiscountedForDebts) external view returns (uint256, address);
}