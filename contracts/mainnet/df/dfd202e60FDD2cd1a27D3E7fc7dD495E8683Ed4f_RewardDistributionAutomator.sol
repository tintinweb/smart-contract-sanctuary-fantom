// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
interface SpookySwap {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract RewardDistributionAutomator is Ownable {
    // Addresses
    address immutable EASY_BACKUP = 0x164E51048dE21EcF9E4C42399145c7fE7DA2Fb19;
    address immutable SPOOKY_SWAP = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d;
    address immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address immutable EASY = 0x26A0D46A4dF26E9D7dEeE9107a27ee979935F237;
    address immutable WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address xEasy = 0x5Cd9C4bcFDa86dd4C13AF8B04B30B4D8651F2D7C;
    address vip = 0xF719e950FD6F280EB76D220480e816ff9C216E19;
    // Contracts
    SpookySwap spookySwapContract;
    IERC20 usdcContract;
    IERC20 easyContract;

    constructor() {
        spookySwapContract = SpookySwap(SPOOKY_SWAP);
        usdcContract = IERC20(USDC);
        easyContract = IERC20(EASY);
    }

    // Methods
    function buyEasy() internal {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = USDC;
        path[2] = EASY;
        spookySwapContract.swapExactETHForTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function distributeEasy() internal {
        uint256 easyBalance = easyContract.balanceOf(address(this));
        easyContract.transfer(vip, easyBalance / 10);
        easyContract.transfer(xEasy, (easyBalance / 10) * 9);
    }

    function processRewards() internal {
        buyEasy();
        distributeEasy();
    }

    // Chainlink Automation
    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = address(this).balance > 0;
    }

    function performUpkeep(bytes calldata /* performData */) external {
        if (address(this).balance > 0) {
            processRewards();
        }
    }

    // Manager Functions
    function setXEasy(address _xEasy) external onlyOwner {
        xEasy = _xEasy;
    }

    function setVip(address _vip) external onlyOwner {
        vip = _vip;
    }

    // Recieve & Fallback
    receive() external payable {}

    fallback() external payable {}
}