/**
 *Submitted for verification at FtmScan.com on 2022-03-15
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;



// Part: IChainlinkOracle

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: HedgilOracle.sol

contract HedgilOracle is Ownable {
    IChainlinkOracle public constant chainlinkOracle =
        IChainlinkOracle(0x4e2870348d8177b68F717531eC4124aBb3B88fc8);
    uint256 private constant PRICE_DECIMALS = 10**18;

    mapping(address => mapping(address => uint256)) public ivRates;
    mapping(address => address) public oracles;

    function updateIVRate(
        address tokenA,
        address tokenB,
        uint256 _ivRate
    ) external onlyOwner {
        require(_ivRate >= 1500);
        ivRates[tokenB][tokenA] = _ivRate;
    }

    function setOracle(address tokenA, address _oracle) external onlyOwner {
        oracles[tokenA] = _oracle;
    }

    function getIVRate(address tokenA, address tokenB)
        external
        view
        returns (uint256)
    {
        return ivRates[tokenB][tokenA];
    }

    // Retrieve price of each token in USD and get price of tokenA in tokenB
    // e.g. tokenA = DAI, tokenB = WFTM
    // WFTM @ 2 and DAI @ 0.99
    // priceAInB = 0.99/2 = 0.495
    function getCurrentPrice(address tokenA, address tokenB)
        external
        view
        returns (uint256 priceAInB)
    {
        uint256 priceA = IChainlinkOracle(oracles[tokenA]).latestAnswer();
        uint256 priceB = IChainlinkOracle(oracles[tokenB]).latestAnswer();
        priceAInB = (priceA * PRICE_DECIMALS) / priceB;
    }
}