/**
 *Submitted for verification at FtmScan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface Cauldron {
    function userBorrowPart(address user) external view returns (uint256);
    function userCollateralShare(address user) external view returns (uint256);
    function totalBorrow() external view returns (uint128 elastic, uint128 base);
}

interface BentoBox {
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
}

interface Oracle {
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);
}

interface WrappedSPA is IERC20 {
    function wOHMTosOHM(uint256 amount) external view returns (uint256);
}

contract SpartacadabraHelper {

    Cauldron private constant CAULDRON = Cauldron(0x878c92A99cc335310710C239BD9808A6F57d5Ea4);
    BentoBox private constant BENTO_BOX = BentoBox(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    WrappedSPA private constant WRAPPED_SPA = WrappedSPA(0x89346B51A54263cF2e92dA79B1863759eFa68692);
    uint256 private constant COLLATERIZATION_RATE = 75000;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;
    
    Oracle private constant ORACLE = Oracle(0xe808B63ECf9397c1A61aBf1f7f7B62b9B9B7286e);
    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    function getHealthyCollateralSPA(address user) public view returns (uint256 collateralSPA) {
        uint256 collateralShare = CAULDRON.userCollateralShare(user);
        if (collateralShare == 0) {
            return 0;
        }
        
        (bool success, uint256 exchangeRate) = ORACLE.peek(new bytes(0)); // Parameter "data" is unused in the oracle code
        require(success, "Oracle query failed");
        if (!isSolvent(user, collateralShare, exchangeRate)) {
            return 0;
        }

        return WRAPPED_SPA.wOHMTosOHM(collateralShare);
    }

    // Adapted from cauldron contract at line 957
    function isSolvent(address user, uint collateralShare, uint256 exchangeRate) internal view returns (bool) {
        uint256 borrowPart = CAULDRON.userBorrowPart(user);
        if (borrowPart == 0) {
            return true;
        }

        (uint128 elastic, uint128 base) = CAULDRON.totalBorrow();

        return
            BENTO_BOX.toAmount(
                WRAPPED_SPA,
                collateralShare * (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION) * COLLATERIZATION_RATE,
                false
            ) >=
            borrowPart * elastic * exchangeRate / base;
    }

}