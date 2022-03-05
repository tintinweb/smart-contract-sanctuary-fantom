// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "IERC20.sol";

interface VaultAPI is IERC20 {
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
}

contract yearnIntegrator {
    address public admin;
    string public name;

    constructor() {
        admin = msg.sender;
        name = "YearnIntegrator";
    }

    VaultAPI vaultDAI = VaultAPI(0x637eC617c86D24E421328e6CAEa1d92114892439);

    VaultAPI vaultUSDT = VaultAPI(0x148c05caf1Bb09B5670f00D511718f733C54bC4c);

    address public DAIaddress = vaultDAI.token();
    address public USDTaddress = vaultUSDT.token();

    IERC20 DAI = IERC20(DAIaddress);

    IERC20 USDT = IERC20(USDTaddress);

    function investDAI(address _depositer, uint256 _amount) external {
        DAI.transferFrom(_depositer, address(this), _amount);
        DAI.approve(address(vaultDAI), 0);
        DAI.approve(address(vaultDAI), _amount);
        vaultDAI.deposit(_amount, address(this));
    }

    function investUSDT(address _depositer, uint256 _amount) external {
        USDT.transferFrom(_depositer, address(this), _amount);
        USDT.approve(address(vaultUSDT), 0);
        USDT.approve(address(vaultUSDT), _amount);
        vaultUSDT.deposit(_amount, address(this));
    }

    function priceDAI() external view returns (uint256) {
        return vaultDAI.pricePerShare();
    }

    function priceUSDT() external view returns (uint256) {
        return vaultUSDT.pricePerShare();
    }

    function withdrawDAI(uint256 _amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        vaultDAI.withdraw(_amount, admin);
    }

    function withdrawAllDAI() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 amount = vaultDAI.balanceOf(address(this));
        vaultDAI.withdraw(amount, admin);
    }

    function withdrawUSDT(uint256 _amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        vaultUSDT.withdraw(_amount, admin);
    }

    function withdrawAllUSDT() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 amount = vaultUSDT.balanceOf(address(this));
        vaultUSDT.withdraw(amount, admin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals in contract.
     */
    function decimals() external view returns (uint256);

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