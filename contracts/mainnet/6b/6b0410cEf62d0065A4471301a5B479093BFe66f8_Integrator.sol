// SPDX-License-Identifier: unlicenced

pragma solidity ^0.6.0;

import "IERC20.sol";
import "VaultAPI.sol";

contract Integrator {
    // some functions can only be performed by admin.
    address public admin;

    // constructor is used to set the admin.
    // address from which th e contract is deployed will become the admin.
    constructor() public {
        admin = msg.sender;
    }

    // There are many vaults corresponding to the DAI.
    // some of these vaults are not being used by any strategy.
    // There is a registery contract to get the address of the latest vault.
    // Address of this registery contract is not available. Hence address of latest vault is hard-coded.

    // Intializing the vault contract
    VaultAPI vaultDAI = VaultAPI(0x637eC617c86D24E421328e6CAEa1d92114892439);

    VaultAPI vaultUSDT = VaultAPI(0x148c05caf1Bb09B5670f00D511718f733C54bC4c);

    VaultAPI vaultUSDC = VaultAPI(0xEF0210eB96c7EB36AF8ed1c20306462764935607);

    //Initializing the DAI/USDT/USDC contract
    IERC20 DAI = IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);

    IERC20 USDT = IERC20(0x049d68029688eAbF473097a2fC38ef61633A3C7A);

    IERC20 USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);

    //before calling the invest function, the user needs to give appproval to this contract to spend from their wallet.

    function investDAI(address _depositer, uint256 _amount) external {
        DAI.transferFrom(_depositer, address(this), _amount);
        DAI.approve(address(vaultDAI), _amount);
        vaultDAI.deposit(_amount, address(this));
    }

    // This function can only be called by the admin.
    // all of the available balance will be withdrawn from the vault.
    function withdrawDAI() external {
        require(
            msg.sender == admin,
            "Only admin can perform the withdraw function"
        );
        uint256 balance = vaultDAI.balanceOf(address(this));
        vaultDAI.withdraw(balance, admin);
    }

    function investUSDT(address _depositer, uint256 _amount) external {
        USDT.transferFrom(_depositer, address(this), _amount);
        USDT.approve(address(vaultUSDT), _amount);
        vaultUSDT.deposit(_amount, address(this));
    }

    function withdrawUSDT() external {
        require(
            msg.sender == admin,
            "Only admin can perform the withdraw function"
        );
        uint256 balance = vaultUSDT.balanceOf(address(this));
        vaultUSDT.withdraw(balance, admin);
    }

    function investUSDC(address _depositer, uint256 _amount) external {
        USDC.transferFrom(_depositer, address(this), _amount);
        USDC.approve(address(vaultUSDC), _amount);
        vaultUSDC.deposit(_amount, address(this));
    }

    function withdrawUSDC() external {
        require(
            msg.sender == admin,
            "Only admin can perform the withdraw function"
        );
        uint256 balance = vaultUSDC.balanceOf(address(this));
        vaultUSDC.withdraw(balance, admin);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import "IERC20.sol";

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}