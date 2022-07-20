// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import "../interfaces/IComptroller.sol";
import "../interfaces/IWrapper.sol";


contract CompoundLikeWrapper is IWrapper {
    IComptroller private immutable _comptroller;
    IERC20 private constant _BASE = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private immutable _cBase;

    mapping(IERC20 => IERC20) public cTokenToToken;
    mapping(IERC20 => IERC20) public tokenTocToken;

    constructor(IComptroller comptroller, IERC20 cBase) {
        _comptroller = comptroller;
        _cBase = cBase;
    }

    function addMarkets(ICToken[] memory markets) external {
        unchecked {
            for (uint256 i = 0; i < markets.length; i++) {
                (bool isListed, , ) = _comptroller.markets(markets[i]);
                require(isListed, "Market is not listed");
                IERC20 underlying = markets[i].underlying();
                cTokenToToken[markets[i]] = underlying;
                tokenTocToken[underlying] = markets[i];
            }
        }
    }

    function removeMarkets(ICToken[] memory markets) external {
        unchecked {
            for (uint256 i = 0; i < markets.length; i++) {
                (bool isListed, , ) = _comptroller.markets(markets[i]);
                require(!isListed, "Market is listed");
                IERC20 underlying = markets[i].underlying();
                delete cTokenToToken[markets[i]];
                delete tokenTocToken[underlying];
            }
        }
    }

    function wrap(IERC20 token) external view override returns (IERC20 wrappedToken, uint256 rate) {
        if (token == _BASE) {
            return (_cBase, 1e36 / ICToken(address(_cBase)).exchangeRateStored());
        } else if (token == _cBase) {
            return (_BASE, ICToken(address(_cBase)).exchangeRateStored());
        }
        IERC20 underlying = cTokenToToken[token];
        IERC20 cToken = tokenTocToken[token];
        if (underlying != IERC20(address(0))) {
            return (underlying, ICToken(address(token)).exchangeRateStored());
        } else if (cToken != IERC20(address(0))) {
            return (cToken, 1e36 / ICToken(address(cToken)).exchangeRateStored());
        } else {
            revert("Unsupported token");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import "./ICToken.sol";


interface IComptroller {
    function getAllMarkets() external view returns (ICToken[] memory);
    function markets(ICToken market) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWrapper {
    function wrap(IERC20 token) external view returns (IERC20 wrappedToken, uint256 rate);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICToken is IERC20 {
    function underlying() external view returns (IERC20 token);
    function exchangeRateStored() external view returns (uint256 exchangeRate);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}