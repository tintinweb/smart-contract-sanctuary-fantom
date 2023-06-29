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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
pragma solidity 0.8.10;

/// @dev Importing openzeppelin stuffs.
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Importing the custom stuffs.
import "./interfaces/IWFTM.sol";
import "./interfaces/ICoinMingleLP.sol";

/// @dev Custom errors.
error PairExists();
error InvalidPath();
error HighSlippage();
error InvalidWFTMPath();
error DeadlinePassed();
error InvalidAddress();
error TokenZeroAmount();
error PairDoesNotExist();
error IdenticalAddress();
error InsufficientAmount();
error ExcessiveLiquidity();
error InsufficientLiquidity();
error InvalidLiquidity();
error InvalidAmount();

contract CoinMingleRouter is Ownable, ReentrancyGuard {
    /// @dev Tracking the Wrapped FTM contract address.
    IWFTM public immutable WrappedFTM;
    /// @dev Tracking the cloneable CoinMingle ERC20.
    address public immutable CoinMingleImplementation;
    /// @dev Tracking the pair address mapping
    mapping(address => mapping(address => address)) public getPair;
    /// @dev Tracking all the pair addresses into list.
    address[] public allPairs;

    /// @dev Modifier to check deadline.
    modifier ensure(uint256 _deadline) {
        /// @dev Revert if caller is not the CoinMingleRouter
        if (_deadline < block.timestamp) revert DeadlinePassed();
        _;
    }

    /**
     * `PairCreated` will be fired when a new pair is created.
     * @param tokenA: The address of the tokenA.
     * @param tokenB: The address of the tokenB.
     * @param pair: The pair address created from tokenA & tokenB.
     */
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address indexed pair
    );

    /**
     * `LiquidityAdded` will be fired when liquidity added into a pool.
     * @param amountA: The amount of the tokenA.
     * @param amountB: The amount of the tokenB.
     * @param pair: The pair address created from tokenA & tokenB.
     */
    event LiquidityAdded(
        uint256 indexed amountA,
        uint256 indexed amountB,
        address indexed pair
    );

    /**
     * `LiquidityRemoved` will be fired when liquidity removed from a pool.
     * @param amountA: The amount of the tokenA.
     * @param amountB: The amount of the tokenB.
     * @param pair: The pair address created from tokenA & tokenB.
     */
    event LiquidityRemoved(
        uint256 indexed amountA,
        uint256 indexed amountB,
        address indexed pair
    );

    /// @dev Events
    /**
     * @dev event TokensSwapped: will be emitted when tokens swapped
     * @param _to: The person to whom swapped tokens are minted
     * @param tokenIN : Address of the token being swapped
     * @param tokenInAmount : The amount of input token given
     * @param tokenOut : Address of the token user will get after swapped
     * @param tokenOutAmount : The amount of output token received
     */

    event TokensSwapped(
        address indexed _to,
        address indexed tokenIN,
        uint256 tokenInAmount,
        address indexed tokenOut,
        uint256 tokenOutAmount
    );

    /**
     * @dev Fallback function to receive FTM from WrappedFTM contract.
     * Only Receive FTM from Wrapped FTM contract.
     */
    receive() external payable {
        /// @dev Revert if other than WFTM contract sending FTM to this contract.
        if (msg.sender != address(WrappedFTM)) revert InvalidAddress();
    }

    /**
     * @dev Initializing the CoinMingleLP implementation.
     * @param _coinMingleLPImplementation: The deployed CoinMingleLP implementation contract address.
     * @param _wrappedFTM: The deployed wrapped FTM contract address.
     */
    constructor(address _coinMingleLPImplementation, address _wrappedFTM) {
        /// @dev Validations.
        if (
            _coinMingleLPImplementation == address(0) ||
            _wrappedFTM == address(0)
        ) revert InvalidAddress();
        /// @dev Initializing the implementation & WrappedFTM.
        CoinMingleImplementation = _coinMingleLPImplementation;
        WrappedFTM = IWFTM(_wrappedFTM);
    }

    /// @dev Returns the length of the allPairs array length.
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /**
     * @dev Creating a new pair of tokens (tokenA & tokenB).
     * @param tokenA: The address of tokenA.
     * @param tokenB: The address of tokenB.
     * @return pair The created pair address.
     */
    function createPair(
        address tokenA,
        address tokenB
    ) public nonReentrant returns (address pair) {
        pair = _createPair(tokenA, tokenB);
    }

    /**
     * @dev Adding Liquidity into pool contact.
     * @param _tokenA: The first token address.
     * @param _tokenB: The second token address.
     * @param _amountADesired: The amount of first token should add into liquidity.
     * @param _amountBDesired: The amount of second token should add into liquidity.
     * @param _to: The address to whom CoinMingleLP tokens will mint.
     * @param _deadline: The unix last timestamp to execute the transaction.
     * @return amountA The amount of tokenA added into liquidity.
     * @return amountB The amount of tokenB added into liquidity.
     * @return liquidity The amount of CoinMingleLP token minted.
     */
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        address _to,
        uint256 _deadline
    )
        external
        nonReentrant
        ensure(_deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        /// @dev Validations.
        if (_tokenA == address(0) || _tokenB == address(0))
            revert InvalidAddress();
        if (_amountADesired == 0 || _amountBDesired == 0)
            revert InsufficientAmount();
        (
            /// @dev Adding liquidity.
            amountA,
            amountB
        ) = _addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired);

        /// @dev Getting the pair address for tokenA & tokenB.
        address pair = getPair[_tokenA][_tokenB];
        /// @dev Transferring both tokens to pair contract.
        IERC20(_tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(_tokenB).transferFrom(msg.sender, pair, amountB);

        /// @dev Minting the CoinMingleLP tokens.
        liquidity = ICoinMingle(pair).mint(_to);

        /// @dev Emitting event.
        emit LiquidityAdded(amountA, amountB, pair);
    }

    /**
     * @dev Adding Liquidity into pool contact with FTM as pair with address.
     * @param _token: The pair token contract address.
     * @param _amountDesired: The amount of pair token should add into liquidity.
     * @param _to: The address to whom CoinMingleLP tokens will mint.
     * @param _deadline: The unix last timestamp to execute the transaction.
     * @return amountToken The amount of token added into liquidity.
     * @return amountFTM The amount of FTM added into liquidity.
     * @return liquidity The amount of CoinMingleLP token minted.
     */
    function addLiquidityFTM(
        address _token,
        uint256 _amountDesired,
        address _to,
        uint256 _deadline
    )
        external
        payable
        nonReentrant
        ensure(_deadline)
        returns (uint256 amountToken, uint256 amountFTM, uint256 liquidity)
    {
        /// @dev Validations.
        if (_token == address(0)) revert InvalidAddress();
        uint256 _ftmAmountSentByUser = msg.value;
        if (_amountDesired == 0 || _ftmAmountSentByUser == 0)
            revert InsufficientAmount();

        /// @dev Adding liquidity.
        (amountToken, amountFTM) = _addLiquidity(
            _token,
            address(WrappedFTM),
            _amountDesired,
            _ftmAmountSentByUser
        );
        /// @dev Getting the pair address for tokenA & tokenB.
        address pair = getPair[_token][address(WrappedFTM)];
        /// @dev Converting FTM to WrappedFTM.
        WrappedFTM.deposit{value: amountFTM}();
        /// @dev Transferring both tokens to pair contract.
        IERC20(_token).transferFrom(msg.sender, pair, amountToken);
        WrappedFTM.transfer(pair, amountFTM);

        /// @dev Minting the CoinMingleLP tokens.
        liquidity = ICoinMingle(pair).mint(_to);

        /// @dev Refund dust ftm, if any
        if (_ftmAmountSentByUser > amountFTM) {
            (bool success, ) = msg.sender.call{
                value: _ftmAmountSentByUser - amountFTM
            }("");
            require(success);
        }

        /// @dev Emitting event.
        emit LiquidityAdded(amountToken, amountFTM, pair);
    }

    /**
     * @dev Removing Liquidity from the pool contact with FTM as pair with address.
     * @param _tokenA: The first token address.
     * @param _tokenB: The second token address.
     * @param _liquidity: The amount of CoinMingleLP tokens.
     * @param _to: The address to whom CoinMingleLP tokens will mint.
     * @param _deadline: The unix last timestamp to execute the transaction.
     */
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        address _to,
        uint256 _deadline
    )
        external
        nonReentrant
        ensure(_deadline)
        returns (uint amountA, uint amountB)
    {
        (amountA, amountB) = _removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _to
        );
    }

    /**
     * @dev Removing Liquidity from the pool contact with FTM as pair with address.
     * @param _token: The pair token contract address.
     * @param _liquidity: The amount of CoinMingleLP tokens.
     * @param _to: The address to whom CoinMingleLP tokens will mint.
     * @param _deadline: The unix last timestamp to execute the transaction.
     */
    function removeLiquidityFTM(
        address _token,
        uint256 _liquidity,
        address _to,
        uint256 _deadline
    )
        external
        nonReentrant
        ensure(_deadline)
        returns (uint amountToken, uint amountFTM)
    {
        /// @dev First removing liquidity.
        (amountToken, amountFTM) = _removeLiquidity(
            _token,
            address(WrappedFTM),
            _liquidity,
            address(this)
        );

        /// @dev Converting WFTM to FTM.
        WrappedFTM.withdraw(amountFTM);
        /// @dev Sending the amounts to `_to`.
        IERC20(_token).transfer(_to, amountToken);
        (bool success, ) = _to.call{value: amountFTM}("");
        require(success);
    }

    /**
     * @dev Calculate the amount of tokenB required when tokenA is given for swap with tokenB
     * @param _amountIn : The amount of tokenA in at path[0] that a person is swapping for tokenB
     * @param _path: Address array of the two tokens.
     * path[0]= The address of token that will be swapped (input)
     * path[length - 1] = The address of token that will be returned after  swap (output)
     * @return _amountOut : The amount of tokenB received after swapping tokenA
     */

    function getAmountOut(
        uint256 _amountIn,
        address[] calldata _path
    ) public view returns (uint256 _amountOut) {
        /// @dev validating input fields
        if (_amountIn == 0) revert TokenZeroAmount();
        if (_path.length < 2) revert InvalidPath();

        /// @dev Loop though all the paths.
        for (uint256 i; i < (_path.length - 1); i++) {
            /// @dev Getting the pair address based on address of two tokens
            address pair = getPair[_path[i]][_path[i + 1]];
            if (pair == address(0)) revert PairDoesNotExist();

            /// @dev If iterator on first index
            if (i == 0) {
                /// @dev Getting the amountOut from pair based on `_amountIn`.
                _amountOut = ICoinMingle(pair).getAmountOut(
                    _path[i],
                    _amountIn
                );
            } else {
                /// @dev Getting the amountOut from pair based on previous pair `_amountOut`.
                _amountOut = ICoinMingle(pair).getAmountOut(
                    _path[i],
                    _amountOut
                );
            }
        }
    }

    /**
     * @dev Swapping one token for another token.
     * @param _amountIn: The amount of _path[0] token trader wants to swap.
     * @param _amountOutMin: The Minimum amount of token trader expected to get.
     * @param _path: The pair address path. path[0] will be main tokenIn and path[length - 1] will be main output token.
     * @param _to: The address to whom output token will send.
     * @param _deadline: The timestamp till user wait for execution to success.
     */
    function swapTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external nonReentrant ensure(_deadline) returns (uint256 _amountOut) {
        _amountOut = _swapTokensForTokens(_amountIn, _amountOutMin, _path, _to);
    }

    /**
     * @dev Swapping FTM for another token.
     * @param _amountOutMin: The Minimum amount of token trader expected to get.
     * @param _path: The pair address path. Path[0] will be WETH and Path[length - 1] will be main output token.
     * @param _to: The address to whom output token will send.
     * @param _deadline: The timestamp till user wait for execution to success.
     */
    function swapFTMForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        nonReentrant
        ensure(_deadline)
        returns (uint256 _amountOut)
    {
        /// @dev Checking if the first address is WFTM.
        if (_path[0] != address(WrappedFTM)) revert InvalidWFTMPath();

        /// @dev Converting FTM to WrappedFTM.
        uint256 _amountIn = msg.value;
        WrappedFTM.deposit{value: _amountIn}();

        /// Swapping.
        _amountOut = _swapTokensForTokens(_amountIn, _amountOutMin, _path, _to);
    }

    /**
     * @dev Swapping tokens for FTM.
     * @param _amountIn: The amount of _path[0] token trader wants to swap.
     * @param _amountOutMin: The Minimum amount of token trader expected to get.
     * @param _path: The pair address path. Path[0] will be WETH and Path[length - 1] will be main output token.
     * @param _to: The address to whom output token will send.
     * @param _deadline: The timestamp till user wait for execution.
     */
    function swapTokensForFTM(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external nonReentrant ensure(_deadline) returns (uint256 _amountOut) {
        /// @dev Checking if the last address is WFTM.
        if (_path[_path.length - 1] != address(WrappedFTM))
            revert InvalidWFTMPath();

        /// Swapping.
        _amountOut = _swapTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this)
        );

        /// @dev Converting WrappedFTM to FTM.
        WrappedFTM.withdraw(_amountOut);

        (bool success, ) = _to.call{value: _amountOut}("");
        require(success);
    }

    /**
     * @dev To get an estimate how many tokenA and TokenB will be received when particular amount of liquidity is removed.
     * @param _liquidity: The amount of liquidity being removed.
     * @param _tokenA: The Address of tokenA.
     * @param _tokenB: The Address of tokenB.
     * @return _amountA : The amount of tokenA received after removing _liquidity amount of liquidity
     * @return _amountB : The amount of tokenB received after removing _liquidity amount of liquidity
     */

    function getAmountsOutForLiquidity(
        uint256 _liquidity,
        address _tokenA,
        address _tokenB
    ) external view returns (uint256 _amountA, uint256 _amountB) {
        /// @dev returning if 0 liquidity is passed as input parameter
        if (_liquidity == 0) return (_amountA, _amountB);

        /// @dev getting the pair based on addresses of two tokens
        address pair = getPair[_tokenA][_tokenB];

        /// @dev validating if pair address exist
        if (pair == address(0)) revert PairDoesNotExist();

        /// @dev getting totalSupply ( Save gas)
        uint256 _totalSupply = ICoinMingle(pair).totalSupply();

        /// @dev validation liquidity entered should be less than equal to total Supply
        if (_liquidity > _totalSupply) revert InvalidLiquidity();

        /// @dev getting both tokens reserves
        (uint256 _reserveA, uint256 _reserveB) = ICoinMingle(pair)
            .getReserves();

        /// @dev Calculating both tokens amounts
        _amountA = (_liquidity * _reserveA) / _totalSupply;
        _amountB = (_liquidity * _reserveB) / _totalSupply;
    }

    /**
     * @dev To get an estimate how many tokenOut required to add liquidity when certain amount of tokenIn added.
     * @param _tokenInAddress: The address of tokenIn ( the token whose amount is entered)
     * @param _tokenOutAddress: The Address of tokenOut (the token whose amount is to obtain)
     * @param _tokenInAmount: The amount of tokenIn
     * @return _tokenOutAmount : The amount of tokenOut required based on amount of tokenIn.
     */

    function getTokenInFor(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _tokenInAmount
    ) public view returns (uint256 _tokenOutAmount) {
        /// @dev Validating 0 amount
        if (_tokenInAmount == 0) revert InvalidAmount();

        /// @dev getting and validating pair
        address pair = getPair[_tokenInAddress][_tokenOutAddress];
        if (pair == address(0)) revert PairDoesNotExist();

        /// @dev initializing LP instance
        ICoinMingle _coinMingle = ICoinMingle(pair);

        /// @dev getting reserves
        (uint256 _reserveA, uint256 _reserveB) = _coinMingle.getReserves();

        /// @dev Calculating tokenOut amount
        if (_coinMingle.tokenA() == _tokenInAddress) {
            _tokenOutAmount = (_tokenInAmount * _reserveB) / _reserveA;
        } else {
            _tokenOutAmount = (_tokenInAmount * _reserveA) / _reserveB;
        }
    }

    /**
     * @dev Creating a new pair of tokens (tokenA & tokenB).
     * @param tokenA: The address of tokenA.
     * @param tokenB: The address of tokenB.
     * @return pair The created pair address.
     */
    function _createPair(
        address tokenA,
        address tokenB
    ) private returns (address pair) {
        /// @dev Validations.
        if (tokenA == tokenB) revert IdenticalAddress();
        if (tokenA == address(0) || tokenB == address(0))
            revert InvalidAddress();
        if (getPair[tokenA][tokenB] != address(0)) revert PairExists();

        /// @dev Cloning the CoinMingleLP contract.
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        pair = Clones.cloneDeterministic(CoinMingleImplementation, salt);

        /// @dev Initializing the CoinMingleLP contact.
        ICoinMingle(pair).initialize(tokenA, tokenB);

        /// @dev Updating the mapping.
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        /// @dev Adding the pair into list.
        allPairs.push(pair);
        /// @dev Emitting event.
        emit PairCreated(tokenA, tokenB, pair);
    }

    /**
     * @dev Adding Liquidity into pool contact.
     * @param _tokenA: The first token address.
     * @param _tokenB: The second token address.
     * @param _amountADesired: The amount of first token should add into liquidity.
     * @param _amountBDesired: The amount of second token should add into liquidity.
     * @return amountA The amount of tokenA added into liquidity.
     * @return amountB The amount of tokenB added into Liquidity.
     */
    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) private returns (uint256 amountA, uint256 amountB) {
        /// @dev Getting the pair for this two tokens.
        address pair = getPair[_tokenA][_tokenB];
        /// @dev If no Pair exists for these two tokens then create one.
        if (pair == address(0)) {
            pair = _createPair(_tokenA, _tokenB);
        }
        /// @dev Getting the initial reserves.
        (uint256 reserveA, uint256 reserveB) = ICoinMingle(pair).getReserves();

        /// @dev If both reserves are 0 then total amount will be added.
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        }
        /// @dev Else checking the correct amount given.
        else {
            uint256 amountBOptimal = getTokenInFor(
                _tokenA,
                _tokenB,
                _amountADesired
            );
            // Checking if the desired amount of token B is less than or equal to the optimal amount
            if (amountBOptimal <= _amountBDesired) {
                if (amountBOptimal == 0) revert InsufficientLiquidity();
                /// @dev Returns the actual amount will be added into liquidity.
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = getTokenInFor(
                    _tokenB,
                    _tokenA,
                    _amountBDesired
                );

                if (amountAOptimal == 0) revert InsufficientLiquidity();
                if (amountAOptimal > _amountADesired)
                    revert ExcessiveLiquidity();
                /// @dev Returns the actual amount will be added into liquidity.
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }
    }

    /**
     * @dev Removing Liquidity from the pool contact with FTM as pair with address.
     * @param _tokenA: The first token address.
     * @param _tokenB: The second token address.
     * @param _liquidity: The amount of CoinMingleLP tokens.
     * @param _to: The address to whom CoinMingleLP tokens will mint.
     */
    function _removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        address _to
    ) private returns (uint amountA, uint amountB) {
        /// @dev Validations.
        if (_liquidity == 0) revert InsufficientLiquidity();

        /// @dev Getting the pair address for tokenA & tokenB.
        address pair = getPair[_tokenA][_tokenB];
        if (pair == address(0)) revert PairDoesNotExist();
        /// @dev Sending CoinMingleLP tokens to CoinMingleLP contract.
        ICoinMingle(pair).transferFrom(msg.sender, pair, _liquidity);
        /// @dev Burning tokens and remove liquidity.
        (amountA, amountB) = ICoinMingle(pair).burn(_to);

        /// @dev Emitting event.
        emit LiquidityRemoved(amountA, amountB, pair);
    }

    /**
     * @dev Swapping one token from another token.
     * @param _amountIn: The amount of _path[0] token trader wants to swap.
     * @param _amountOutMin: The Minimum amount of token trader expected to get.
     * @param _path: The pair address path. Path[0] will be main tokenIn and Path[length - 1] will be main output token.
     * @param _to: The address to whom output token will send.
     */
    function _swapTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to
    ) private returns (uint256 _amountOut) {
        /// @dev Token validation
        if (_path.length < 2) revert InvalidPath();
        if (_to == address(0)) revert InvalidAddress();

        /// @dev Loop through all the paths and swapping in each pair
        for (uint256 i; i < (_path.length - 1); i++) {
            /// @dev Getting the pair
            address pair = getPair[_path[i]][_path[i + 1]];
            if (pair == address(0)) revert PairDoesNotExist();

            /// @dev If iterator on first index
            if (i == 0) {
                if (_path[i] == address(WrappedFTM)) {
                    IERC20(_path[i]).transfer(pair, _amountIn);
                    _amountOut = ICoinMingle(pair).swap(address(this));
                } else {
                    /// @dev Then transfer from trader to first pair.
                    IERC20(_path[i]).transferFrom(msg.sender, pair, _amountIn);
                    _amountOut = ICoinMingle(pair).swap(address(this));
                }
            } else {
                /// @dev Then transfer from CoinMingleRouter to next pair.
                IERC20(_path[i]).transfer(pair, _amountOut);
                _amountOut = ICoinMingle(pair).swap(address(this));
            }
        }
        /// @dev Minimum tokenOut validation.
        if (_amountOut < _amountOutMin) revert HighSlippage();

        /// @dev Transferring the amountOut of path[_path.length-1] token.
        if (_to != address(this)) {
            IERC20(_path[_path.length - 1]).transfer(_to, _amountOut);
        }

        emit TokensSwapped(
            _to,
            _path[0],
            _amountIn,
            _path[_path.length - 1],
            _amountOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @dev Importing openzeppelin stuffs.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICoinMingle is IERC20 {
    /**
     * @dev Initializing the CoinMingle, ERC20 token and Pair tokens (tokenA & tokenB).
     * @param _tokenA: The first token for pair.
     * @param _tokenB: The second token for pair
     */
    function initialize(address _tokenA, address _tokenB) external;

    /**
     * @dev Minting liquidity tokens as per share alloted.
     * @param _to: The address to whom the CoinMingleLP share will mint.
     * @return liquidity The amount of CoinMingleLP token minted.
     */
    function mint(address _to) external returns (uint256 liquidity);

    /**
     * @dev Removing liquidity tokens as per share given.
     * @param _to: The address to whom the tokens will transferred.
     * @return amountA The amount of tokenA removed from pool.
     * @return amountB The amount of tokenB removed from pool
     */
    function burn(
        address _to
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @dev Swap tokens for other tokens
     * @param _to: The address to whom the tokens will transferred.
     * @return _amountOut The amount of token user got after swapping.
     */
    function swap(address _to) external returns (uint256 _amountOut);

    /**
     * @dev Getting the actual amount of token you will get on the behalf of amountIn & tokenIn.
     * @param _tokenIn: The token you want to swap.
     * @param _amountIn: The amount of token you want to swap.
     */
    function getAmountOut(
        address _tokenIn,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);

    /**
     * @dev Returns tha actual amount of reserves available for tokenA & tokenB.
     * @return reserveA The tokenA amount.
     * @return reserveB The tokenB amount.
     */
    function getReserves()
        external
        view
        returns (uint256 reserveA, uint256 reserveB);

    /**
     * @dev returns the address of tokenA
     */

    function tokenA() external view returns (address _tokenA);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWFTM {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint256) external;
}