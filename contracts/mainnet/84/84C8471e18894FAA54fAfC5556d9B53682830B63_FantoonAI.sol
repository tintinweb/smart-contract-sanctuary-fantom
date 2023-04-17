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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Requisite {
    string label;
    address token1;
    address token2;
    uint256 threshold1;
    uint256 threshold2;
}

contract FantoonAI is Ownable {
    Requisite[] private requisites;
    mapping(address => uint256) public expires;

    address public developer;
    
    IERC20 public token;
    uint256 public threshold = 0;
    uint256 public expiredPeriod = 30 days;

    constructor() Ownable() {
        developer = msg.sender;
    }

    function addRequisite(
        string memory label,
        address _token1, uint256 _threshold1,
        address _token2, uint256 _threshold2
    ) public onlyOwner {
        require(_token1 != address(0) || _token2 != address(0), "Either of tokens must not be NULL");

        requisites.push(Requisite({
            label: label,
            token1: _token1,
            token2: _token2,
            threshold1: _threshold1,
            threshold2: _threshold2
        }));
    }

    function removeRequisite(uint8 _step) public onlyOwner {
        require(_step > 0 && _step <= requisites.length, "Invalid Number");

        Requisite storage requisite = requisites[_step - 1];
        requisite.token1 = address(0);
        requisite.token2 = address(0);
    }

    function updateRequisite (
        uint8 _step,
        string memory label,
        address _token1, uint256 _threshold1,
        address _token2, uint256 _threshold2
    ) public onlyOwner {        
        require(_step > 0 && _step <= requisites.length, "Invalid Number");
        require(_token1 != address(0) || _token2 != address(0), "Either of tokens must not be NULL");

        requisites[_step - 1] = Requisite({
            label: label,
            token1: _token1,
            token2: _token2,
            threshold1: _threshold1,
            threshold2: _threshold2
        });
    }

    function plans() public view returns (Requisite[] memory) {
        uint256 length = requisites.length;
        for(uint256 i = 0;i<requisites.length;i++) {
            if(requisites[i].token1==address(0) && requisites[i].token2==address(0))
                length--;
        }
        Requisite[] memory _requisites = new Requisite[](length);
        uint256 j = 0;
        for(uint256 i = 0;i<requisites.length;i++) {
            if(requisites[i].token1!=address(0) || requisites[i].token2!=address(0)) {
                _requisites[j].label = requisites[i].label;
                _requisites[j].token1 = requisites[i].token1;
                _requisites[j].threshold1 = requisites[i].threshold1;
                _requisites[j].token2 = requisites[i].token2;
                _requisites[j].threshold2 = requisites[i].threshold2;
                j ++;
            }
        }
        return _requisites;
    }

    function check(address _account) public view returns (uint32) {
        uint32 res = 0;
        for( uint32 index = 0 ; index<requisites.length ; index++ ) {
            Requisite storage requisite = requisites[index];
            uint8 permitted = 0;
            if( requisite.token1 != address(0) && requisite.threshold1 > 0 ) {
                uint256 balance = IERC20(requisite.token1).balanceOf(_account);
                if(balance < requisite.threshold1) {
                    continue;
                } else {
                    permitted++;
                }
            }
            if(requisite.token2 != address(0) && requisite.threshold2 > 0) {
                uint256 balance = IERC20(requisite.token2).balanceOf(_account);
                if(balance < requisite.threshold2) {
                    continue;
                } else {
                    permitted++;
                }
            }
            if(permitted > 0) {
                res = index + 1;
                break;
            }
        }
        if(expires[_account] >= block.timestamp){
            res = uint32(requisites.length + 1);
        }
        return res;
    }

    function setToken(address _token, uint256 _threshold) public onlyOwner {
        require(_token != address(0), "Address cannot be NULL");
        require(_threshold > 0, "Threshold cannot be negotive");
        token = IERC20(_token);
        threshold = _threshold;
    }

    function setDeveloper(address _developer) public onlyOwner {
        require(_developer != address(0), "Address cannot be NULL");

        developer = _developer;
    }

    function setExpirePeriod(uint256 _period) public onlyOwner {
        require(_period > 0 && _period < 365 days, "Period range invalid");

        expiredPeriod = _period;
    }

    function pay(uint8 _months) public {
        require(address(token) != address(0) && developer != address(0) && threshold > 0, "Payment has not initialized");
        require(_months > 0 && _months <= 12, "Invalid argument");

        token.transferFrom(msg.sender, developer, threshold * _months);
        expires[msg.sender] = (expires[msg.sender]==0 ? block.timestamp : expires[msg.sender]) + _months * expiredPeriod;
    }

    function withdraw(address _token) public onlyOwner {
        IERC20 wtoken = IERC20(_token);
        uint256 balance = wtoken.balanceOf(address(this));
        wtoken.transfer(msg.sender, balance);
    }
}