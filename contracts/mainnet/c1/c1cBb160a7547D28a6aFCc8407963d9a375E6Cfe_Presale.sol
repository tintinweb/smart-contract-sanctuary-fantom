// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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
//////

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IContractProvider {
    function AllCrewBounties() external view returns (address[] memory);

    function areTokensLaunched() external view returns (bool);
}

contract Presale is Ownable {
    IERC20[] public tokens;
    mapping(address => mapping(IERC20 => uint256)) public balances;
    mapping(address => bool) public whitelist;

    IContractProvider public provider;

    uint256 public rate = 20; // User gets 0.5% of each token for 0.1 ETH
    uint256 public ethAmount = 0.1 ether;

    event Purchased(address indexed buyer, uint256 amount);

    function setProvider(IContractProvider _provider) external onlyOwner {
        provider = _provider;
    }

    function setTokens() external onlyOwner {
        require(address(provider) != address(0), "Provider is not set");
        address[] memory addresses = provider.AllCrewBounties();
        for (uint256 i = 0; i < addresses.length; i++) {
            tokens.push(IERC20(addresses[i]));
        }
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function setEthAmount(uint256 _ethAmount) public onlyOwner {
        ethAmount = _ethAmount;
    }

    function purchase() external payable {
        require(address(provider) != address(0), "Provider is not set");
        require(whitelist[msg.sender], "You are not on the whitelist");
        require(msg.value == ethAmount, "Incorrect amount of ETH sent");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokensToBuy = ethAmount * rate;
            require(
                tokens[i].balanceOf(address(this)) >= tokensToBuy,
                "Not enough tokens in the contract"
            );

            balances[msg.sender][tokens[i]] += tokensToBuy;

            emit Purchased(msg.sender, tokensToBuy);
        }
    }

    function getTokensToClaim(
        address user
    ) external view returns (IERC20[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = balances[user][tokens[i]];
        }

        return (tokens, amounts);
    }

    function claim() external {
        require(provider.areTokensLaunched(), "Tokens are not launched yet");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = balances[msg.sender][tokens[i]];
            require(balance > 0, "No tokens to claim");

            balances[msg.sender][tokens[i]] = 0;
            tokens[i].transfer(msg.sender, balance);
        }
    }

    function withdrawETHtoFactory() external onlyOwner {
        require(address(provider) != address(0), "Provider is not set");
        payable(address(provider)).transfer(address(this).balance);
    }

    function withdrawUnsoldTokensToFactory() external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
        uint256 balance = tokens[i].balanceOf(address(this));
        if (balance > 0) {
            tokens[i].transfer(address(provider), balance);
        }
    }
}

}