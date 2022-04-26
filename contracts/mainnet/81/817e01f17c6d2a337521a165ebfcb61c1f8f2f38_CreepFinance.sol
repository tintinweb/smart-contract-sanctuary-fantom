/**
 *Submitted for verification at FtmScan.com on 2022-04-26
*/

// SPDX-License-Identifier: MIT
// dev address is 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D
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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/CreepFinance.sol

pragma solidity ^0.8.0;

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract CreepFinance is Ownable, ReentrancyGuard {
    uint256 public fee = 5; // 5% fee for 2% burning, 1% gas(0.1 % for odd one), 2% team
    uint256 public lockedPeriod = 5 minutes; // can not enter at last 5 mins
    address public devWallet = 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D;
    address public founderWallet = 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D;
    address public virtualFTMaddress =
        0x0000000000000000000000000000000000000000;
    address[] public aggregators;
    struct Pool {
        bytes32 seedHash;
        address tokenAddress;
        uint256 tokenAmount;
        uint128 period;
        uint128 updatedAt;
        bool burning;
        address[] players;
    }

    Pool[] public pools;
    mapping(address => mapping(address => uint256)) userBalance;

    constructor() {}

    /**
     * Returns the latest price
     */
    function getLatestPrice(address aggregator) internal view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregator);
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function setAggregators(address[] memory _aggregators) external onlyOwner {
        aggregators = _aggregators;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 5, "exceed limit");
        require(_fee > 2, "minimum fee");
        fee = _fee;
    }

    function setDevWallet(address _new) external {
        require(msg.sender == devWallet, "Only dev");
        devWallet = _new;
    }

    function setFounderWallet(address _new) external {
        require(msg.sender == founderWallet, "Only founder");
        founderWallet = _new;
    }

    function addPool(
        bytes32 _seedHash,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint128 _period,
        bool _burning
    ) external onlyOwner {
        address[] memory empty;
        Pool memory newPool = Pool(
            _seedHash,
            _tokenAddress,
            _tokenAmount,
            _period,
            uint128(block.timestamp),
            _burning,
            empty
        );
        pools.push(newPool);
    }

    function updatePoolPeriod(uint128 _period, uint256 index)
        external
        onlyOwner
    {
        pools[index].period = _period;
    }

    function enter(uint256 index) external nonReentrant {
        require(index < pools.length, "not exiting pool");
        require(
            block.timestamp <
                pools[index].updatedAt + pools[index].period - lockedPeriod,
            "locking time"
        );
        for (uint256 i = 0; i < pools[index].players.length; i++) {
            require(msg.sender != pools[index].players[i], "double enter");
        }
        require(
            userBalance[msg.sender][pools[index].tokenAddress] >=
                pools[index].tokenAmount,
            "Not enough balance"
        );
        userBalance[msg.sender][pools[index].tokenAddress] -= pools[index]
            .tokenAmount;
        pools[index].players.push(msg.sender);
    }

    function deposit(address _tokenAddress, uint256 _amount) external {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        userBalance[msg.sender][_tokenAddress] += _amount;
    }

    function depositFTM() external payable {
        userBalance[msg.sender][virtualFTMaddress] += msg.value;
    }

    function withdraw(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
    {
        require(
            userBalance[msg.sender][_tokenAddress] >= _amount,
            "exceed amount"
        );
        userBalance[msg.sender][_tokenAddress] -= _amount;
        if (_tokenAddress == virtualFTMaddress)
            IERC20(_tokenAddress).transferFrom(
                address(this),
                msg.sender,
                _amount
            );
        else {
            (bool sent, ) = msg.sender.call{value: _amount}("");
            require(sent, "Ether not sent");
        }
    }

    function withdrawAllFund() external nonReentrant {
        for (uint256 i = 0; i < pools.length; i++) {
            address _tokenAddress = pools[i].tokenAddress;
            uint256 _amount = userBalance[msg.sender][_tokenAddress];
            userBalance[msg.sender][_tokenAddress] = 0;
            if (_amount >= 0)
                IERC20(_tokenAddress).transferFrom(
                    address(this),
                    msg.sender,
                    _amount
                );
        }
    }

    function process(
        uint256 index,
        bytes32 seed,
        bytes32 nexthash
    ) internal {
        require(
            keccak256(abi.encodePacked(seed)) == pools[index].seedHash,
            "incorrect seed"
        );
        require(
            block.timestamp >= pools[index].updatedAt + pools[index].period,
            "lottery time"
        );
        Pool storage pool = pools[index];
        pool.seedHash = nexthash;
        pool.updatedAt = uint128(block.timestamp);
        if (pool.players.length < 1) return;
        if (pool.players.length == 1) {
            userBalance[pool.players[0]][pool.tokenAddress] += pool.tokenAmount;
            pool.players = new address[](0);
            return;
        }

        uint256[] memory prices = new uint256[](aggregators.length);
        for (uint256 i = 0; i < aggregators.length; i++) {
            uint256 price = uint256(getLatestPrice(aggregators[i]));
            prices[i] = price;
        }
        uint256 random = uint256(
            keccak256(abi.encodePacked(seed, prices, pools[index].players))
        );

        address[] memory players = pool.players;
        uint256 distribution = ((pool.tokenAmount * players.length) * fee) /
            1000;
        uint256 half = (players.length + (players.length % 2)) / 2;
        bool odd = players.length % 2 == 1;
        for (uint256 i = 0; i < half; i++) {
            address player = players[i];
            uint256 swap = (uint256(keccak256(abi.encodePacked(random, i))) %
                (players.length - i)) + i;
            players[i] = players[swap];
            players[swap] = player;
            if (odd && i == half - 1)
                userBalance[players[i]][pool.tokenAddress] +=
                    pool.tokenAmount +
                    distribution /
                    5;
            else
                userBalance[players[i]][pool.tokenAddress] +=
                    (pool.tokenAmount * (200 - fee)) /
                    100;
        }
        pool.players = new address[](0);
        if (pool.burning) {
            userBalance[devWallet][pool.tokenAddress] += distribution;
            userBalance[founderWallet][pool.tokenAddress] += distribution;
            userBalance[owner()][pool.tokenAddress] += distribution;
            IERC20Burnable(pool.tokenAddress).burn(2 * distribution);
        } else {
            userBalance[devWallet][pool.tokenAddress] += 2 * distribution;
            userBalance[founderWallet][pool.tokenAddress] += 2 * distribution;
            userBalance[owner()][pool.tokenAddress] += distribution;
        }
        if (odd) userBalance[owner()][pool.tokenAddress] -= distribution / 5;
    }

    function draw(
        uint256 index,
        bytes32 seed,
        bytes32 nexthash
    ) external onlyOwner {
        process(index, seed, nexthash);
    }

    function drawAll(bytes32[] memory seeds, bytes32 nexthash)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < seeds.length; i++) {
            if (block.timestamp < pools[i].updatedAt + pools[i].period)
                continue;
            process(i, seeds[i], nexthash);
        }
    }
}