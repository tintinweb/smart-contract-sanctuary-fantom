// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IBeetsBar } from "solidity-interfaces/beethovenx/IBeetsBar.sol";
import { IBalancerVault } from "solidity-interfaces/beethovenx/IBalancerVault.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { BalancerPoolJoiner } from "src/BalancerPoolJoiner.sol";
import { IChefFarmer } from "src/Interfaces.sol";

contract Manager is Ownable, BalancerPoolJoiner {
  IERC20 public beets;
  IERC20 public fBeets;
  IERC20 public bpt;

  IBeetsBar public beetsBar;

  uint256[] public chefPIDs;
  uint256 public fBeetsChefPID;

  IChefFarmer public chefFarmer;

  address[] public lpTokens;
  bytes32 public fBeetsPoolID;

  address public operator;

  constructor(
    uint256[] memory _chefPIDs,
    uint256 _fBeetsChefPID,
    address _bpt,
    address _beets,
    address _beetsBar,
    address[] memory _lpTokens,
    bytes32 _fBeetsPoolID,
    address _balancerVault
  ) BalancerPoolJoiner(_balancerVault){
    chefPIDs = _chefPIDs;
    fBeetsChefPID = _fBeetsChefPID;
    beets = IERC20(_beets);
    bpt = IERC20(_bpt);
    beetsBar = IBeetsBar(_beetsBar);
    fBeets = IERC20(_beetsBar);
    lpTokens = _lpTokens;
    fBeetsPoolID = _fBeetsPoolID;

    beets.approve(_balancerVault, type(uint256).max);
    bpt.approve(_beetsBar, type(uint256).max);
  }

  modifier onlyOperator() {
    require(msg.sender == owner() || msg.sender == operator, "not allowed");
    _;
  }

  function setOperator(address _operator) public onlyOwner {
    operator = _operator;
  }

  function setChefFarmer(address _chefFarmer) public onlyOwner {
    chefFarmer = IChefFarmer(_chefFarmer);
    fBeets.approve(address(chefFarmer), type(uint256).max);
  }

  function setChefPIDs(uint256[] memory _chefPIDs) public onlyOwner {
    chefPIDs = _chefPIDs;
  }

  function compoundRewards(uint256 _minfBeetsReceived) public onlyOperator {
    chefFarmer.harvestRewards(chefPIDs);
    uint256 beetsAmt = beets.balanceOf(address(chefFarmer));
    require(beetsAmt > 0, "nothing to compound");

    beets.transferFrom(address(chefFarmer), address(this), beetsAmt);
    beetsTofBeets(beetsAmt, _minfBeetsReceived);

    chefFarmer.depositFarmToken(
      address(fBeets),
      fBeets.balanceOf(address(this)),
      fBeetsChefPID
    );
  }

  // internal

  function beetsTofBeets(uint256 _amount, uint256 _minReceived) internal {
    balancerJoin(lpTokens, fBeetsPoolID, address(beets), _amount);
    beetsBar.enter(bpt.balanceOf(address(this)));
    require(fBeets.balanceOf(address(this)) > _minReceived, "not enough received");
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IBeetsBar {
  function enter(uint256 amount_) external;
  function leave(uint256 shareOfFreshBeets_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IBalancerVault } from "solidity-interfaces/beethovenx/IBalancerVault.sol";

contract BalancerPoolJoiner {
  IBalancerVault public balancerVault;

  constructor(address _balancerVault) {
    balancerVault = IBalancerVault(_balancerVault);
  }

  function balancerJoin(address[] memory tokens, bytes32 _poolId, address _tokenIn, uint256 _amountIn) internal {
    uint256[] memory amounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < amounts.length; i++) {
        amounts[i] = tokens[i] == _tokenIn ? _amountIn : 0;
    }
    bytes memory userData = abi.encode(1, amounts, 1); // TODO

    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(tokens, amounts, userData, false);
    IBalancerVault(balancerVault).joinPool(_poolId, address(this), address(this), request);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IChefFarmer {
  function transferToken(address _token, uint256 _amount) external;
  function harvestRewards(uint256[] calldata _chefPIDs) external;
  function depositFarmToken(address _token, uint256 _amount, uint256 _chefPID) external;
  function depositFarmTokenBalance(address _token, uint256 _amount, uint256 _chefPID) external;
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