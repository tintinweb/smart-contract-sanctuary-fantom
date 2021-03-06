/**
 *Submitted for verification at FtmScan.com on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IComptroller {
    function getAccountLiquidity(address account) view external returns (uint error, uint liquidity, uint shortfall);
    function closeFactorMantissa() view external returns (uint);
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount)
        external view returns (uint error , uint ctokenAmount);
    function getAssetsIn(address account) view external returns(address[] memory);
}

interface CToken {
    function borrowBalanceStored(address account) external view returns (uint);
    function balanceOf(address account) view external returns (uint);
    function underlying() view external returns(address);
    function decimals() view external returns(uint8);
    function exchangeRateStored() external view returns (uint);
}

interface BAMMLike {
    function LUSD() view external returns(uint);
    function cBorrow() view external returns(address);
    function cTokens(address a) view external returns(bool);
}

contract CLiquidationBotHelper {
    struct Account {
        address account;
        address bamm;
        address ctoken;
        uint repayAmount;
        bool underwater;
    }

    function getAccountInfo(address account, IComptroller comptroller, BAMMLike bamm) public view returns(Account memory a) {
        address[] memory ctokens = comptroller.getAssetsIn(account);

        CToken cBorrow = CToken(bamm.cBorrow());
        uint repayAmount = cBorrow.borrowBalanceStored(account) * comptroller.closeFactorMantissa() / 1e18;                
        uint bammBalance = CToken(cBorrow).balanceOf(address(bamm)) * CToken(cBorrow).exchangeRateStored() / 1e18;
        uint decimals = CToken(cBorrow.underlying()).decimals();
        if(repayAmount > bammBalance) repayAmount = bammBalance;
        if(repayAmount == 0) return a;

        a.account = account;
        a.bamm = address(bamm);
        a.repayAmount = 0;

        uint orgRepayAmount = repayAmount;

        for(uint i = 0; i < ctokens.length ; i++) {
            repayAmount = orgRepayAmount;

            address ctoken = ctokens[i];

            if((! bamm.cTokens(ctoken)) && (ctoken != address(cBorrow))) continue;
            CToken cETH = CToken(ctoken);
                
            uint cETHBalance = cETH.balanceOf(account);
            if(cETHBalance == 0) continue;

            (uint err, uint cETHAmount) = comptroller.liquidateCalculateSeizeTokens(address(cBorrow), address(cETH), repayAmount);

            if(cETHAmount == 0 || err != 0) continue;

            if(cETHBalance < cETHAmount) {
                repayAmount = cETHBalance * repayAmount / cETHAmount;
            }

            // dust
            if(repayAmount < (10 ** (decimals - 1))) continue;

            // get the collateral with the highest deposits
            if(repayAmount > a.repayAmount) {
                a.repayAmount = repayAmount;
                a.ctoken = ctoken;
            }
        }
    } 

    function getInfo(address[] memory accounts, address comptroller, address[] memory bamms) public view returns(Account[] memory unsafeAccounts) {
        if(accounts.length == 0) return unsafeAccounts;

        Account[] memory actions = new Account[](accounts.length);
        uint numUnsafe = 0;
        
        for(uint i = 0 ; i < accounts.length ; i++) {
            (uint err,, uint shortfall) = IComptroller(comptroller).getAccountLiquidity(accounts[i]);
            if(shortfall == 0 || err != 0) continue;

            Account memory a;

            for(uint j = 0 ; j < bamms.length ; j++) {
                a = getAccountInfo(accounts[i], IComptroller(comptroller), BAMMLike(bamms[j]));
                if(a.repayAmount > 0) {
                    actions[numUnsafe++] = a;
                    break;
                }

                a.underwater = true;                
            }
        }

        unsafeAccounts = new Account[](numUnsafe);
        for(uint k = 0 ; k < numUnsafe ; k++) {
            unsafeAccounts[k] = actions[k];
        }
    }
}