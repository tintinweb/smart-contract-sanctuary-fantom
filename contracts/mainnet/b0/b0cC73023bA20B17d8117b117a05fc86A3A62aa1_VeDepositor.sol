pragma solidity 0.8.11;

import "Ownable.sol";
import "IERC20.sol";
import "IVotingEscrow.sol";
import "IVeDist.sol";
import "ILpDepositor.sol";
import "IFeeDistributor.sol";
import "ISolidexVoter.sol";

contract VeDepositor is IERC20, Ownable {

    string public constant name = "SOLIDsex: Tokenized veSOLID";
    string public constant symbol = "SOLIDsex";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // Solidly contracts
    IERC20 public immutable token;
    IVotingEscrow public immutable votingEscrow;
    IVeDist public immutable veDistributor;

    // Solidex contracts
    ILpDepositor public lpDepositor;
    ISolidexVoter public solidexVoter;
    IFeeDistributor public feeDistributor;

    uint256 public tokenID;
    uint256 public unlockTime;

    uint256 constant MAX_LOCK_TIME = 86400 * 365 * 4;
    uint256 constant WEEK = 86400 * 7;

    event ClaimedFromVeDistributor(address indexed user, uint256 amount);
    event Merged(address indexed user, uint256 tokenID, uint256 amount);
    event UnlockTimeUpdated(uint256 unlockTime);

    constructor(
        IERC20 _token,
        IVotingEscrow _votingEscrow,
        IVeDist _veDist
    ) {
        token = _token;
        votingEscrow = _votingEscrow;
        veDistributor = _veDist;

        // approve vesting escrow to transfer SOLID (for adding to lock)
        _token.approve(address(_votingEscrow), type(uint256).max);
        emit Transfer(address(0), msg.sender, 0);
    }

    function setAddresses(
        ILpDepositor _lpDepositor,
        ISolidexVoter _solidexVoter,
        IFeeDistributor _feeDistributor
    ) external onlyOwner {
        lpDepositor = _lpDepositor;
        solidexVoter = _solidexVoter;
        feeDistributor = _feeDistributor;

        // approve fee distributor to transfer this token (for distributing SOLIDsex)
        allowance[address(this)][address(_feeDistributor)] = type(uint256).max;
        renounceOwnership();
    }


    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        if (allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenID,
        bytes calldata
    )external returns (bytes4) {
        (uint256 amount, uint256 end) = votingEscrow.locked(_tokenID);

        if (tokenID == 0) {
            tokenID = _tokenID;
            unlockTime = end;
            solidexVoter.setTokenID(tokenID);
            votingEscrow.safeTransferFrom(address(this), address(lpDepositor), _tokenID);
        } else {
            votingEscrow.merge(_tokenID, tokenID);
            if (end > unlockTime) unlockTime = end;
        }

        balanceOf[_operator] += amount;
        totalSupply += amount;
        extendLockTime();

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function merge(uint256 _tokenID) external returns (bool) {
        require(tokenID != _tokenID);
        (uint256 amount, uint256 end) = votingEscrow.locked(_tokenID);
        require(amount > 0);

        votingEscrow.merge(_tokenID, tokenID);
        if (end > unlockTime) unlockTime = end;

        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        extendLockTime();
        emit Merged(msg.sender, _tokenID, amount);

        return true;
    }

    function depositTokens(uint256 _amount) external returns (bool) {
        require(tokenID != 0, "First deposit must be NFT");

        token.transferFrom(msg.sender, address(this), _amount);
        votingEscrow.increase_amount(tokenID, _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        extendLockTime();

        return true;
    }

    function extendLockTime() public {
        uint256 maxUnlock = ((block.timestamp + MAX_LOCK_TIME) / WEEK) * WEEK;
        if (maxUnlock > unlockTime) {
            votingEscrow.increase_unlock_time(tokenID, MAX_LOCK_TIME);
            unlockTime = maxUnlock;
        }
        emit UnlockTimeUpdated(unlockTime);
    }

    /**
        @notice Claim veSOLID received via ve(3,3)
        @dev This method is unguarded, anyone can call to claim at any time.
             The new veSOLID is represented by newly minted SOLIDsex, which is
             then sent to `FeeDistributor` and streamed to SEX lockers starting
             at the beginning of the following epoch week.
     */
    function claimFromVeDistributor() external returns (bool) {
        veDistributor.claim(tokenID);

        // calculate the amount by comparing the change in the locked balance
        // to the known total supply, this is necessary because anyone can call
        // `veDistributor.claim` for any NFT
        (uint256 amount,) = votingEscrow.locked(tokenID);
        amount -= totalSupply;

        if (amount > 0) {
            balanceOf[address(this)] += amount;
            feeDistributor.depositFee(address(this), balanceOf[address(this)]);
            emit ClaimedFromVeDistributor(address(this), amount);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
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
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.11;

interface IVotingEscrow {
    function increase_amount(uint256 tokenID, uint256 value) external;
    function increase_unlock_time(uint256 tokenID, uint256 duration) external;
    function merge(uint256 fromID, uint256 toID) external;
    function locked(uint256 tokenID) external view returns (uint256 amount, uint256 unlockTime);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOfNFT(uint tokenId) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
}

pragma solidity 0.8.11;

interface IVeDist {
    function claim(uint _tokenId) external returns (uint);
}

pragma solidity 0.8.11;

interface ILpDepositor {
    function setTokenID(uint256 tokenID) external returns (bool);
    function userBalances(address user, address pool) external view returns (uint256);
    function totalBalances(address pool) external view returns (uint256);
    function transferDeposit(address pool, address from, address to, uint256 amount) external returns (bool);
    function whitelist(address token) external returns (bool);
}

pragma solidity 0.8.11;

interface IFeeDistributor {
    function depositFee(address _token, uint256 _amount) external returns (bool);
}

pragma solidity 0.8.11;

interface ISolidexVoter {
    function setTokenID(uint256 tokenID) external returns (bool);
}