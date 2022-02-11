// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPrinterToken {
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
    function isAuthorized(address adr) external view returns (bool);
    function setMaxWallet(uint256 _amount) external;
    function setTxLimit(uint256 _amount) external;
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external;
    function setIsDividendExempt(address holder, bool exempt) external;
    function setIsFeeExempt(address holder, bool exempt) external;
    function setIsTxLimitExempt(address holder, bool exempt) external;
}

interface IPrinterTokenV1 {
  function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external;
}

interface IPrinterTokenV2 {
  function setFees(uint256 _devFee, uint256 _marketingFee, uint256 _reflectionFee, uint256 _liquidityFee) external;
}

contract PrinterManager is Ownable {
    
    IERC20 public WFTM; 
    
    IERC20 public GSCARABp; 
    IERC20 public SCARAp; 

    mapping (address => bool) internal authorizations;
    
    constructor(
        IERC20 wftm_,
        IERC20 gscarabp_,
        IERC20 scarap_
    ) {
        WFTM = wftm_;
        GSCARABp = gscarabp_; 
        SCARAp = scarap_; 

        authorizations[msg.sender] = true;
    }

    function hasControl(address _token) external view returns(bool) {
        if(_token == address(GSCARABp)) {
            return IPrinterToken(_token).owner() == address(this) || IPrinterToken(_token).isAuthorized(address(this)) == true;
        } else if(_token == address(SCARAp)) {
            return IPrinterToken(_token).owner() == address(this);
        } else {
            return false; 
        }
    }

    function setNewPrinterOwner(address _token , address _newOwner) external onlyOwner {
        IPrinterToken(_token).transferOwnership(_newOwner);
    }

    function setPrinterFees(
        address _token,
        uint256 _devFee, 
        uint256 _marketingFee, 
        uint256 _reflectionFee, 
        uint256 _liquidityFee,
        uint256 _feeDenominator
    ) external AuthorizedOnly {
        if(_token == address(GSCARABp)) {
            IPrinterTokenV1(_token).setFees(_liquidityFee, 0, _reflectionFee, _marketingFee, _feeDenominator);
        } else if(_token == address(SCARAp)) {
           IPrinterTokenV2(_token).setFees(_devFee, _marketingFee, _reflectionFee, _liquidityFee);
        } 
    }

    function setPrinterMaxWallet(address _token, uint256 _amount) external AuthorizedOnly{
        IPrinterToken(_token).setMaxWallet(_amount);
    }

    function setPrinterTxLimit(address _token, uint256 _amount) external AuthorizedOnly{
        IPrinterToken(_token).setTxLimit(_amount);
    }

    function setPrinterTargetLiquidity(address _token, uint256 _target, uint256 _denominator) external AuthorizedOnly {
        IPrinterToken(_token).setTargetLiquidity(_target, _denominator);
    }

    function setPrinterIsDividendExempt(address _token, address _holder, bool _exempt) external AuthorizedOnly {
        IPrinterToken(_token).setIsDividendExempt(_holder, _exempt);
    }

    function setPrinterIsFeeExempt(address _token, address _holder, bool _exempt) external AuthorizedOnly {
        IPrinterToken(_token).setIsFeeExempt(_holder, _exempt);
    }

    function setPrinterIsTxLimitExempt(address _token, address _holder, bool _exempt) external AuthorizedOnly {
        IPrinterToken(_token).setIsTxLimitExempt(_holder, _exempt);
    }
    

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        authorizations[newOwner] = true;
        _transferOwnership(newOwner);
    }

    /** ======= MODIFIERS ======= */

    /**
     * Function modifier to require caller to be authorized
     */
    modifier AuthorizedOnly() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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