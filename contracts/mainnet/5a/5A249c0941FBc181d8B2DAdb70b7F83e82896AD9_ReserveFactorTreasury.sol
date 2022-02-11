// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Errors} from './Errors.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {ILendingPool} from './ILendingPool.sol';
import {IAToken} from './IAToken.sol';
import {IERC20} from './IERC20.sol';
import {DataTypes} from './DataTypes.sol';
import {Context} from './Context.sol';
import {Ownable} from './Ownable.sol';


contract ReserveFactorTreasury is Ownable {
  ILendingPoolAddressesProvider public ADDRESSES_PROVIDER;
  ILendingPool public LENDING_POOL;
  address private currentTreasury = address(this);
  address private multisig;

  modifier onlyPoolAdmin {
    require(ADDRESSES_PROVIDER.getPoolAdmin() == _msgSender(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  constructor (
    ILendingPoolAddressesProvider provider
  ) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    multisig = _msgSender();
  }

  function withdrawAllReserves() external returns (bool) {
    withdrawReserves(LENDING_POOL.getReservesList());
    return true;
  }

  function withdrawReserves(address[] memory assets) public returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveData memory reserveData = LENDING_POOL.getReserveData(assets[i]);
      uint256 balance = IAToken(reserveData.aTokenAddress).balanceOf(address(this));
      if (balance != 0) {
        LENDING_POOL.withdraw(assets[i], balance, currentTreasury);
      }
    }
    return true;
  }

  function transferToMultisig(address asset, uint256 value) external onlyOwner {
    IERC20(asset).transfer(multisig, value);
  }

  function setTreasury(address newTreasury) external onlyPoolAdmin {
    currentTreasury = newTreasury;
  }

  function setMultisig(address newMultisig) external onlyOwner {
    multisig = newMultisig;
  }
}