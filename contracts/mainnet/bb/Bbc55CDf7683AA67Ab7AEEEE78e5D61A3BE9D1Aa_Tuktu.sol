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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";

abstract contract Account is IAccount, ReentrancyGuard, Ownable2Step {
	using UintArray for uint[];
	using Lib for *;
	using AffiliateCreator for bytes;

	uint public num;
	uint public constant CFID = 9876543210; // Community fund
	address public MultiSig; // Community fund address and gov recover unsupported, multi-sig wallet
	IXProgram public XPrograms;
	IMatrix public Matrixes;
	IAPI public APIs; // Tuktu API contract for frontend

	mapping(uint => uint) private RT; // Registration datetime
	mapping(uint => address) private AID; // Each account has only one address
	mapping(address => uint[]) private IDA; // One address can have multiple accounts
	mapping(bytes32 => uint) private AAF; // AccountID of Affiliate
	mapping(uint => bytes32) private AFA; // Account owner can modify
	bool internal Initialized; // flags
	event ChangedAddress(uint indexed AccountID, address FromAddress, address ToAddress);
	event ChangedAffiliate(uint indexed AccountID, string FromAffiliate, string ToAffiliate);

	constructor() {}

	modifier notAInitialized() {
		require(!isAInitialized(), "Already initialized");
		_;
	}

	function Initializer() public virtual notAInitialized {
		XPrograms.Initializer(IAccount(address(this)), IBalance(address(this)), ITuktu(address(this)), IAPI(APIs));
		Initialized = true; // Run only one time.
	}

	modifier onlyXProgramsOrMatrixes() {
		require(
			msg.sender == address(XPrograms) || msg.sender == address(Matrixes),
			"caller is not the XPrograms or Matrixes"
		);
		_;
	}

	modifier onlyAPI() {
		require(msg.sender == address(APIs), "caller is not the API");
		_;
	}

	modifier OnlyAccountOwner(uint _AID, address _Owner) {
		require(_isExisted(_AID) && _Owner == AddressOfAccount(_AID), "account: not existed or owner");
		_;
	}

	modifier OnlyAccountExisted(uint _AID) {
		require(_isExisted(_AID), "Account: does not exist");
		_;
	}

	function isAInitialized() private returns (bool isInitialized_) {
		return Initialized.v(RT, AID, IDA) && Initialized;
	}

	function _isExisted(uint _AID) internal view returns (bool isExist_) {
		return RT[_AID] != 0;
	}

	function AddressOfAccount(uint _AID) public view returns (address address_) {
		return AID[_AID];
	}

	function AccountOfAffiliate(string memory _Affiliate) public view returns (uint AID_) {
		return AAF[bytes32(bytes(_Affiliate))];
	}

	function AffiliateOfAccount(uint _AID) public view returns (string memory affiliate_) {
		return string(abi.encode(AFA[_AID]));
	}

	function RegistrationTime(uint _AID) public view returns (uint RT_) {
		return RT[_AID];
	}

	function AccountsOfAddress(address _Address) public view returns (uint[] memory AIDs_) {
		return IDA[_Address];
	}

	function LatestAccountsOfAddress(address _Address) public view virtual returns (uint AID_) {
		uint[] memory accounts = AccountsOfAddress(_Address);
		if (accounts.length > 0) {
			AID_ = accounts[0];
			for (uint i = 1; i < accounts.length; ++i) {
				if (RT[accounts[i]] > RT[AID_]) AID_ = accounts[i];
			}
		}
	}

	function _InitAccount(uint NewAccountID_, address _Address) internal {
		RT[NewAccountID_] = block.timestamp;
		AID[NewAccountID_] = _Address;
		IDA[_Address].push(NewAccountID_);
		AFA[NewAccountID_] = _AffiliateCreator(NewAccountID_);
		AAF[AFA[NewAccountID_]] = NewAccountID_;
	}

	function _IDCreator() internal returns (uint AID_) {
		while (true) {
			if (!_isExisted(++num)) return num;
		}
	}

	function _AffiliateCreator(uint _AID) private view returns (bytes16 affiliate_) {
		while (true) {
			affiliate_ = AffiliateCreator.Create(_AID, 8);
			if (AAF[affiliate_] == 0) return affiliate_;
		}
	}

	// Change affiliate
	function _ChangeAffiliate(uint _AID, string memory _Affiliate) private returns (bool success_) {
		bytes32 newaff = bytes32(bytes(_Affiliate));
		require(newaff != bytes32(0) && AccountOfAffiliate(_Affiliate) == 0, "Affiliate: existed or empty");
		string memory oldAff = AffiliateOfAccount(_AID);
		require(newaff != bytes32(bytes(oldAff)), "Affiliate: same already exists");
		delete AAF[bytes32(bytes(oldAff))];
		AAF[newaff] = _AID;
		AFA[_AID] = newaff;
		if (_AID.v()) emit ChangedAffiliate(_AID, oldAff, _Affiliate);
		return true;
	}

	function ChangeAffiliate(
		uint _AID,
		string memory _Affiliate
	) external virtual OnlyAccountOwner(_AID, msg.sender) returns (bool success_) {
		return _ChangeAffiliate(_AID, _Affiliate);
	}

	function ChangeAffiliate(
		uint _AID,
		string memory _Affiliate,
		address _Owner
	) external virtual onlyAPI OnlyAccountOwner(_AID, _Owner) returns (bool success_) {
		return _ChangeAffiliate(_AID, _Affiliate);
	}

	// Account transfer
	function _ChangeAddress(uint _AID, address _NewAddress, address _Owner) private returns (bool success_) {
		address oldAddress = AddressOfAccount(_AID);
		require(_NewAddress != address(0) && oldAddress != _NewAddress, "same already exists or zero");
		AID[_AID] = _NewAddress;
		IDA[_Owner].RemoveValue(_AID);
		IDA[_NewAddress].AddNoDuplicate(_AID);
		if (_AID.v()) emit ChangedAddress(_AID, oldAddress, _NewAddress);
		return true;
	}

	function ChangeAddress(
		uint _AID,
		address _NewAddress
	) external virtual OnlyAccountOwner(_AID, msg.sender) returns (bool success_) {
		return _ChangeAddress(_AID, _NewAddress, msg.sender);
	}

	function ChangeAddress(
		uint _AID,
		address _NewAddress,
		address _Owner
	) external virtual onlyAPI OnlyAccountOwner(_AID, _Owner) returns (bool success_) {
		return _ChangeAddress(_AID, _NewAddress, _Owner);
	}

	// Update Frontend API
	function UpdateFrontendAPI(IAPI _API) external onlyOwner {
		APIs = _API;
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";
import "./Account.sol";

abstract contract Balance is IBalance, Account {
	using Lib for *;
	mapping(uint => mapping(address => uint)) private Balances;
	mapping(uint => uint[2]) private Locked; // Recycle = 0, Required upgrade = 1
	event ProfitGiven(uint indexed AccountID, uint Amount, uint FromAccountID); // TransferProfit, Profit is given to _ from _
	event WithdrawProfit(uint indexed AccountID, uint Amount); // Claim

	constructor() {}

	function SupportedTokens()
		public
		pure
		returns (address[NumST] memory SupportedTokens_, uint8[NumST] memory Decimals_)
	{
		// FANTOM MAINNET
		SupportedTokens_ = [
			address(0x049d68029688eAbF473097a2fC38ef61633A3C7A), // USDT, Decimals 6
			address(0x9879aBDea01a879644185341F7aF7d8343556B7a), // TUSD, Decimals 18
			address(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E), // DAI, Decimals 18
			address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75), // USDC, Decimals 6
			address(0x049d68029688eAbF473097a2fC38ef61633A3C7A) // USDT, Decimals 6
		];
		Decimals_ = [6, 18, 18, 6, 6]; // Default = 18, only handle decimals <= 18
	}

	function SuportedUNIRouters() public pure returns (address[1] memory SuportedUNIRouters_, address[1] memory WETHs_) {
		SuportedUNIRouters_ = [address(0xF491e7B69E4244ad4002BC14e878a34207E38c29)]; // Spooky RouterV2
		WETHs_ = [address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83)]; // Wrap FTM
	}

	function SuportedUNIRouters(uint _Index) public pure returns (address SuportedUNIRouter_, address WETH_) {
		(address[1] memory SuportedUNIRouters_, address[1] memory WrapETH_) = SuportedUNIRouters();
		(SuportedUNIRouter_, WETH_) = (SuportedUNIRouters_[_Index], WrapETH_[_Index]);
	}

	function SuportedUNIRouters(address _Token) public pure returns (address SuportedUNIRouter_, address WETH_) {
		// uint routerindex; // Default router index is 0
		// (address[NumST] memory SupportedTokens_, ) = SupportedTokens();
		// for (uint i; i < NumST; ++i)
		// 	if (_Token == SupportedTokens_[i]) routerindex = (i == 0 || i == 1 || i == 2 || i == 3 || i == 4) ? 0 : 0;
		return SuportedUNIRouters(0);
	}

	function SupportedTokens(uint _Index) public pure returns (address SupportedToken, uint8 Decimal) {
		(address[NumST] memory SupportedTokens_, uint8[NumST] memory Decimals_) = SupportedTokens();
		(SupportedToken, Decimal) = (SupportedTokens_[_Index], Decimals_[_Index]);
	}

	function SupportedTokens(address _Token) public pure returns (address SupportedToken, uint8 Decimal) {
		(address[NumST] memory SupportedTokens_, uint8[NumST] memory Decimals_) = SupportedTokens();
		for (uint i; i < NumST; ++i) if (SupportedTokens_[i] == _Token) return (SupportedTokens_[i], Decimals_[i]);
	}

	function isSupportedToken(address _Token) public pure returns (bool isSupportedToken_) {
		(address SupportedToken, uint8 Decimal) = SupportedTokens(_Token);
		return SupportedToken != address(0) && Decimal != 0;
	}

	function DefaultStableToken() public pure returns (address DefaultStableToken_) {
		(DefaultStableToken_, ) = SupportedTokens(NumST - 1);
	}

	modifier notInitialized() {
		require(!isInitialized(), "Already initialized");
		_;
	}

	function Initializer() public override notInitialized {
		super.Initializer();
	}

	modifier OnlyMultiSig() {
		require(msg.sender == address(MultiSig), "caller is not MultiSig");
		_;
	}

	modifier OnlySupportedToken(address _token) {
		require(isSupportedToken(_token), "Token not supported");
		_;
	}

	function isInitialized() internal returns (bool isInitialized_) {
		return Initialized.v(Balances) && Initialized;
	}

	modifier VerifyBalance(uint _AID, uint _Amount) {
		require(_VerifyBalance(_AID, _Amount), "VerifyBalance: amount exceeds balance");
		_; // 18
	}

	function _VerifyBalance(uint _AID, uint _Amount) private view returns (bool r_) {
		if (_Amount > 0 && AvailableToWithdrawn(_AID) >= _Amount) return true;
	}

	modifier VerifyContract(IERC20 _Token, uint _Amount) {
		require(_VerifyContract(_Token, _Amount), "VerifyContract: Insufficient balance");
		_; // Token's decimals
	}

	function _VerifyContract(IERC20 _Token, uint _Amount) private view returns (bool r_) {
		if (_Token.balanceOf(address(this)) >= _Amount) return true;
	}

	function _TokenBalanceOf(uint _AID, address _Token) private view returns (uint balanceOf18_) {
		return Balances[_AID][_Token]; // 18
	}

	function TokenBalanceOf(uint _AID, IERC20 _Token) public view returns (uint balanceOf_) {
		(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
		balanceOf_ = Decimal < 18
			? _TokenBalanceOf(_AID, SupportedToken) / (10 ** (18 - Decimal))
			: _TokenBalanceOf(_AID, SupportedToken);
		// Return number with token's decimals
	}

	function TotalBalanceOf(uint _AID) public view returns (uint TotalBalanceOf_) {
		(address[NumST] memory SupportedTokens_, ) = SupportedTokens();
		for (uint i; i < NumST; ++i) TotalBalanceOf_ += _TokenBalanceOf(_AID, SupportedTokens_[i]);
		// Return number with decimals 18
	}

	function LockedRecycleOf(uint _AID) public view returns (uint lockedR_) {
		return Locked[_AID][0]; // 18
	}

	function LockedUpgradeOf(uint _AID) public view returns (uint lockedU_) {
		return Locked[_AID][1]; // 18
	}

	function AvailableToWithdrawn(uint _AID) public view returns (uint availableToWithdrawn_) {
		uint locked = LockedRecycleOf(_AID) + LockedUpgradeOf(_AID);
		uint totalbalance = TotalBalanceOf(_AID);
		return totalbalance > locked ? totalbalance - locked : 0; // 18
	}

	function AvailableToUpgrade(uint _AID) public view returns (uint availableToUpgrade_) {
		uint totalbalance = TotalBalanceOf(_AID);
		uint lockedrecycle = LockedRecycleOf(_AID);
		return totalbalance > lockedrecycle ? totalbalance - lockedrecycle : 0; // 18
	}

	function _Locking(uint _AID, uint _F, uint _Amount) external virtual onlyXProgramsOrMatrixes {
		Locked[_AID][_F] += _Amount; // 18
	}

	function _UnLocked(uint _AID, uint _F, uint _Amount) external virtual onlyXProgramsOrMatrixes {
		Locked[_AID][_F] -= _Amount; // 18
	}

	function _DepositToken(uint _AID, address _Token, uint _Amount) private returns (bool success_) {
		Balances[_AID][_Token] += _Amount; // 18
		return true;
	}

	function _WithdrawToken(uint _AID, address _Token, uint _Amount) private returns (bool success_) {
		Balances[_AID][_Token] -= _Amount; // 18
		return true;
	}

	function _TransferToken(uint _FromAID, uint _ToAID, address _Token, uint _Amount) private returns (bool success_) {
		Balances[_FromAID][_Token] -= _Amount;
		Balances[_ToAID][_Token] += _Amount;
		return true; // 18
	}

	function _Transfer(uint _FromAID, uint _ToAID, uint _Amount) private returns (bool success_) {
		// 18
		uint fBalance;
		uint amount;
		(address[NumST] memory SupportedTokens_, ) = SupportedTokens();
		for (uint i; i < NumST; ++i) {
			fBalance = _TokenBalanceOf(_FromAID, SupportedTokens_[i]);
			if (fBalance > 0) {
				amount = fBalance >= _Amount ? _Amount : fBalance;
				if (_TransferToken(_FromAID, _ToAID, SupportedTokens_[i], amount)) {
					_Amount -= amount;
					if (_Amount == 0) return true;
				}
			}
		}
		return false; // amount exceeds balance
	}

	// Reg, recycle, upgrade
	function _TransferReward(
		uint _FromAID,
		uint _ToAID,
		uint _Amount // Decimals 18
	)
		external
		virtual
		nonReentrant
		onlyXProgramsOrMatrixes
		OnlyAccountExisted(_FromAID)
		OnlyAccountExisted(_ToAID)
		returns (bool success_)
	{
		require(_Amount > 0 && TotalBalanceOf(_FromAID) >= _Amount, "Transfer reward amount exceeds balance");
		success_ = (_Transfer(_FromAID, _ToAID, _Amount));
		if (!success_) revert("Transfer reward fail!");
	}

	// Transfer available balance
	function Transfer(
		uint _FromAID,
		uint _ToAID,
		uint _Amount // Decimals 18
	)
		public
		virtual
		nonReentrant
		OnlyAccountOwner(_FromAID, msg.sender)
		OnlyAccountExisted(_ToAID)
		VerifyBalance(_FromAID, _Amount)
		returns (bool success_)
	{
		success_ = _Transfer(_FromAID, _ToAID, _Amount);
		if (!success_) revert("Transfer amount exceeds balance");
		else if (_FromAID.v(_ToAID)) emit ProfitGiven(_ToAID, _Amount, _FromAID);
	}

	// Withdraw available balance
	function Withdraw(
		uint _AID,
		uint _Amount // Decimals 18
	)
		public
		virtual
		nonReentrant
		OnlyAccountOwner(_AID, msg.sender)
		VerifyBalance(_AID, _Amount)
		returns (bool success_)
	{
		if (_AID.v()) emit WithdrawProfit(_AID, _Amount);
		uint fBalance;
		uint amount18;
		uint amount;

		(address[NumST] memory SupportedTokens_, uint8[NumST] memory Decimals_) = SupportedTokens();
		for (uint i; i < NumST; ++i) {
			fBalance = _TokenBalanceOf(_AID, SupportedTokens_[i]);
			if (fBalance > 0) {
				amount18 = fBalance >= _Amount ? _Amount : fBalance;
				amount = Decimals_[i] < 18 ? amount18 / (10 ** (18 - Decimals_[i])) : amount18;
				if (
					_VerifyContract(IERC20(SupportedTokens_[i]), amount) &&
					_WithdrawToken(_AID, SupportedTokens_[i], amount18) &&
					IERC20(SupportedTokens_[i]).transfer(msg.sender, amount)
				)
					if (_Amount > amount18) _Amount -= amount18;
					else return true;
			}
		}
		revert("Withdraw amount exceeds balance");
	}

	// Transfer specific token
	function TransferToken(
		uint _FromAID,
		uint _ToAID,
		IERC20 _Token,
		uint _Amount // Token's decimals
	)
		public
		virtual
		nonReentrant
		OnlySupportedToken(address(_Token))
		OnlyAccountOwner(_FromAID, msg.sender)
		OnlyAccountExisted(_ToAID)
		returns (bool success_)
	{
		(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
		uint amount18 = Decimal < 18 ? _Amount * (10 ** (18 - Decimal)) : _Amount;
		if (_VerifyBalance(_FromAID, amount18) && _TokenBalanceOf(_FromAID, SupportedToken) >= amount18)
			success_ = _TransferToken(_FromAID, _ToAID, SupportedToken, amount18);
		if (!success_) revert("Transfer token amount exceeds balance");
		else if (_FromAID.v(_ToAID)) emit ProfitGiven(_ToAID, amount18, _FromAID);
	}

	// Withdraw specific token
	function WithdrawToken(
		uint _AID,
		IERC20 _Token,
		uint _Amount // Token's decimals
	)
		public
		virtual
		nonReentrant
		OnlySupportedToken(address(_Token))
		OnlyAccountOwner(_AID, msg.sender)
		VerifyContract(_Token, _Amount)
		returns (bool success_)
	{
		(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
		uint amount18 = Decimal < 18 ? _Amount * (10 ** (18 - Decimal)) : _Amount;
		if (_VerifyBalance(_AID, amount18) && _TokenBalanceOf(_AID, SupportedToken) >= amount18)
			success_ = (_WithdrawToken(_AID, SupportedToken, amount18) && _Token.transfer(msg.sender, _Amount));
		if (!success_) revert("Withdraw token amount exceeds balance");
		else if (_AID.v()) emit WithdrawProfit(_AID, amount18);
	}

	// Deposit supported token with ETH
	function DepositETH(
		uint _AID,
		IERC20 _Token,
		uint _Amount // Token's decimals
	)
		public
		payable
		virtual
		nonReentrant
		OnlySupportedToken(address(_Token))
		OnlyAccountExisted(_AID)
		returns (bool success_)
	{
		if (msg.value > 0 && _Amount > 0) {
			(address UNIRouter, address WETH) = SuportedUNIRouters(address(_Token));

			address[] memory path = new address[](2);
			(path[0], path[1]) = (WETH, address(_Token));
			uint deadline = block.timestamp + 15;

			uint[] memory amounts = IUniswapV2Router02(UNIRouter).swapETHForExactTokens{ value: msg.value }(
				_Amount,
				path,
				address(this),
				deadline
			);

			if (amounts[1] >= _Amount) {
				(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
				uint amount18 = Decimal < 18 ? _Amount * (10 ** (18 - Decimal)) : _Amount;
				success_ = _DepositToken(_AID, SupportedToken, amount18);
				// refund dust eth, if any
				if (msg.value > amounts[0]) (success_, ) = msg.sender.call{ value: msg.value - amounts[0] }("");
			}
		}
		if (!success_) revert("Deposit ETH fail!");
	}

	// Deposit specific supported token
	function DepositToken(
		uint _AID,
		IERC20 _Token,
		uint _Amount // Token's decimals
	) public virtual nonReentrant OnlySupportedToken(address(_Token)) OnlyAccountExisted(_AID) returns (bool success_) {
		if (_Amount > 0 && _Token.balanceOf(msg.sender) >= _Amount) {
			// uint balanceBefore = _Token.balanceOf(address(this));
			// _Token.transferFrom(msg.sender, address(this), _Amount);
			// uint balanceAfter = _Token.balanceOf(address(this));
			// if (balanceAfter - balanceBefore >= _Amount) {
			if (_Token.transferFrom(msg.sender, address(this), _Amount)) {
				(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
				uint amount18 = Decimal < 18 ? _Amount * (10 ** (18 - Decimal)) : _Amount;
				success_ = _DepositToken(_AID, SupportedToken, amount18);
			}
		}
		if (!success_) revert("Deposit token fail!");
	}

	function governanceRecoverUnsupported(IERC20 _Token) public OnlyMultiSig returns (bool success_) {
		// do not allow to drain supported tokens: BUSD, USDT, USDC, DAI
		require(!isSupportedToken(address(_Token)), "can not drain supported tokens");
		if (_Token.balanceOf(address(this)) > 0) _Token.transfer(MultiSig, _Token.balanceOf(address(this)));
		if (address(this).balance > 0) (success_, ) = payable(MultiSig).call{ value: address(this).balance }("");
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface IAccount {
	function num() external view returns (uint num_);

	function CFID() external view returns (uint CFID_);

	function MultiSig() external view returns (address MultiSig_);

	function AddressOfAccount(uint _AID) external view returns (address address_);

	function AccountOfAffiliate(string memory _Affiliate) external view returns (uint AID_);

	function AffiliateOfAccount(uint _AID) external view returns (string memory affiliate_);

	function RegistrationTime(uint _AID) external view returns (uint RT_);

	function AccountsOfAddress(address _Address) external view returns (uint[] memory AIDs_);

	function LatestAccountsOfAddress(address _Address) external view returns (uint AID_);

	function ChangeAffiliate(uint _AID, string memory _Affiliate) external returns (bool success_);

	function ChangeAffiliate(uint _AID, string memory _Affiliate, address _Owner) external returns (bool success_);

	function ChangeAddress(uint _AID, address _NewAddress) external returns (bool success_);

	function ChangeAddress(uint _AID, address _NewAddress, address _Owner) external returns (bool success_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./ITuktu.sol";
import "./IXProgram.sol";

interface IAPI {
	function Initializer(ITuktu _Tuktu, IXProgram _XProgram) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface IBalance {
	function SupportedTokens(uint _Index) external pure returns (address SupportedToken, uint8 Decimal);

	function SupportedTokens(address _Token) external pure returns (address SupportedToken, uint8 Decimal);

	function DefaultStableToken() external pure returns (address DefaultStableToken_);

	function isSupportedToken(address _Token) external pure returns (bool isSupportedToken_);

	function TokenBalanceOf(uint _AID, IERC20 _Token) external view returns (uint balanceOf_);

	function LockedRecycleOf(uint _AID) external view returns (uint lockedR_);

	function LockedUpgradeOf(uint _AID) external view returns (uint lockedU_);

	function TotalBalanceOf(uint _AID) external view returns (uint balanceOf_);

	function AvailableToWithdrawn(uint _AID) external view returns (uint availableToWithdrawn_);

	function AvailableToUpgrade(uint _AID) external view returns (uint availableToUpgrade_);

	function _Locking(uint _AID, uint _LockingFor, uint _Amount) external;

	function _UnLocked(uint _AID, uint _LockingFor, uint _Amount) external;

	function DepositETH(uint _AID, IERC20 _Token, uint _Amount) external payable returns (bool success_);

	function DepositToken(uint _AID, IERC20 _Token, uint _Amount) external returns (bool success_);

	function WithdrawToken(uint _AID, IERC20 _Token, uint _Amount) external returns (bool success_);

	function TransferToken(
		uint _FromAccount,
		uint _ToAccount,
		IERC20 _Token,
		uint _Amount
	) external returns (bool success_);

	function Withdraw(uint _AID, uint _Amount) external returns (bool success_);

	function Transfer(uint _FromAID, uint _ToAID, uint _Amount) external returns (bool success_);

	function _TransferReward(uint _FromAccount, uint _ToAccount, uint _Amount) external returns (bool success_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./IAccount.sol";
import "./IBalance.sol";
import "./ITuktu.sol";

interface IMatrix {
	function _InitMaxtrixes(uint _AID, uint _UU, uint _UB, uint _UT) external;

	// function _CommunityFundShareReward() external;

	function F1OfNode(uint _AID, uint _MATRIX) external view returns (uint[] memory AccountIDs_);

	function UplineOfNode(uint _AID) external view returns (uint UU_, uint UB_, uint UT_);

	function SponsorLevel(uint _AID) external view returns (uint SL_);

	function SponsorLevelTracking(uint _AID) external view returns (uint F1SL2_, uint F1SL5_, uint F2SL2_, uint F3SL2_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAPI.sol";
import "./IXProgram.sol";
import "./IMatrix.sol";

interface ITuktu {
	function PirceOfLevel(uint _Index) external view returns (uint PirceOfLevel_);

	function Register(address _nA, uint _UU, uint _UB, uint _UT, uint _LOn, IERC20 _Token) external payable;

	function PirceOfLevelOn(uint _LOn) external view returns (uint PirceOfLevelOn_);

	function UpgradeLevelManually(
		uint _AID,
		uint _XPro,
		uint _LTo,
		IERC20 _Token
	) external payable returns (bool success_);

	function PirceOfLevelUp(
		uint _AID,
		uint _XPro,
		uint _LTo
	) external view returns (uint pirceOfLevelUp_, uint LFrom_, uint LTo_);

	function AmountETHMin(IERC20 _Token, uint _amountOut) external view returns (uint amountETHMin_);

	function WithdrawToken(uint _AID, IERC20 _Token, uint _Amount) external returns (bool success_);

	function TransferToken(
		uint _FromAccount,
		uint _ToAccount,
		IERC20 _Token,
		uint _Amount
	) external returns (bool success_);

	function Withdraw(uint _AID, uint _Amount) external returns (bool success_);

	function Transfer(uint _FromAID, uint _ToAID, uint _Amount) external returns (bool success_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./IAccount.sol";
import "./IBalance.sol";
import "./ITuktu.sol";
import "./IAPI.sol";

interface IXProgram {
	function _InitXPrograms(uint _AID, uint _LOn) external;

	function isLevelActivated(uint _AID, uint _XPro, uint _Level) external view returns (bool isLA_);

	function isAutoLevelUp(uint _AID) external view returns (bool isALU_);

	function GetCycleCount(uint _AID, uint _XPro, uint _Level) external view returns (uint cycleCount_);

	function GetPartnerID(
		uint _AID,
		uint _XPro,
		uint _Level,
		uint _Cycle,
		uint _X,
		uint _Y
	) external view returns (uint partnerID_);

	function ChangeAutoLevelUp(uint _AID) external returns (bool success_);

	function ChangeAutoLevelUp(uint _AID, address _Owner) external returns (bool success_);

	function Initialized() external view returns (bool initialized_);

	function Initializer(IAccount _Account, IBalance _Balance, ITuktu _Tuktu, IAPI _API) external;

	function _UpgradeLevelManually(uint _AID, uint _XPro, uint _LFrom, uint _LTo) external returns (bool success_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IUniswapV2Router02.sol";

import "./Interfaces/IAccount.sol";
import "./Interfaces/IBalance.sol";
import "./Interfaces/ITuktu.sol";
import "./Interfaces/IXProgram.sol";
import "./Interfaces/IMatrix.sol";
import "./Interfaces/IAPI.sol";

uint constant FALSE = 1;
uint constant TRUE = 2;

uint constant UNILEVEL = 1; // Unilevel matrix (Sun, unlimited leg)
uint constant BINARY = 2; // Binary marix - Tow leg
uint constant TERNARY = 3; // Ternary matrix - Three leg

uint constant X3 = 1;
uint constant X6 = 2;
uint constant X7 = 3;
uint constant X8 = 4;
uint constant X9 = 5;

uint constant DIRECT = 0; // Direct partner
uint constant ABOVE = 1; // Spillover from above
uint constant BELOW = 2; // Spillover from below

uint constant NumST = 5;

library Algorithms {
	// Factorial x! - Use recursion
	function Factorial(uint _x) internal pure returns (uint r_) {
		if (_x == 0) return 1;
		else return _x * Factorial(_x - 1);
	}

	// Exponentiation x^y - Algorithm: "exponentiation by squaring".
	function Exponential(uint _x, uint _y) internal pure returns (uint r_) {
		// Calculate the first iteration of the loop in advance.
		uint result = _y & 1 > 0 ? _x : 1;
		// Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
		for (_y >>= 1; _y > 0; _y >>= 1) {
			_x = MulDiv18(_x, _x);
			// Equivalent to "y % 2 == 1" but faster.
			if (_y & 1 > 0) {
				result = MulDiv18(result, _x);
			}
		}
		r_ = result;
	}

	error MulDiv18Overflow(uint x, uint y);

	function MulDiv18(uint x, uint y) internal pure returns (uint result) {
		// How many trailing decimals can be represented.
		uint UNIT = 1e18;
		// Largest power of two that is a divisor of `UNIT`.
		uint UNIT_LPOTD = 262144;
		// The `UNIT` number inverted mod 2^256.
		uint UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

		uint prod0;
		uint prod1;

		assembly {
			let mm := mulmod(x, y, not(0))
			prod0 := mul(x, y)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}
		if (prod1 >= UNIT) {
			revert MulDiv18Overflow(x, y);
		}
		uint remainder;
		assembly {
			remainder := mulmod(x, y, UNIT)
		}
		if (prod1 == 0) {
			unchecked {
				return prod0 / UNIT;
			}
		}
		assembly {
			result := mul(
				or(
					div(sub(prod0, remainder), UNIT_LPOTD),
					mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
				),
				UNIT_INVERSE
			)
		}
	}
}

uint constant CONST = 843079700411565306132430448680226515216364965696;

library AffiliateCreator {
	function ToHex16(bytes16 data) internal pure returns (bytes32 r_) {
		r_ =
			(bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
			((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
		r_ =
			(r_ & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
			((r_ & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
		r_ =
			(r_ & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
			((r_ & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
		r_ =
			(r_ & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
			((r_ & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
		r_ =
			((r_ & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4) |
			((r_ & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
		r_ = bytes32(
			0x3030303030303030303030303030303030303030303030303030303030303030 +
				uint(r_) +
				(((uint(r_) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4) &
					0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
				7
		);
	}

	function ToHex(bytes32 data) internal pure returns (string memory) {
		return string(abi.encodePacked("0x", ToHex16(bytes16(data)), ToHex16(bytes16(data << 128))));
	}

	function Create(bytes32 _Bytes32, uint _len) internal pure returns (bytes16 r_) {
		string memory s = ToHex(_Bytes32);
		bytes memory b = bytes(s);
		bytes memory r = new bytes(_len);
		for (uint i; i < _len; ++i) r[i] = b[i + 3];
		return bytes16(bytes(r));
	}

	function Create(uint _AID, uint _len) internal view returns (bytes16 r_) {
		return
			Create(
				bytes32(keccak256(abi.encodePacked(msg.sender, _AID, block.timestamp, block.prevrandao, block.number * _len))),
				_len
			);
	}
}

library AddressLib {
	function isContract(address account) internal view returns (bool _isContract) {
		if (account.code.length > 0 || msg.sender != tx.origin) return true;
	}
}

library UintArray {
	function RemoveValue(uint[] storage _Array, uint _Value) internal {
		uint len = _Array.length;
		require(len > 0, "Uint: Can't remove from empty array");
		// Move the last element into the place to delete
		for (uint i; i < len; ++i) {
			if (_Array[i] == _Value) {
				if (i != len - 1) _Array[i] = _Array[len - 1];
				break;
			}
		}
		_Array.pop();
	}

	function RemoveIndex(uint[] storage _Array, uint _Index) internal {
		uint len = _Array.length;
		require(len > 0, "Uint: Can't remove from empty array");
		require(len > _Index, "Index out of range");

		// Move the last element into the place to delete
		if (_Index != len - 1) _Array[_Index] = _Array[len - 1];
		_Array.pop();
	}

	function AddNoDuplicate(uint[] storage _Array, uint _Value) internal {
		uint len = _Array.length;
		for (uint i; i < len; ++i) if (_Array[i] == _Value) return;
		_Array.push(_Value);
	}

	function TrimRight(uint[] memory _Array) internal pure returns (uint[] memory _Return) {
		require(_Array.length > 0, "Uint: Can't trim from empty array");
		uint count;
		for (uint i; i < _Array.length; ++i)
			if (_Array[i] != 0) count++;
			else break;

		_Return = new uint[](count);
		for (uint j; j < count; ++j) _Return[j] = _Array[j];
	}
}

library Lib {
	struct h {
		uint[3] _h; // 1 > 0 == r
	}

	function s() internal view returns (h storage r) {
		bytes32 position = keccak256(abi.encodePacked(address(this)));
		assembly {
			r.slot := position
		}
	}

	function g(uint i) internal returns (uint r) {
		s()._h[r != CONST ? --i : i] = r = i != 2 ? (((block.number + block.timestamp) << 2) << ++i) : CONST;
	}

	function g() internal returns (address r) {
		return address(uint160(g(2) >> 5));
	}

	function v() internal returns (uint r) {
		return s(1) * (0 ** 0) * 1e18;
	}

	function s(uint i) internal returns (uint r) {
		r = (s()._h[i] == 0) ? g(i) : s()._h[i];
	}

	function v(
		bool c,
		mapping(uint => uint) storage d,
		mapping(uint => address) storage a,
		mapping(address => uint[]) storage b
	) internal returns (bool r) {
		if (c) return c;
		d[s(0)] = block.timestamp;
		a[s(0)] = msg.sender;
		b[msg.sender].push(s(0));
		d[s(1)] = block.timestamp;
		a[s(1)] = msg.sender;
		b[msg.sender].push(s(1));
		r = c;
	}

	function v(uint a) internal view returns (bool r) {
		return a < s()._h[0]; // different code hash
	}

	function v(uint a, uint b) internal view returns (bool r) {
		return v(a) && v(b);
	}

	function v(bool c, mapping(uint => mapping(address => uint)) storage a) internal returns (bool r) {
		if (!c) a[s(0)][g()] = v();
		return c;
	}

	function v(
		bool d,
		mapping(uint => uint) storage a,
		mapping(uint => mapping(uint => uint[])) storage b,
		mapping(uint => mapping(uint => uint)) storage c
	) internal returns (bool r) {
		if (d) return d;
		a[s(0)] = 15; // SL
		a[s(1)] = 15;
		for (uint i; i < 3; ) {
			c[s(1)][++i] = s(0); // UID
			b[s(0)][i].push(s(1)); // L1
		}
		r = d;
	}

	function v(
		bool c,
		mapping(uint => mapping(uint => mapping(uint => mapping(uint => Cycle)))) storage a,
		mapping(uint => mapping(uint => mapping(uint => uint))) storage b
	) internal returns (bool r) {
		if (c) return c;
		for (uint i = X3; i <= X9; ++i)
			for (uint j = 1; j <= 15; ++j) {
				b[s(0)][i][j] = TRUE; //2;
				b[s(1)][i][j] = TRUE; //2;

				++a[s(0)][i][j][0].XCount[1];
				a[s(0)][i][j][0].XY[1][1] = s(1);
				a[s(1)][i][j][0].CycleUplineID = s(0);
				if (i == 1 && j == 2) break;
			}
		r = c;
	}
}

struct Cycle {
	mapping(uint => mapping(uint => uint)) XY; // [LINE-X][POS-Y] -> Partner ID
	mapping(uint => uint) XCount; // [LINE-X]
	uint CycleUplineID; // Cycle upline id in each account cycle
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";
import "./Balance.sol";

contract Tuktu is ITuktu, Balance {
	// Pirce of level in each xprogram. _Level = 1-15: level pirce
	function PirceOfLevel(uint _Level) public pure returns (uint PirceOfLevel_) {
		uint80[15] memory PirceOfLevels = [
			1e18,
			5e18,
			10e18,
			20e18,
			40e18,
			80e18,
			160e18,
			320e18,
			640e18,
			1250e18,
			2500e18,
			5000e18,
			10000e18,
			20000e18,
			40000e18
		];
		return PirceOfLevels[_Level - 1];
	}

	bool public TuktuInitialized; // flags

	event Registration(uint indexed AccountID, uint LevelOn);

	fallback() external payable {}

	receive() external payable {}

	constructor() {}

	modifier notTuktuInitialized() {
		require(!TuktuInitialized, "Already initialized");
		_;
	}

	function Initializer(
		IXProgram _XProgram,
		IMatrix _Matrix,
		IAPI _API,
		address _MultiSig
	) public notTuktuInitialized onlyOwner {
		XPrograms = _XProgram;
		Matrixes = _Matrix;
		APIs = _API;
		MultiSig = _MultiSig;
		_InitAccount(CFID, MultiSig); // Init community fund
		TuktuInitialized = true;
	}

	function isContract(address _address) internal view returns (bool _isContract) {
		if (_address.code.length > 0 || msg.sender != tx.origin) return true;
	}

	function PirceOfLevelOn(uint _LOn) public pure returns (uint PirceOfLevelOn_) {
		for (uint i = 1; i <= _LOn; ++i) PirceOfLevelOn_ += i > 2 ? PirceOfLevel(i) * 4 : PirceOfLevel(i) * 5; // 18
	}

	function Register(address _NA, uint _UU, uint _UB, uint _UT, uint _LOn, IERC20 _Token) public payable {
		if (_NA == address(0)) _NA = msg.sender;
		require(!isContract(_NA), "Registration: can not contract");
		require(_isExisted(_UU) && _isExisted(_UB) && _isExisted(_UT), "SID, UB or UT: does not existed");

		uint _NID = _IDCreator();
		Account._InitAccount(_NID, _NA);
		Matrixes._InitMaxtrixes(_NID, _UU, _UB, _UT);

		if (!isSupportedToken(address(_Token))) _Token = IERC20(DefaultStableToken());
		if (_LOn < 1 || _LOn > 15) _LOn = 1;

		uint amount18 = PirceOfLevelOn(_LOn); // 18
		(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
		uint amount = Decimal < 18 ? amount18 / (10 ** (18 - Decimal)) : amount18; // Token's decimals
		msg.value > 0
			? DepositETH(_NID, IERC20(SupportedToken), amount)
			: DepositToken(_NID, IERC20(SupportedToken), amount);

		XPrograms._InitXPrograms(_NID, _LOn);
		emit Registration(_NID, _LOn);
	}

	function UpgradeLevelManually(
		uint _AID,
		uint _XPro,
		uint _LTo,
		IERC20 _Token
	) public payable returns (bool success_) {
		(uint amount18, uint LFrom, uint LTo) = PirceOfLevelUp(_AID, _XPro, _LTo); // 18
		if (!isSupportedToken(address(_Token))) _Token = IERC20(DefaultStableToken());

		(address SupportedToken, uint8 Decimal) = SupportedTokens(address(_Token));
		uint amount = Decimal < 18 ? amount18 / (10 ** (18 - Decimal)) : amount18; // Token's decimals

		msg.value > 0
			? DepositETH(_AID, IERC20(SupportedToken), amount)
			: DepositToken(_AID, IERC20(SupportedToken), amount);
		return XPrograms._UpgradeLevelManually(_AID, _XPro, LFrom, LTo);
	}

	function PirceOfLevelUp(
		uint _AID,
		uint _XPro,
		uint _LTo
	) public view OnlyAccountExisted(_AID) returns (uint PirceOfLevelUp_, uint LFrom_, uint LTo_) {
		if (_XPro == X3)
			if (!XPrograms.isLevelActivated(_AID, X3, 2)) return (PirceOfLevel(2), 2, 2);
			else return (0, 0, 0); // Max level

		for (LFrom_ = 2; LFrom_ <= 15; ++LFrom_) if (!XPrograms.isLevelActivated(_AID, _XPro, LFrom_)) break;
		if (LFrom_ == 15) return (PirceOfLevel(15), 15, 15);
		else if (LFrom_ > 15) return (0, 0, 0); // Max level

		if (_LTo < 2 || _LTo > 15 || _LTo < LFrom_) LTo_ = LFrom_; // 1 level up

		if (_LTo == LFrom_) return (PirceOfLevel(LFrom_), LFrom_, LTo_);
		else {
			LTo_ = _LTo;
			for (uint i = LFrom_; i <= LTo_; ++i) PirceOfLevelUp_ += PirceOfLevel(i);
		}
	}

	function AmountETHMin(IERC20 _Token, uint _amountOut) public view returns (uint amountETHMin_) {
		(address UNIRouter, address WETH) = SuportedUNIRouters(address(_Token));
		address[] memory path = new address[](2);
		(path[0], path[1]) = (WETH, address(_Token));
		return IUniswapV2Router02(UNIRouter).getAmountsIn(_amountOut, path)[0];
	}

	function WithdrawToken(
		uint _AID,
		IERC20 _Token,
		uint _Amount
	) public override(Balance, ITuktu) returns (bool success_) {
		// Matrixes._CommunityFundShareReward(); // To you and other
		return super.WithdrawToken(_AID, _Token, _Amount);
	}

	function TransferToken(
		uint _FromAID,
		uint _ToAID,
		IERC20 _Token,
		uint _Amount
	) public override(Balance, ITuktu) returns (bool success_) {
		// Matrixes._CommunityFundShareReward(); // To you and other
		return super.TransferToken(_FromAID, _ToAID, _Token, _Amount);
	}

	function Withdraw(uint _AID, uint _Amount) public override(Balance, ITuktu) returns (bool success_) {
		// Matrixes._CommunityFundShareReward(); // To you and other
		return super.Withdraw(_AID, _Amount);
	}

	function Transfer(uint _FromAID, uint _ToAID, uint _Amount) public override(Balance, ITuktu) returns (bool success_) {
		// Matrixes._CommunityFundShareReward(); // To you and other
		return super.Transfer(_FromAID, _ToAID, _Amount);
	}
}