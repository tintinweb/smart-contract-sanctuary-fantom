/**
 *Submitted for verification at FtmScan.com on 2023-03-26
*/

// File: interfaces/IUniswapV2Pair.sol



pragma solidity 0.8.15;


interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}
// File: libraries/Sqrt.sol



pragma solidity 0.8.15;


library Sqrt {
    function sqrt(uint y) internal pure returns (uint z) {
        unchecked {
            if (y > 3) {
                z = y;
                uint x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
        }
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: interfaces/IOracle.sol



pragma solidity 0.8.15;



interface IOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 rate, uint256 weight);
}
// File: oracles/OracleBase.sol



pragma solidity 0.8.15;





abstract contract OracleBase is IOracle {
    using Sqrt for uint256;

    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view override returns (uint256 rate, uint256 weight) {
        uint256 balance0;
        uint256 balance1;
        if (connector == _NONE) {
            (balance0, balance1) = _getBalances(srcToken, dstToken);
        } else {
            uint256 balanceConnector0;
            uint256 balanceConnector1;
            (balance0, balanceConnector0) = _getBalances(srcToken, connector);
            (balanceConnector1, balance1) = _getBalances(connector, dstToken);
            if (balanceConnector0 > balanceConnector1) {
                balance0 = balance0 * balanceConnector1 / balanceConnector0;
            } else {
                balance1 = balance1 * balanceConnector0 / balanceConnector1;
            }
        }

        rate = balance1 * 1e18 / balance0;
        weight = (balance0 * balance1).sqrt();
    }

    function _getBalances(IERC20 srcToken, IERC20 dstToken) internal view virtual returns (uint256 srcBalance, uint256 dstBalance);
}
// File: oracles/UniswapV2LikeOracle.sol



pragma solidity 0.8.15;




contract UniswapV2LikeOracle is OracleBase {
    address public immutable factory;
    bytes32 public immutable initcodeHash;

    event InitcodeHashCalculated(bytes32 indexed initcodeHash, bytes byteCode);

    constructor(address _factory) {
        factory = _factory;
        initcodeHash = getInitCodeHash(_factory);

        emit InitcodeHashCalculated(initcodeHash, getCode(_factory));
    }

    function getInitCodeHash(address _factory) internal view returns (bytes32) {
        bytes memory bytecode = getCode(_factory);
        bytes32 hash = keccak256(bytecode);
        return bytes32(uint256(hash) - uint256(2));
    }

    function getCode(address _address) internal view returns (bytes memory) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }
        if (codeSize > 0) {
            bytes memory code = new bytes(codeSize);
            assembly {
                // Retrieve the code of the contract at the address _address and store it in the memory array "code"
                extcodecopy(_address, add(code, 32), 0, codeSize)
            }
            return code;
        } else {
            return new bytes(0);
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(IERC20 tokenA, IERC20 tokenB) private view returns (address pair) {
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(tokenA, tokenB)),
                initcodeHash
            )))));
    }

    function _getBalances(IERC20 srcToken, IERC20 dstToken) internal view override returns (uint256 srcBalance, uint256 dstBalance) {
        (IERC20 token0, IERC20 token1) = srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairFor(token0, token1)).getReserves();
        (srcBalance, dstBalance) = srcToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}