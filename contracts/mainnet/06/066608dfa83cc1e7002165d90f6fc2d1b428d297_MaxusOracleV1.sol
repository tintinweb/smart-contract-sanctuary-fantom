/**
 *Submitted for verification at FtmScan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
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

// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}
interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

contract MaxusOracleV1 is Ownable, ReentrancyGuard {
    
    address public oraclePair = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
    IUniswapV2Pair opair = IUniswapV2Pair(oraclePair);

    address public native = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    
    function changeOraclePair (address newPair) public onlyOwner {
        oraclePair = newPair;
        opair = IUniswapV2Pair(newPair);
    }
    function getReserves(address pair) public view returns (
        uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        (reserve0, 
         reserve1,
         blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
    }

    
    uint public precision = 10 ** 12;
    function getNativePrice () public view returns (uint256 price) {
        (uint112 r0, 
         uint112 r1, 
         ) = getReserves(oraclePair);
        
        IERC20 token0 = IERC20(opair.token0());
        IERC20 token1 = IERC20(opair.token1());

        uint dec0 = token0.decimals();
        uint dec1 = token1.decimals();

        uint256 res0 = (dec0 >= dec1) ? r0 : r0 * 10**(dec1 - dec0);
        uint256 res1 = (dec1 >= dec0) ? r1 : r1 * 10**(dec0 - dec1);
        if (address(token0) == native) {
            price = (res1 * precision) / res0;
        } else {
            price = (res0 * precision) / res1;
        }
    }
    
    address[] public stables;
    function addStable(address stable) public onlyOwner {
        stables.push(stable);
    }
    function isStable(address token) public view returns (bool is_stable) {
        is_stable = false;
        for (uint256 i = 0; i < stables.length;) {
            is_stable = is_stable ? true : (token == stables[i] ? true : false); 
            i += 1;
        }
    }
    mapping (address => address) public primaryPairs;
    
    function getPrimaryPair(address token) public view returns (address) {
        return primaryPairs[token];
    }
    
    function changePrimaryPair(address token, address pair) public onlyOwner {
        primaryPairs[token] = pair;
    }

    constructor () {
        stables.push(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
        stables.push(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
        primaryPairs[0xFF042a6F2D50F00413f9F1eE8f55b2BB7E0cAB2c] = 0x24d24B78dc35452B2Fb6a75F1e885BF741047536;
        primaryPairs[0x19840d508904587E08f262F518dA078bd4c560bf] = 0x8812731320aeeF90ED1Fa2ac0CDF9187711Dae76;
        primaryPairs[0xf5F76a41B4863a5b8d2E9CCDceE38359Ce1ebf21] = 0x8c2A1CEd2aB27ed327cA3c44b233b2AB3317c907;
    }
    function calculatePrice(address token) public view returns (uint256 price) {
        IUniswapV2Pair pair = IUniswapV2Pair(primaryPairs[token]);
        (uint112 r0, 
         uint112 r1, 
         ) = getReserves(address(pair));
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());

        uint dec0 = token0.decimals();
        uint dec1 = token1.decimals();

        uint256 res0 = (dec0 >= dec1) ? r0 : r0 * 10**(dec1 - dec0);
        uint256 res1 = (dec1 >= dec0) ? r1 : r1 * 10**(dec0 - dec1);
        address helper;
        uint256 helperPrice;
        
        if (isStable(address(token0)) || isStable(address(token1))) {
            // only need to do one step
            if (address(token0) == token) {
                price = (res1 * precision) / res0;
            } else {
                price = (res0 * precision) / res1;
            }
        } else if (address(token0) == native || address(token1) == native) {
            if (address(token0) == token) {
                price = (getNativePrice() * res1) / res0;
            } else {
                price = (getNativePrice() * res0 ) / res1;
            }
        } else {
            if(pair.token0() == token) {
                helper = pair.token1();
            } else {
                helper = pair.token0();    
            }
            helperPrice = calculatePrice(helper);
            if (address(token0) == token) {
                price = (res1 * helperPrice) / res0;
            } else {
                price = (res0 * helperPrice) / res1;
            }
        }

    }
}