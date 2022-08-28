/**
 *Submitted for verification at FtmScan.com on 2022-08-28
*/

// File: BlackList.sol



pragma solidity ^0.8.0;

abstract contract BlackList {
    mapping (address => bool) public isBlackListed;

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

    function getBlackListStatus(address _maker) external view virtual returns (bool) {
        return isBlackListed[_maker];
    }

    function _addBlackList (address _evilUser) internal virtual {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function _removeBlackList (address _clearedUser) internal virtual {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

// File: ReentrancyGuard.sol


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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: ITOKEN.sol



pragma solidity ^0.8.0;


interface ITOKEN {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

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
}

// File: ITOKENMetadata.sol



pragma solidity ^0.8.0;



interface ITOKENMetadata is ITOKEN {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: Context.sol



pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: TOKEN.sol



pragma solidity ^0.8.0;





contract TOKEN is ITOKEN, ITOKENMetadata, Pausable {

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File: Contract.sol



pragma solidity ^0.8.0;







contract BTCBET is Ownable, TOKEN, ReentrancyGuard, BlackList {

    uint minAmount;
    uint32 constant MULTIPLIER = 1e9;

    uint32 public leadingWinners;

    bool public resetInProgress;

    uint public totalBet;

    string [] pool;

    address [] users;


    mapping (string => uint) public totalPoolBet;

    mapping (address => mapping (string => uint)) public betArray;

    event BuyToken(address indexed buyer, uint256 value);

    event SellToken(address indexed seller, uint256 value);

    event CreateBet(address indexed beter, string indexed pool, uint256 value);

    event WinBet(address indexed beter, string indexed pool, uint256 value);

    event NobodyWin(string indexed pool);

    modifier onlyIfResetNotInProgress(){
        require(!resetInProgress, "Reward calculation, please try again later");
        _;
    }
    // "BlockchainBitcoinBet", "BTCBET"
    constructor() TOKEN("TestTest", "TTTTTTT") {
        minAmount = 1e18;
        _mint(_msgSender(), 1e27);
    }

    function createBet(string memory pool_, uint amount_) external onlyIfResetNotInProgress {
        require(amount_ >= minAmount, "Amount less than the minimum bet");
        require(balanceOf(_msgSender()) >= amount_, "Insufficient funds");
        _transfer(_msgSender(), owner(), amount_);
        bool isUser = false;
        for (uint i = 0; i < users.length; i++){
            if (users[i] == _msgSender()) {
                isUser = true;
                break;
            }
        }
        if (!isUser) {
            users.push(_msgSender());
        }
        totalBet += amount_;
        totalPoolBet[pool_] += amount_;
        betArray[_msgSender()][pool_] += amount_;
        emit CreateBet(_msgSender(), pool_, amount_);
    }

    function winningCalculation(string memory pool_) external onlyOwner {
        resetInProgress = true;
        leadingWinners = 0;
        uint amount_;
        uint pr_;
        uint totalPoolBet_ = totalPoolBet[pool_];
        for (uint i = 0; i < users.length; i++){
            amount_ = 0;
            pr_ = 0;
            if (betArray[users[i]][pool_] > 0) {
                pr_ = betArray[users[i]][pool_] * MULTIPLIER / totalPoolBet_;
                amount_ = totalBet * pr_ / MULTIPLIER;
                _transfer(owner(), users[i], amount_);
                leadingWinners ++;
                emit WinBet(users[i], pool_, amount_);
            }
        }
        if (leadingWinners > 0) {
            _reset();
        } else {
            emit NobodyWin(pool_);
        }
        resetInProgress = false;
    }

    function _reset() private {
        totalBet = 0;
        for (uint i = 0; i < users.length; i++){
            for (uint p = 0; p < pool.length; p++) {
                betArray[users[i]][pool[p]] = 0;
            }
        }
        users = [address(0)];
        users.pop();
        for (uint p = 0; p < pool.length; p++) {
            totalPoolBet[pool[p]] = 0;
        }

    }

    receive() external payable {
        require(msg.value >= 1e18, "You need to send minimum 1");
        _transfer(owner(), _msgSender(), msg.value);
        emit BuyToken(_msgSender(), msg.value);
    }

    function sell(uint amount_) external nonReentrant {
        require(balanceOf(_msgSender()) >= amount_, "Insufficient funds");
        _transfer(_msgSender(), owner(), amount_);
        (bool success, ) = payable(_msgSender()).call{value: amount_}("");
        require(success, "Could not sell BTCBET");
        emit SellToken(_msgSender(), amount_);
    }

    function setMinAmount(uint amount_) external onlyOwner{
        minAmount = amount_;
    }

    function deletePool(uint index) external onlyOwner{
        pool[index] = pool[pool.length - 1];
        pool.pop();
    }

    function setPool(string memory pool_) external onlyOwner{
        pool.push(pool_);
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        _transferOwnership(newOwner_);
    }

    function addBlackList(address account_) external onlyOwner {
        _addBlackList(account_);
    }

    function removeBlackList(address account_) external onlyOwner {
        _removeBlackList(account_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getPool() external view returns (string [] memory) {
        return pool;
    }

    function getUsers() external view returns (address [] memory) {
        return users;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!isBlackListed[from], "Address from in black list");
        require(!isBlackListed[to], "Address to in black list");
        require(!paused(), "Token transfer while paused");
    }
}