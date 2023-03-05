// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// File: @openzeppelin/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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


contract TimelockTreasury is Ownable {
    using SafeMath for uint256;

    /* NEW */

    uint256 changeSettingsDelay = 86400;
    uint256 lastChangeSettingsTime;

    struct Token {
        uint256 tokenWithdrawDelay;
        uint256 lastWithdrawTime;
        uint256 maxWithdrawPerBatchSmall;
        uint256 maxWithdrawPerBatchBig;
        uint256 minAuths;
        uint256 currentAuths;
        mapping(address => bool) isRecipient;
        mapping(address => bool) isAuth;
    }

    mapping(address => Token) public tokens;

    event AddTreasuryToken(address _token);
    event SetRecipientToken(address _token, address _recipient, bool _status);
    event WithdrawTreasuryToken(address _token, address _recipient, uint _amount);

    function addTreasuryToken(
        address _token,
        uint256 _maxWithdrawPerBatchSmall,
        uint256 _maxWithdrawPerBatchBig,
        uint256 _minAuths
    ) external onlyOwner
    {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].tokenWithdrawDelay == 0, 'TreasuryVester::addVestingVault: already added');

        tokens[_token].tokenWithdrawDelay = 86400;
        tokens[_token].maxWithdrawPerBatchSmall = _maxWithdrawPerBatchSmall;
        tokens[_token].maxWithdrawPerBatchBig = _maxWithdrawPerBatchBig;
        tokens[_token].lastWithdrawTime = block.timestamp;
        tokens[_token].minAuths = _minAuths;
        tokens[_token].isRecipient[owner()] = true;
        tokens[_token].isAuth[owner()] = true;
        lastChangeSettingsTime = block.timestamp;

        emit AddTreasuryToken(_token);
    }

    function setTokenRecipient(address _token, address _recipient, bool _status) external onlyOwner {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].isRecipient[_recipient] != _status, 'TreasuryVester::setTokenRecipient: already set');

        tokens[_token].isRecipient[_recipient] = _status;

        emit SetRecipientToken(_token, _recipient, _status);
    }

    function setTokenIsAuth(address _token, address _auth, bool _status) external onlyOwner {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].isAuth[_auth] != _status, 'TreasuryVester::setTokenIsAuth: already set');

        tokens[_token].isAuth[_auth] = _status;

        emit SetRecipientToken(_token, _auth, _status);
    }

    function setTokenMinAuths(address _token, uint _minAuths) external onlyOwner {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].minAuths != _minAuths, 'TreasuryVester::setTokenMinAuths: already set');

        tokens[_token].minAuths = _minAuths;
        lastChangeSettingsTime = block.timestamp;
    }

    function setMaxWithdrawBatches(address _token, uint _maxWithdrawPerBatchSmall, uint _maxWithdrawPerBatchBig) external onlyOwner {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].maxWithdrawPerBatchSmall != _maxWithdrawPerBatchSmall, 'TreasuryVester::setMaxWithdrawBatches: already set');
        require(tokens[_token].maxWithdrawPerBatchBig != _maxWithdrawPerBatchBig, 'TreasuryVester::setMaxWithdrawBatches: already set');

        tokens[_token].maxWithdrawPerBatchSmall = _maxWithdrawPerBatchSmall;
        tokens[_token].maxWithdrawPerBatchBig = _maxWithdrawPerBatchBig;
        lastChangeSettingsTime = block.timestamp;
    }

    function setTokenWithdrawDelay(address _token, uint _timeDelay) external onlyOwner {
        require(block.timestamp >= lastChangeSettingsTime + changeSettingsDelay, 'TreasuryVester::addVestingVault: wait 24h');
        require(tokens[_token].tokenWithdrawDelay != _timeDelay, 'TreasuryVester::setTokenWithdrawDelay: already set');
        require(_timeDelay >= 3600, 'TreasuryVester::setTokenWithdrawDelay: minimum 1 hour');

        tokens[_token].tokenWithdrawDelay = _timeDelay;
        lastChangeSettingsTime = block.timestamp;
    }

    function addAuth(address _token) external {
        require(tokens[_token].isAuth[msg.sender], 'TreasuryVester::addAuth: unauthorized');
        require(tokens[_token].currentAuths < tokens[_token].minAuths, 'TreasuryVester::addAuth: already set');

        tokens[_token].currentAuths += 1;
    }

    function withdraw(address _tokenAddress, uint _amount) external {
        require(block.timestamp >= tokens[_tokenAddress].lastWithdrawTime + tokens[_tokenAddress].tokenWithdrawDelay, 'TreasuryVester::withdraw: wait 24h');
        require(tokens[_tokenAddress].isRecipient[msg.sender], 'TreasuryVester::withdraw: unauthorized');
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, 'TreasuryVester::withdraw: not enough tokens');
        require(tokens[_tokenAddress].currentAuths >= tokens[_tokenAddress].minAuths, 'TreasuryVester::withdraw: not enough auths');

        if (_amount > tokens[_tokenAddress].maxWithdrawPerBatchBig) {
            require(_amount <= tokens[_tokenAddress].maxWithdrawPerBatchBig, 'TreasuryVester::withdraw: too much tokens');
        }
        else if (_amount > tokens[_tokenAddress].maxWithdrawPerBatchSmall) {
            require(block.timestamp >= tokens[_tokenAddress].lastWithdrawTime + (86400 * 7), 'TreasuryVester::withdraw: wait 7 days');
        }
        else {
            require(block.timestamp >= tokens[_tokenAddress].lastWithdrawTime + 86400, 'TreasuryVester::withdraw: wait 1 day');
        }

        tokens[_tokenAddress].currentAuths = 0;

        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        tokens[_tokenAddress].lastWithdrawTime = block.timestamp;

        emit WithdrawTreasuryToken(_tokenAddress, msg.sender, _amount);
    }

    function emergencyClaimAll(address _tokenAddress) external onlyOwner {
        require(block.timestamp >= tokens[_tokenAddress].lastWithdrawTime + (86400 * 30), 'TreasuryVester::claim: wait 30 days');

        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(owner(), amount);
        tokens[_tokenAddress].lastWithdrawTime = block.timestamp;

        emit WithdrawTreasuryToken(_tokenAddress, owner(), amount);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}