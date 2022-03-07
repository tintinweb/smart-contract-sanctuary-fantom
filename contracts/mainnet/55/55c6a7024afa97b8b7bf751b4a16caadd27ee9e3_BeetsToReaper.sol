/**
 *Submitted for verification at FtmScan.com on 2022-03-07
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
interface ICrypt {
  function deposit(uint256) external;
}

contract BeetsToReaper {
  ICrypt         public immutable crypt;
  IBalancerVault public immutable balancerVault;
  IBeetsBar      public immutable beetsBar;
  IERC20         public immutable beets;
  IERC20         public immutable wftm;
  IERC20         public immutable fBeetsBPT;
  bytes32        public immutable fBeetsPoolID;

  uint256 public fee = 0; // fee in BPS
  address public feeReceiver;
  address[]      public lpTokens;

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

  function zapAll(uint256 _minimumReceived) external {
    zap(beets.balanceOf(msg.sender), _minimumReceived);
  }

  function zap(uint256 _amount, uint256 _minimumReceived) public {
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

    crypt.deposit(received);
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