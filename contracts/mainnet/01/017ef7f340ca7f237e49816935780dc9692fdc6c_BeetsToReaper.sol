/**
 *Submitted for verification at FtmScan.com on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
interface IBeetsBar is IERC20 {
  function enter(uint256 amount_) external;
  function leave(uint256 shareOfFreshBeets_) external;
}
pragma experimental ABIEncoderV2;

interface IBalancerVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getPool(bytes32 poolId)
        external
        view
        returns (address, uint8);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
}
interface ICrypt is IERC20 {
  function deposit(uint256) external;
}

contract BeetsToReaper is Ownable {
  ICrypt         public immutable crypt;
  IBalancerVault public immutable balancerVault;
  IBeetsBar      public immutable beetsBar;
  IERC20         public immutable beets;
  IERC20         public immutable wftm;
  IERC20         public immutable fBeetsBPT;
  bytes32        public immutable fBeetsPoolID;

  uint256   public fee = 0; // fee in BPS
  address   public feeReceiver;
  address[] public lpTokens;

  mapping(address=>bool) public feeExempt;

  event SetFee(address indexed _feeReceiver, uint256 _fee);
  event SetFeeExempt(address indexed _caller, bool _exempt);

  constructor(address _crypt, address _vault, address _beetsBar, address _beets, address _wftm, address _fBeetsBPT, bytes32 _fBeetsPoolID) {
    crypt = ICrypt(_crypt);
    balancerVault = IBalancerVault(_vault);
    beetsBar = IBeetsBar(_beetsBar);
    beets = IERC20(_beets);
    wftm = IERC20(_wftm);
    fBeetsBPT = IERC20(_fBeetsBPT);
    lpTokens.push(_wftm);
    lpTokens.push(_beets);
    fBeetsPoolID = _fBeetsPoolID;

    IERC20(_beets).approve(_vault, type(uint256).max);
    IERC20(_fBeetsBPT).approve(_beetsBar, type(uint256).max);
    IERC20(_beetsBar).approve(_crypt, type(uint256).max);
  }

  function destroy() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  function recover(address _token) external onlyOwner {
    IERC20(_token).transfer(
      owner(),
      IERC20(_token).balanceOf(address(this))
    );
  }

  function setFee(uint256 _fee, address _feeReceiver) external onlyOwner {
    if (_fee != 0) {
      require(_feeReceiver != address(0), "zero receiver");
    }

    require(_fee <= 500, "fee limit"); // 5%
    fee = _fee;
    feeReceiver = _feeReceiver;

    emit SetFee(_feeReceiver, _fee);
  }

  function setFeeExempt(bool _exempt, address _caller) external onlyOwner {
    feeExempt[_caller] = _exempt;

    emit SetFeeExempt(_caller, _exempt);
  }

  function zapAll(uint256 _minimumReceived) external {
    zap(beets.balanceOf(msg.sender), _minimumReceived);
  }

  function zap(uint256 _amount, uint256 _minimumReceived) public {
    uint256 received = zapToBeets(_amount, _minimumReceived);

    crypt.deposit(received);
    crypt.transfer(msg.sender, crypt.balanceOf(address(this)));
  }

  function zapToBeets(uint256 _amount, uint256 _minimumReceived) public returns(uint256){
    uint256 balBefore = beetsBar.balanceOf(address(this));
    beets.transferFrom(msg.sender, address(this), _amount);

    if (fee > 0 && feeReceiver != address(0)) {
      uint256 feeTaken = (_amount * fee);
      beets.transfer(feeReceiver, feeTaken / 1e4);
      _amount = _amount - feeTaken;
    }


    convertToFreshBeets(_amount);
    uint256 received = beetsBar.balanceOf(address(this)) - balBefore;
    require(received >= _minimumReceived, "minimum received");

    return received;
  }

  function convertToFreshBeets(uint256 beetsAmt) internal {
    balancerJoin(fBeetsPoolID, address(beets), beetsAmt);
    uint256 amount = fBeetsBPT.balanceOf(address(this));

    beetsBar.enter(amount);
  }

  function balancerJoin(bytes32 _poolId, address _tokenIn, uint256 _amountIn) internal {
    uint256[] memory amounts = new uint256[](lpTokens.length);
    for (uint256 i = 0; i < amounts.length; i++) {
        amounts[i] = lpTokens[i] == _tokenIn ? _amountIn : 0;
    }
    bytes memory userData = abi.encode(1, amounts, 1); // TODO

    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(lpTokens, amounts, userData, false);
    balancerVault.joinPool(_poolId, address(this), address(this), request);
  }
}