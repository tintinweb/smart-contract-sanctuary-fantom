/**
 *Submitted for verification at FtmScan.com on 2022-07-29
*/

/**
 *Submitted for verification at FtmScan.com on 2022-03-28
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/network/$.sol


pragma solidity 0.8.9;

library $
{
    // ftmmain
    address constant LQDR = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    address constant XLQDR = 0x3Ae658656d1C526144db371FaEf2Fff7170654eE;

    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant BOO = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address constant SPIRIT = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    address constant LINSPIRIT = 0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C;
    address constant SPELL = 0x468003B688943977e6130F4F68F23aad939a1040;
    address constant BEETS = 0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e;
    address constant DEUS = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;
    address constant HND = 0x10010078a54396F62c96dF8532dc2B4847d47ED3;
    address constant LIHND = 0xA147268f35Db4Ae3932eabe42AF16C36A8B89690;

    address constant SPIRITSWAP_UNISWAP_V2_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address constant SPOOKYSWAP_UNISWAP_V2_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address constant BEETHOVEN_BALANCER_V2_VAULT = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;
    bytes32 constant BEETHOVEN_BALANCER_V2_FTM_BEETS_WP2T = 0xcde5a11a4acb4ee4c805352cec57e236bdbc3837000200000000000000000019;
    bytes32 constant BEETHOVEN_BALANCER_V2_SPIRIT_LINSPIRIT_SP = 0x30a92a4eeca857445f41e4bb836e64d66920f1c0000200000000000000000071;
    bytes32 constant BEETHOVEN_BALANCER_V2_LQDR_cLQDR_SPP = 0xeadcfa1f34308b144e96fcd7a07145e027a8467d000000000000000000000331;
    bytes32 constant BEETHOVEN_BALANCER_V2_HND_LIHND_SP = 0x8f6a658056378558ff88265f7c9444a0fb4db4be0002000000000000000002b8;
    bytes32 constant BEETHOVEN_BALANCER_V2_FTM_USDC_HND_WP = 0xd57cda2caebb9b64bb88905c4de0f0da217a77d7000100000000000000000073;
}


// File contracts/interop/BalancerV2.sol


pragma solidity 0.8.9;

interface IVault
{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

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

    function swap(SingleSwap memory _singleSwap, FundManagement memory _funds, uint256 _limit, uint256 _deadline) external payable returns (uint256 _amountCalculated);
}

interface IRateProvider
{
    function getRate() external view returns (uint256 _rate);
}


// File contracts/interop/UniswapV2.sol


pragma solidity 0.8.9;

interface Factory
{
    function getPair(address _tokenA, address _tokenB) external view returns (address _pair);
}

interface Router02
{
    function factory() external view returns (address _factory);
/*
    function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);
*/

    function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
}


// File contracts/IOracle.sol


pragma solidity 0.8.9;

interface IOracle
{
    function consultCurrentPrice(address _pair, address _token, uint256 _amountIn) external view returns (uint256 _amountOut);
    function consultAveragePrice(address _pair, address _token, uint256 _amountIn) external view returns (uint256 _amountOut);

    function updateAveragePrice(address _pair) external;
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/interop/LiquidDriver.sol


pragma solidity 0.8.9;

interface MasterChefV2
{
    function LQDR() external view returns (address _LQDR);
    function pendingLqdr(uint256 _pid, address _user) external view returns (uint256 _pending);

    function deposit(uint256 _pid, uint256 _amount, address _to) external;
    function withdraw(uint256 _pid, uint256 _amount, address _to) external;
    function harvest(uint256 _pid, address _to) external;
    function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;
    function emergencyWithdraw(uint256 _pid, address _to) external;
}

interface VoteEscrow
{
    function locked(address _account) external view returns (int128 _amount, uint256 _unlockTime);

    function create_lock(uint256 _amount, uint256 _unlockTime) external;
    function deposit_for(address _account, uint256 _amount) external;
    function increase_unlock_time(uint256 _unlockTime) external;
    function withdraw() external;
}

interface FeeDistribution
{
    function tokens(uint256 _index) external view returns (address _token);

    function claim() external returns (uint256[7] memory _amounts);
}


// File contracts/DelayedActionGuard.sol


pragma solidity 0.8.9;

abstract contract DelayedActionGuard
{
    uint256 private constant DEFAULT_WAIT_INTERVAL = 1 days;
    uint256 private constant DEFAULT_OPEN_INTERVAL = 1 days;

    struct DelayedAction {
        uint256 release;
        uint256 expiration;
    }

    mapping (address => mapping (bytes32 => DelayedAction)) private actions_;

    modifier delayed()
    {
        bytes32 _actionId = keccak256(msg.data);
        DelayedAction storage _action = actions_[msg.sender][_actionId];
        require(_action.release <= block.timestamp && block.timestamp < _action.expiration, "invalid action");
        delete actions_[msg.sender][_actionId];
        emit ExecuteDelayedAction(msg.sender, _actionId);
        _;
    }

    function announceDelayedAction(bytes calldata _data) external
    {
        bytes4 _selector = bytes4(_data);
        bytes32 _actionId = keccak256(_data);
        (uint256 _wait, uint256 _open) = _delayedActionIntervals(_selector);
        uint256 _release = block.timestamp + _wait;
        uint256 _expiration = _release + _open;
        actions_[msg.sender][_actionId] = DelayedAction({ release: _release, expiration: _expiration });
        emit AnnounceDelayedAction(msg.sender, _actionId, _selector, _data, _release, _expiration);
    }

    function _delayedActionIntervals(bytes4 _selector) internal pure virtual returns (uint256 _wait, uint256 _open)
    {
        _selector;
        return (DEFAULT_WAIT_INTERVAL, DEFAULT_OPEN_INTERVAL);
    }

    event AnnounceDelayedAction(address indexed _sender, bytes32 indexed _actionId, bytes4 indexed _selector, bytes _data, uint256 _release, uint256 _expiration);
    event ExecuteDelayedAction(address indexed _sender, bytes32 indexed _actionId);
}


// File contracts/PerpetualEscrowToken.sol


pragma solidity 0.8.9;





contract PerpetualEscrowToken is ERC20, Ownable, ReentrancyGuard, DelayedActionGuard
{
    using SafeERC20 for IERC20;

    uint256 constant WEEK = 7 days;
    uint256 constant MAXTIME = 730 days; // 2 years

    uint256 private unlockTime_;

    address public extension;

    bool public emergencyMode;

    modifier onlyExtension()
    {
        require(msg.sender == extension, "access denied");
        _;
    }

    modifier inEmergency()
    {
        require(emergencyMode, "not available");
        _;
    }

    modifier nonEmergency()
    {
        require(!emergencyMode, "not available");
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        uint256 _unlockTime = ((block.timestamp + MAXTIME) / WEEK) * WEEK;
        IERC20($.LQDR).safeApprove($.XLQDR, 1);
        VoteEscrow($.XLQDR).create_lock(1, _unlockTime);
        unlockTime_ = _unlockTime;
        _mint(address(1), 1);
    }

    function totalReserve() public view returns (uint256 _amount)
    {
        if (emergencyMode) {
            return IERC20($.LQDR).balanceOf(address(this));
        } else {
            (int128 _value,) = VoteEscrow($.XLQDR).locked(address(this));
            return uint256(uint128(_value));
        }
    }

    function calcSharesFromAmount(uint256 _amount) public view returns (uint256 _shares)
    {
        return _amount * totalSupply() / totalReserve();
    }

    function calcAmountFromShares(uint256 _shares) public view returns (uint256 _amount)
    {
        return _shares * totalReserve() / totalSupply();
    }

    function deposit(uint256 _amount, uint256 _minShares) external nonReentrant nonEmergency
    {
        uint256 _shares = _amount * totalSupply() / totalReserve();
        require(_shares >= _minShares, "high slippage");
        _mint(msg.sender, _shares);
        IERC20($.LQDR).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20($.LQDR).safeApprove($.XLQDR, _amount);
        VoteEscrow($.XLQDR).deposit_for(address(this), _amount);
    }

    function withdraw(uint256 _shares, uint256 _minAmount) external nonReentrant inEmergency
    {
        uint256 _amount = _shares * totalReserve() / totalSupply();
        require(_amount >= _minAmount, "high slippage");
        _burn(msg.sender, _shares);
        IERC20($.LQDR).safeTransfer(msg.sender, _amount);
    }

    function burn(uint256 _amount) external nonReentrant
    {
        _burn(msg.sender, _amount);
    }

    function _call(address _target, bytes calldata _calldata) external payable onlyExtension returns (bool _success, bytes memory _resultdata)
    {
        require(_target != $.XLQDR, "forbidden target");
        return _target.call{value: msg.value}(_calldata);
    }

    function enterEmergencyMode() external onlyOwner nonEmergency
    {
        require(block.timestamp >= unlockTime_, "not available");
        emergencyMode = true;
        VoteEscrow($.XLQDR).withdraw();
        emit EmergencyDeclared();
    }

    function setExtension(address _newExtension) external onlyOwner delayed
    {
        address _oldExtension = extension;
        extension = _newExtension;
        emit UpdateExtension(_oldExtension, _newExtension);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override
    {
        if (emergencyMode) return;
        uint256 _unlockTime = ((block.timestamp + MAXTIME) / WEEK) * WEEK;
        if (_unlockTime > unlockTime_) {
            try VoteEscrow($.XLQDR).increase_unlock_time(_unlockTime) {
                unlockTime_ = _unlockTime;
            } catch (bytes memory _data) {
                _from; _to; _amount; _data;
            }
        }
    }

    event EmergencyDeclared();
    event UpdateExtension(address _oldExtension, address _newExtension);
}


// File contracts/PerpetualEscrowTokenReceiver.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

contract ConstantNeo {
    function updateRewardPerSec(uint256) public {}
}




contract PerpetualEscrowTokenReceiver is Ownable, ReentrancyGuard, DelayedActionGuard
{
    using SafeERC20 for IERC20;

    uint256 constant DEFAULT_MINIMAL_GULP_FACTOR = 80e16; // 80%
    uint256 constant DEFAULT_BURNING_RATE = 80e16; // 80%

    enum SwapType { NONE, UNISWAP_V2, BALANCER_V2 }

    struct SwapInfo {
        uint256 index;
        uint256 minAmount;
        SwapType swapType;
        // UniswapV2
        address router;
        address[] path;
        // BalancerV2
        address vault;
        IVault.SingleSwap swap;
        IVault.FundManagement funds;
    }

    uint public fee;
    address public recipient;

    address public treasury;

    address public oracle;
    uint256 public minimalGulpFactor = DEFAULT_MINIMAL_GULP_FACTOR;

    uint256 public burningRate = DEFAULT_BURNING_RATE;

    address[] public tokens;
    mapping(address => SwapInfo) public swapInfo;

    constructor(/*address _escrowToken,*/ address _recipient, address _treasury, address _oracle)
    {
        // escrowToken = _escrowToken;
        recipient = _recipient;
        treasury = _treasury;
        oracle = _oracle;
        fee = 50;
        _addUniswapV2Token($.BOO, 1, $.SPOOKYSWAP_UNISWAP_V2_ROUTER, $.WFTM);
        _addUniswapV2Token($.SPELL, 1, $.SPOOKYSWAP_UNISWAP_V2_ROUTER, $.WFTM);
        _addBalancerV2Token($.BEETS, 1, $.BEETHOVEN_BALANCER_V2_VAULT, $.BEETHOVEN_BALANCER_V2_FTM_BEETS_WP2T, $.WFTM);
        _addBalancerV2Token($.LINSPIRIT, 1, $.BEETHOVEN_BALANCER_V2_VAULT, $.BEETHOVEN_BALANCER_V2_SPIRIT_LINSPIRIT_SP, $.SPIRIT);
        _addUniswapV2Token($.SPIRIT, 1, $.SPIRITSWAP_UNISWAP_V2_ROUTER, $.WFTM);
        _addUniswapV2Token($.DEUS, 1, $.SPIRITSWAP_UNISWAP_V2_ROUTER, $.WFTM);
        _addBalancerV2Token($.LIHND, 1, $.BEETHOVEN_BALANCER_V2_VAULT, $.BEETHOVEN_BALANCER_V2_HND_LIHND_SP, $.HND);
        _addBalancerV2Token($.HND, 1, $.BEETHOVEN_BALANCER_V2_VAULT, $.BEETHOVEN_BALANCER_V2_FTM_USDC_HND_WP, $.WFTM);

        _addUniswapV2Token($.LQDR, 1, $.SPIRITSWAP_UNISWAP_V2_ROUTER, $.WFTM);
    }

    modifier onlyEOA()
    {
        require(msg.sender == tx.origin, "access denied");
        _;
    }

    function tokensCount() external view returns (uint256 _tokensCount)
    {
        return tokens.length;
    }

    function setRecipient(address _newRecipient) external onlyOwner
    {
        require(_newRecipient != address(0), "invalid address");
        address _oldRecipient = recipient;
        recipient = _newRecipient;
        emit UpdateRecipient(_oldRecipient, _newRecipient);
    }

    function setFee(uint _fee) external onlyOwner {
        require(_fee != fee, "already exists");
        require(_fee <= 70, "fee cannot be more than 7.0%"); 
        fee = _fee;
    }

    function setTreasury(address _newTreasury) external onlyOwner //delayed
    {
        require(_newTreasury != address(0), "invalid address");
        address _oldTreasury = treasury;
        treasury = _newTreasury;
        emit UpdateTreasury(_oldTreasury, _newTreasury);
    }

    function setOracle(address _newOracle) external onlyOwner delayed
    {
        require(_newOracle != address(0), "invalid address");
        address _oldOracle = oracle;
        oracle = _newOracle;
        emit UpdateOracle(_oldOracle, _newOracle);
    }

    function setMinimalGulpFactor(uint256 _newMinimalGulpFactor) external onlyOwner delayed
    {
        require(_newMinimalGulpFactor <= 1e18, "invalid factor");
        uint256 _oldMinimalGulpFactor = minimalGulpFactor;
        minimalGulpFactor = _newMinimalGulpFactor;
        emit UpdateMinimalGulpFactor(_oldMinimalGulpFactor, _newMinimalGulpFactor);
    }

    function setBurningRate(uint256 _newBurningRate) external onlyOwner delayed
    {
        require(_newBurningRate <= 1e18, "invalid rate");
        uint256 _oldBurningRate = burningRate;
        burningRate = _newBurningRate;
        emit UpdateBurningRate(_oldBurningRate, _newBurningRate);
    }

    function addUniswapV2Token(address _token, uint256 _minAmount, address _router, address _target) external onlyOwner delayed
    {
        _addUniswapV2Token(_token, _minAmount, _router, _target);
    }

    function addBalancerV2Token(address _token, uint256 _minAmount, address _vault, bytes32 _poolId, address _target) external onlyOwner delayed
    {
        _addBalancerV2Token(_token, _minAmount, _vault, _poolId, _target);
    }

    function removeToken(address _token) external onlyOwner delayed
    {
        _removeToken(_token);
    }

    function updateTokenParameters(address _token, uint256 _minAmount, address _routerOrVault, bytes32 _ignoredOrPoolId) external onlyOwner delayed
    {
        _updateTokenParameters(_token, _minAmount, _routerOrVault, _ignoredOrPoolId);
    }

    function _addUniswapV2Token(address _token, uint256 _minAmount, address _router, address _target) internal
    {
        SwapInfo storage _swapInfo = swapInfo[_token];
        require(_swapInfo.swapType == SwapType.NONE, "duplicate token");
        uint256 _index = tokens.length;
        tokens.push(_token);
        _swapInfo.index = _index;
        _swapInfo.minAmount = _minAmount;
        _swapInfo.swapType = SwapType.UNISWAP_V2;
        _swapInfo.router = _router;
        _swapInfo.path = new address[](2);
        _swapInfo.path[0] = _token;
        _swapInfo.path[1] = _target;
    }

    function _addBalancerV2Token(address _token, uint256 _minAmount, address _vault, bytes32 _poolId, address _target) internal
    {
        SwapInfo storage _swapInfo = swapInfo[_token];
        require(_swapInfo.swapType == SwapType.NONE, "duplicate token");
        uint256 _index = tokens.length;
        tokens.push(_token);
        _swapInfo.index = _index;
        _swapInfo.minAmount = _minAmount;
        _swapInfo.swapType = SwapType.BALANCER_V2;
        _swapInfo.vault = _vault;
        _swapInfo.swap.poolId = _poolId;
        _swapInfo.swap.kind = IVault.SwapKind.GIVEN_IN;
        _swapInfo.swap.assetIn = _token;
        _swapInfo.swap.assetOut = _target;
        _swapInfo.swap.amount = 0;
        _swapInfo.swap.userData = new bytes(0);
        _swapInfo.funds.sender = address(this);
        _swapInfo.funds.fromInternalBalance = false;
        _swapInfo.funds.recipient = payable(address(this));
        _swapInfo.funds.toInternalBalance = false;
    }

    function _removeToken(address _token) internal
    {
        SwapInfo storage _swapInfo = swapInfo[_token];
        require(_swapInfo.swapType != SwapType.NONE, "unknown token");
        uint256 _index = _swapInfo.index;
        _swapInfo.index = 0;
        _swapInfo.minAmount = 0;
        _swapInfo.swapType = SwapType.NONE;
        _swapInfo.router = address(0);
        _swapInfo.path = new address[](0);
        _swapInfo.vault = address(0);
        _swapInfo.swap.poolId = bytes32(0);
        _swapInfo.swap.kind = IVault.SwapKind.GIVEN_IN;
        _swapInfo.swap.assetIn = address(0);
        _swapInfo.swap.assetOut = address(0);
        _swapInfo.swap.amount = 0;
        _swapInfo.swap.userData = new bytes(0);
        _swapInfo.funds.sender = address(0);
        _swapInfo.funds.fromInternalBalance = false;
        _swapInfo.funds.recipient = payable(0);
        _swapInfo.funds.toInternalBalance = false;
        uint256 _lastIndex = tokens.length - 1;
        if (_index < _lastIndex) {
            address _lastToken = tokens[_lastIndex];
            tokens[_index] = _lastToken;
            swapInfo[_lastToken].index = _index;
        }
        tokens.pop();
    }

    function _updateTokenParameters(address _token, uint256 _minAmount, address _routerOrVault, bytes32 _ignoredOrPoolId) internal
    {
        SwapInfo storage _swapInfo = swapInfo[_token];
        require(_swapInfo.swapType != SwapType.NONE, "unknown token");
        _swapInfo.minAmount = _minAmount;
        if (_swapInfo.swapType == SwapType.UNISWAP_V2) {
            _swapInfo.router = _routerOrVault;
        }
        else
        if (_swapInfo.swapType == SwapType.BALANCER_V2) {
            _swapInfo.vault = _routerOrVault;
            _swapInfo.swap.poolId  = _ignoredOrPoolId;
        }
    }

    function recoverLostFunds(address _token) external onlyOwner nonReentrant //delayed
    {
        // require(_token != escrowToken, "invalid token");
        SwapInfo storage _swapInfo = swapInfo[_token];
        require(_swapInfo.swapType == SwapType.NONE, "invalid token");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(treasury, _balance);
    }

    function gulp() external onlyEOA nonReentrant
    {
        // swap all the tokens to WFTM
        
        for (uint256 _i = 0; _i < tokens.length; _i++) {
            address _token = tokens[_i];
            SwapInfo storage _swapInfo = swapInfo[_token];
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            if (_balance < _swapInfo.minAmount) continue;
            uint256 _estimate = 1;

            if (_swapInfo.swapType == SwapType.UNISWAP_V2) {
                address _router = _swapInfo.router;
                uint256 _factor = _oracleAveragePriceFactorFromInput(_router, _swapInfo.path, _balance);
                if (_factor < minimalGulpFactor) continue;
                IERC20(_token).safeApprove(_router, _balance);

                // NOT SURE WHAT THIS ERROR IS ALL ABOUT
                try Router02(_router).swapExactTokensForTokens(_balance, _estimate, _swapInfo.path, address(this), block.timestamp) {
                    continue;
                } catch (bytes memory _error) {
                    require(_token == $.LQDR, string(_error));
                    IERC20(_token).safeApprove(_router, 0);
                }
            }
            else if (_swapInfo.swapType == SwapType.BALANCER_V2) {
                address _vault = _swapInfo.vault;
                IERC20(_token).safeApprove(_vault, _balance);
                _swapInfo.swap.amount = _balance;
                try IVault(_vault).swap(_swapInfo.swap, _swapInfo.funds, _estimate, block.timestamp) {
                    continue;
                } catch (bytes memory _error) {
                    require(_token == $.LQDR, string(_error));
                    IERC20(_token).safeApprove(_vault, 0);
                }
            }
        }
        {
            // uint256 _balance = IERC20(escrowToken).balanceOf(address(this));
            uint256 _balance = IERC20($.WFTM).balanceOf(address(this));
            if (_balance > 0) {
                // sudo code
                
                // take out fee
                uint _fee = (_balance * fee) / 1000;
                IERC20($.WFTM).safeTransfer(treasury, _fee);
                IERC20($.WFTM).safeTransfer(recipient, _balance - _fee);
                ConstantNeo(recipient).updateRewardPerSec(_balance);
            }
        }
    }

    function _oracleAveragePriceFactorFromInput(address _router, address[] memory _path, uint256 _inputAmount) internal returns (uint256 _factor)
    {
        require(_inputAmount > 0, "invalid amount");
        address _factory = Router02(_router).factory();
        _factor = 1e18;
        uint256 _amount = _inputAmount;
        for (uint256 _i = 1; _i < _path.length; _i++) {
            address _tokenA = _path[_i - 1];
            address _tokenB = _path[_i];
            address _pool = Factory(_factory).getPair(_tokenA, _tokenB);
            IOracle(oracle).updateAveragePrice(_pool);
            uint256 _averageOutputAmount = IOracle(oracle).consultAveragePrice(_pool, _tokenA, _amount);
            uint256 _currentOutputAmount = IOracle(oracle).consultCurrentPrice(_pool, _tokenA, _amount);
            _factor = _currentOutputAmount * _factor / _averageOutputAmount;
            _amount = _currentOutputAmount;
        }
        return _factor;
    }

    event UpdateTreasury(address _oldTreasury, address _newTreasury);
    event UpdateRecipient(address _oldRecipient, address _newRecipient);
    event UpdateOracle(address _oldOracle, address _newOracle);
    event UpdateMinimalGulpFactor(uint256 _oldMinimalGulpFactor, uint256 _newMinimalGulpFactor);
    event UpdateBurningRate(uint256 _oldBurningRate, uint256 _newBurningRate);
}