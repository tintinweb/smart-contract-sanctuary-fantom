// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivateSaleICO is Ownable {
    struct investmentRecord {
        uint256 quantity;
        uint256 monthlyRelease;
    }
    mapping(address => bool) private investors;
    mapping(address => investmentRecord) public investmentRecords;
    mapping(address => uint256) public referalEarnings;
    address[] private UsersWhoInvested;
    uint256 internal privateSale;
    uint256 internal price;
    uint256 public endTime;
    uint256 public referalEndtime;
    uint256 public tokensSold;
    uint256 internal minPurchase;
    uint256 internal releaseCount;
    IERC20 internal token;
    // tether
    IERC20 internal firstPeggedToken;
    // usdc
    IERC20 internal secondPeggedToken;
    bool public end;
    bool internal withdrawn;

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

    function start() external onlyOwner icoNotActive {
        require(
            token.balanceOf(address(this)) >= 10000000 * 1e18,
            "Not Enough tokens to start ICO."
        );
        end = false;
        referalEndtime = block.timestamp + 2 weeks;
        price = 500000; // 1 = 1000000 so 0.5 = 500000
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

    function rewardAndReferalCalc(uint256 Amount)
        internal
        view
        returns (uint256 value)
    {
        uint256 timePeriod;
        if (block.timestamp > referalEndtime) {
            timePeriod = (block.timestamp - referalEndtime) / 1 weeks;
        }
        if (Amount > 100 && Amount <= 200) {
            return timePeriod < 2 ? 1 - timePeriod : 0;
        }
        if (Amount > 200 && Amount <= 300) {
            return timePeriod < 3 ? 2 - timePeriod : 0;
        }
        if (Amount > 300 && Amount <= 400) {
            return timePeriod < 4 ? 3 - timePeriod : 0;
        }
        if (Amount > 400 && Amount <= 500) {
            return timePeriod < 5 ? 4 - timePeriod : 0;
        }
        if (Amount > 500 && Amount <= 2000) {
            return timePeriod < 6 ? 5 - timePeriod : 0;
        }
        if (Amount > 2000) {
            return timePeriod < 11 ? 10 - timePeriod : 0;
        } else {
            return 0;
        }
    }

    function buy(
        uint256 peggedTokenAmount,
        address referalAddress,
        bool peggedBool
    ) external icoActive {
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
        uint256 referalReward;
        uint256 quantity = peggedTokenAmount / price;
        if (referalAddress != address(0)) {
            require(
                referalAddress != msg.sender,
                "You can not Refer Your own Address."
            );
            if (investors[referalAddress]) {
                referalReward += (quantity / 100) * 10;
                if (
                    investmentRecords[referalAddress].quantity == 0 &&
                    referalEarnings[referalAddress] == 0
                ) {
                    UsersWhoInvested.push(referalAddress);
                }
            } else {
                require(
                    investmentRecords[referalAddress].quantity >= 100 * 1e18,
                    "Invaid Referal Address."
                );
                referalReward +=
                    (quantity / 100) *
                    rewardAndReferalCalc(
                        investmentRecords[referalAddress].quantity / 1e18
                    );
            }
            referalEarnings[referalAddress] += referalReward;
        }
        quantity = quantity * 1e18;
        uint256 totalQuantity = tokensSold + quantity;
        require(
            totalQuantity <= token.balanceOf(address(this)),
            "Not enough tokens left for sale"
        );
        uint256 rewardQuantity = (quantity / 100) *
            rewardAndReferalCalc(peggedTokenAmount / 1e6);
        if (investmentRecords[msg.sender].quantity == 0) {
            UsersWhoInvested.push(msg.sender);
        }
        investmentRecords[msg.sender].quantity += (quantity + rewardQuantity);
        investmentRecords[msg.sender].monthlyRelease +=
            (quantity + rewardQuantity) /
            10;
        tokensSold += (quantity + rewardQuantity);
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
    }

    function release() external onlyOwner icoEnded tokensNotReleased {
        require(
            block.timestamp >=
                (endTime + 6 * 4 weeks) +
                    (10 * 4 weeks - releaseCount * 4 weeks),
            "TimeLock: Released Time not reached yet."
        );
        uint256 referalReward;
        for (uint i = 0; i < UsersWhoInvested.length; i++) {
            address user = UsersWhoInvested[i];
            if (releaseCount == 10) {
                referalReward = 0;
                referalReward = referalEarnings[user] * 1e18;
            }
            uint256 userReleaseAmount = investmentRecords[user].monthlyRelease +
                referalReward;
            if (userReleaseAmount > 0) {
                token.transfer(user, userReleaseAmount);
            }
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