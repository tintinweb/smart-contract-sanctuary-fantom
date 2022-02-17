// SPDX-License-Identifier: MIT
import "IERC20.sol";
import "MatrixVault.sol";
import "MatrixStrategy.sol";

pragma solidity ^0.6.0;

contract MatrixProxy {
    // returning want, pricePerFullShare, balance, balanceOfUser, allowanceOfUser
    function getInfo(address _vault, address _strategy, address _zap) public view returns (IERC20, uint256, uint256, uint256, uint256) {
        MatrixVault vault = MatrixVault(_vault);
        
        IERC20 want = vault.want();
        uint256 pricePerFullShare = vault.getPricePerFullShare();
        uint256 balance = vault.balance();
        uint256 balanceOfUser = vault.balanceOf(msg.sender);
        uint256 allowanceOfUser = vault.allowance(msg.sender, _zap);

        return (want, pricePerFullShare, balance, balanceOfUser, allowanceOfUser);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
import "IERC20.sol";

pragma solidity ^0.6.0;

interface MatrixVault {
    function want() external view returns (IERC20);

    function getPricePerFullShare() external view returns (uint256);

    function available() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
import "IERC20.sol";

pragma solidity ^0.6.0;

interface MatrixStrategy {
    function vault() external view returns (address);

    function want() external view returns (IERC20);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function harvest() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}