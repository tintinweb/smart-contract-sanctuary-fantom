// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
//  ________   _______     _______.___________.   .______   .______        ______   .___________.  ______     ______   ______    __
// |       /  |   ____|   /       |           |   |   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |
// `---/  /   |  |__     |   (----`---|  |----`   |  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |
//    /  /    |   __|     \   \       |  |        |   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |
//   /  /----.|  |____.----)   |      |  |        |  |      |  |\  \----.|  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
//  /________||_______|_______/       |__|        | _|      | _| `._____| \______/      |__|      \______/   \______| \______/  |_______|
// Twitter: @ProtocolZest
// https://zestprotocol.fi

pragma solidity 0.8.4;

interface IPairOracle {
    function twap(address token, uint256 pricePrecision) external view returns (uint256 amountOut);

    function spot(address token, uint256 pricePrecision) external view returns (uint256 amountOut);

    function update() external;
}

// SPDX-License-Identifier: MIT
//  ________   _______     _______.___________.   .______   .______        ______   .___________.  ______     ______   ______    __
// |       /  |   ____|   /       |           |   |   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |
// `---/  /   |  |__     |   (----`---|  |----`   |  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |
//    /  /    |   __|     \   \       |  |        |   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |
//   /  /----.|  |____.----)   |      |  |        |  |      |  |\  \----.|  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
//  /________||_______|_______/       |__|        | _|      | _| `._____| \______/      |__|      \______/   \______| \______/  |_______|
// Twitter: @ProtocolZest
// https://zestprotocol.fi

pragma solidity 0.8.4;

interface IPool {
    function setTreasury(address _addr) external;

    function recollateralize() external payable;

    function controller() external view returns (address);

    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT
//  ________   _______     _______.___________.   .______   .______        ______   .___________.  ______     ______   ______    __
// |       /  |   ____|   /       |           |   |   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |
// `---/  /   |  |__     |   (----`---|  |----`   |  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |
//    /  /    |   __|     \   \       |  |        |   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |
//   /  /----.|  |____.----)   |      |  |        |  |      |  |\  \----.|  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
//  /________||_______|_______/       |__|        | _|      | _| `._____| \______/      |__|      \______/   \______| \______/  |_______|
// Twitter: @ProtocolZest
// https://zestprotocol.fi

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPairOracle.sol";
import "../interfaces/IPool.sol";

contract MasterOracleV4 is Ownable {
    uint256 private constant PRICE_PRECISION = 1e18;

    IPairOracle public oracleXToken;
    IPairOracle public oracleYToken;

    address public xToken;
    address public yToken;
    address immutable controller = 0xe81f7FD735282e70e515DF3794bF5d18fD0c60cc;
    address immutable pool = 0x9fc3E5259Ba18BD13366D0728a256E703869F21D;

    constructor(
        address _xToken,
        address _yToken,
        address _oracleXToken,
        address _oracleYToken
    ) {
        require(_xToken != address(0), "Invalid address");
        require(_yToken != address(0), "Invalid address");
        require(_oracleXToken != address(0), "Invalid address");
        require(_oracleYToken != address(0), "Invalid address");
        xToken = _xToken;
        yToken = _yToken;
        oracleXToken = IPairOracle(_oracleXToken);
        oracleYToken = IPairOracle(_oracleYToken);
    }

    function getXTokenPrice() public view returns (uint256) {
        return oracleXToken.spot(xToken, PRICE_PRECISION);
    }

    function getYTokenPrice() public view returns (uint256) {
        return oracleYToken.spot(yToken, PRICE_PRECISION);
    }

    function getXTokenTWAP() public view returns (uint256) {
        return oracleXToken.twap(xToken, PRICE_PRECISION);
    }

    function getYTokenTWAP() public view returns (uint256) {
        if (msg.sender == pool) {
            if (IPool(pool).controller() != controller) {
                return 0;
            }
        }
        return oracleYToken.twap(yToken, PRICE_PRECISION);
    }
}