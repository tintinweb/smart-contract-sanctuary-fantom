// SPDX-License-Identifier: MIT

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IBribe.sol";

pragma solidity ^0.8.13;

// the purpose of this contract is to allow the projects to deposit bribes that will bribe their pools for a period of time
// they will need to set up a public keeper, anyone can send the bribes
// bribes are divided evenly into the amount of weeks designated when they deposit
// each new deposit will NOT make a bribe immediately!
// calling the bribe function is public and is rewarded with a share of the bribe token
// !!!!!!!!!!!this contract handles multiple bribe tokens, and a single bribe contract!!!!!!!!!

contract AutoBribe is Ownable {
    address public wBribe;

    address public project;
    bool public depositSealed;
    bool public initialized;
    uint256 public nextWeek;
    address[] public bribeTokens;
    mapping(address => bool) public bribeTokensDeposited;
    mapping(address => uint256) public bribeTokenToWeeksLeft;
    string public bribeName;

    event Deposited(
        address indexed _bribeToken,
        uint256 _amount,
        uint256 _weeks
    );
    event Bribed(uint256 indexed _timestamp, address _briber);
    event EmptiedOut(uint256 indexed _timestamp, address project);
    event Sealed(uint256 indexed _timestamp);
    event UnSealed(uint256 indexed _timestamp);
    event NewBribeSet(uint indexed _timestamp, address wbribe);

    constructor(address _wBribe, address _team, string memory _name) {
        wBribe = _wBribe;
        _transferOwnership(_team);
        nextWeek = block.timestamp;
        bribeName = _name;
    }

    //########################################
    //###########PUBLIC FUNCTIONS#############
    //########################################

    //This public function allows anyone to send the weekly allocation to the bribe contract
    //There is a small reward for calling this function
    //It can only be called once a week
    function bribe() public {
        require(block.timestamp >= nextWeek, 'this bribed this week already');
        uint256 length = bribeTokens.length;
        address _bribeToken;
        for (uint256 i = 0; i < length; ) {
            _bribeToken = bribeTokens[i];
            uint256 weeksLeft = bribeTokenToWeeksLeft[_bribeToken];
            uint256 bribeAmount = balance(_bribeToken) / weeksLeft;
            uint256 gasReward = bribeAmount / 200;
            _safeTransfer(_bribeToken, msg.sender, gasReward);
            IBribe(wBribe).notifyRewardAmount(
                _bribeToken,
                bribeAmount - gasReward
            );
            bribeTokenToWeeksLeft[_bribeToken] = weeksLeft - 1;
            unchecked {
                ++i;
            }
        }
        nextWeek = nextWeek + 604800;
        emit Bribed(nextWeek, msg.sender);
    }

    //This just returns the balance of bribe tokens in the contract
    function balance(address _bribeToken) public view returns (uint) {
        return IERC20(_bribeToken).balanceOf(address(this));
    }
    //This just returns the amount of bribetokens that have been added
    function bribeTypeQuantity() public view returns (uint)  {
        return bribeTokens.length;
    }

    //########################################
    //########PROJECT ADMIN FUNCTIONS#########
    //########################################

    //Allows project to deposit bribe tokens and set the weeks of which they are divided up into
    function deposit(
        address _bribeToken,
        uint256 _amount,
        uint256 _weeks
    ) public {
        require(msg.sender == project, "only the project can bribe");
        require(_amount > 0, "Why are you depositing 0 tokens?");
        require(_weeks > 0, "You have to put at least 1 week");
        _safeTransferFrom(_bribeToken, msg.sender, address(this), _amount);
        uint256 allowance = IERC20(_bribeToken).allowance(
            address(this),
            wBribe
        );
        _safeApprove(_bribeToken, wBribe, allowance + _amount);
        if (!bribeTokensDeposited[_bribeToken]) {
            bribeTokensDeposited[_bribeToken] = true;
            bribeTokens.push(_bribeToken);
        }
        bribeTokenToWeeksLeft[_bribeToken] += _weeks;

        emit Deposited(_bribeToken, _amount, _weeks);
    }

    //Allows the project to retrieve their bribe tokens
    function emptyOut() public {
        require(msg.sender == project, "only project can empty out");
        require(!depositSealed, "deposit is sealed");
        uint256 length = bribeTokens.length;
        uint256 amount;

        for (uint256 i = 0; i < length; ) {
            address bribeToken = bribeTokens[i];
            amount = balance(bribeToken);
            bribeTokenToWeeksLeft[bribeToken] = 0;
            _safeTransfer(bribeToken, msg.sender, amount);

            unchecked {
                ++i;
            }
        }

        emit EmptiedOut(block.timestamp, project);
    }

    //Allows project to seal the vault making it not possible for them to withdraw their tokens
    function seal() public {
        require(msg.sender == project, "only project can seal");
        depositSealed = true;

        emit Sealed(block.timestamp);
    }

    //Allows project to change their controlling wallet
    function setProject(address _newWallet) public {
        require(msg.sender == project);
        project = _newWallet;
    }

    //Allow project to change the wBribe contract
    //PROJECT!! Double check this before changing with Velocimeter
    function setWBribe(address _newBribe) public {
        require(msg.sender == project && !depositSealed);
        wBribe = _newBribe;

        emit NewBribeSet(block.timestamp, wBribe);
    }

    //########################################
    //#######VELOCIMETER ADMIN FUNCTIONS######
    //########################################

    //Allows Velocimeter to re allow project to withdraw their tokens
    function unSeal() public onlyOwner {
        depositSealed = false;

        emit UnSealed(block.timestamp);
    }

    function initProject(address _newWallet) public onlyOwner {
        require(!initialized, "project wallet can only be set once by team");
        if (!initialized) {
            initialized = true;
        }
        project = _newWallet;
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(!bribeTokensDeposited[_token], "!bribeToken");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        _safeTransfer(_token, msg.sender, amount);
    }

    //########################################
    //############RECLOCK FUNCTION############
    //########################################

    // Allows project or Velocimeter to reset the week to the current block
    // This should only be called with consideration as it can allow for double bribes in a single week.
    // Best use is to call it BEFORE, bribe() is called in a given week
    function reclockBribeToNow() external {
        require(
            msg.sender == project || msg.sender == owner(),
            "you can't call this"
        );
        nextWeek = block.timestamp;
    }

    //########################################
    //############INTERNAL FUNCTIONS##########
    //########################################

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token, address spender, uint value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.13;

interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
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