// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreSaleICO is Ownable {
    struct Sale {
        address investor;
        uint quantity;
        uint256 monthlyRelease;
    }
    Sale[] private sales;
    mapping(address => bool) public investors;
    IERC20 internal token;
    // tether
    IERC20 internal firstPeggedToken;
    // usdc
    IERC20 internal secondPeggedToken;
    bool public end;
    uint256 public endTime;
    uint internal price;
    uint public tokensSold;
    uint internal minPurchase;
    bool internal withdrawn;
    uint256 internal releaseCount;

    constructor(
        IERC20 _token,
        IERC20 _firstPeggedToken,
        IERC20 _secondPeggedToken
    ) {
        token = _token;
        firstPeggedToken = _firstPeggedToken;
        secondPeggedToken = _secondPeggedToken;
        releaseCount = 10;
        end = true;
    }

    modifier icoActive() {
        require(end == false, "ICO must be active");
        _;
    }

    modifier icoNotActive() {
        require(end == true && endTime == 0, "ICO should not be active.");
        _;
    }

    modifier icoEnded() {
        require(
            (end == true && endTime > 0) || token.balanceOf(address(this)) == 0,
            "ICO must have ended."
        );
        _;
    }

    modifier tokensNotReleased() {
        require(releaseCount > 0, "Already released.");
        _;
    }

    modifier notWithdrawn() {
        require(withdrawn == false, "Already Withdrawn.");
        _;
    }

    modifier onlyInvestors() {
        require(investors[msg.sender] == true, "only investors");
        _;
    }

    function start() external onlyOwner icoNotActive {
        require(
            token.balanceOf(address(this)) >= 10000000 * 1e18,
            "Not Enough tokens to start ICO."
        );
        end = false;
        price = 700000; // 1 = 1000000 so 0.7 = 700000
        // conversion => 1 *10 * 18 ICO'edToken = 500000 peggedToken
        minPurchase = 10000000;
    }

    function whitelistInvestor(address[] memory investorsAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < investorsAddresses.length; i++) {
            investors[investorsAddresses[i]] = true;
        }
    }

    function buy(uint256 peggedTokenAmount, bool peggedBool)
        external
        onlyInvestors
        icoActive
    {
        //  true for usdt; false for usdc
        if (peggedBool) {
            require(
                firstPeggedToken.balanceOf(msg.sender) >= peggedTokenAmount,
                "Not Enough Balance."
            );
        } else {
            require(
                secondPeggedToken.balanceOf(msg.sender) >= peggedTokenAmount,
                "Not Enough Balance."
            );
        }
        require(
            peggedTokenAmount >= minPurchase,
            "Amount is less than the minimum Purchase."
        );
        uint256 quantity = peggedTokenAmount / price;
        quantity = quantity * 10**18;
        uint256 monthlyReleaseAmount = quantity / 10;
        uint256 totalQuantity = tokensSold + quantity;
        require(
            totalQuantity <= token.balanceOf(address(this)),
            "Not enough tokens left for sale"
        );
        tokensSold += quantity;
        // BUYER SHOULD APPROVE FIRST
        if (peggedBool) {
            firstPeggedToken.transferFrom(
                msg.sender,
                address(this),
                peggedTokenAmount
            );
        } else {
            secondPeggedToken.transferFrom(
                msg.sender,
                address(this),
                peggedTokenAmount
            );
        }
        sales.push(Sale(msg.sender, quantity, monthlyReleaseAmount));
    }

    function release() external onlyOwner icoEnded tokensNotReleased {
        require(
            block.timestamp >=
                endTime + (10 * 4 weeks - releaseCount * 4 weeks),
            "TimeLock: Released Time not reached yet."
        );
        for (uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            token.transfer(sale.investor, sale.monthlyRelease);
        }
        releaseCount -= 1;
    }

    function endSale() external onlyOwner {
        end = true;
        endTime = block.timestamp;
    }

    function withdraw() external onlyOwner icoEnded notWithdrawn {
        firstPeggedToken.transfer(
            owner(),
            firstPeggedToken.balanceOf(address(this))
        );
        secondPeggedToken.transfer(
            owner(),
            secondPeggedToken.balanceOf(address(this))
        );
        token.transfer(owner(), token.balanceOf(address(this)));
        withdrawn = true;
    }
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