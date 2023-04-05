// SPDX-License-Identifier: MIT

// File: contracts/interfaces/IPair.sol
pragma solidity >=0.8.0;

interface ISoulSwapPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);
    function token1() external view returns (address);
    
    function getReserves() external view returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out, 
        uint256 amount1Out, 
        address to, 
        bytes calldata data
    ) external;

    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interfaces/IManifestation.sol

interface IManifestation {
    function userInfo (address account) external view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays);
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: contracts/governance/Bearing.sol
pragma solidity >=0.8.0;

contract Bearing is Ownable {

    // addresses
    IManifestation manifestation = IManifestation(0x87ED587e2a52bA28c6dA63199E9988067d10Fe34);
    IERC20 surv = IERC20(0x5d9EaFC54567F34164A269Ba6C099068df6ef651);
    ISoulSwapPair survNative = ISoulSwapPair(0xF9062aF9EF6492Cbd68Aed1739769d75E461602D);

    function name() public pure returns (string memory) { return "Bearing"; }
    function symbol() public pure returns (string memory) { return "BRG"; }
    function decimals() public pure returns (uint8) { return 18; }

    // gets: total voting power = the reserves in the LPs
    function totalSupply() public view returns (uint) {
        return surv.totalSupply();
    }

    function balanceOf(address member) public view returns (uint) {
        ( uint memberLiquidity, ) = pooledPower(member);
        ( uint memberSurv, ) = survPower(member);

        return memberLiquidity + memberSurv;
    }

    // gets: member's pooled SURV power
    function pooledPower(address member) public view returns (uint raw, uint formatted) {

        // surv per LP
        (uint _servPerLP, ) = servPerLP();

        // pooled balance (LP)
        (uint _pooledBalance, ) = pooledBalance(member);

        // staked balance (LP)
        (uint _stakedBalance, ) = stakedBalance(member);

        // total LP balance
        uint lp_balance = _pooledBalance + _stakedBalance;

        // LP balance * SURV per each LP
        uint lp_power = lp_balance * _servPerLP;

        return (lp_power, fromWei(lp_power));
    }

    function servPerLP() public view returns (uint raw, uint formatted) {
        // pooled SURV
        uint lp_underlyingSurv = surv.balanceOf(address(survNative));

        // SURV in each LP
        uint _survPerLP = lp_underlyingSurv / survNative.totalSupply();

        return (_survPerLP, fromWei(_survPerLP));
    }

    function pooledBalance(address member) public view returns (uint raw, uint formatted) {
        // wallet balance (LP)
        uint _pooledBalance = survNative.balanceOf(member);
        return (_pooledBalance, fromWei(_pooledBalance));
    }

    function stakedBalance(address member) public view returns (uint raw, uint formatted) {
        // staked balance (LP)
        (uint _stakedBalance,,,,,) = manifestation.userInfo(member);
        return (_stakedBalance, fromWei(_stakedBalance));
    }

    // gets: member's SURV power
    function survPower(address member) public view returns (uint raw, uint formatted) {
        // survPower is the members' SURV balance.
        uint surv_power = surv.balanceOf(member);
        return (surv_power, fromWei(surv_power));
    }

    // blocks ERC20 functionality.
    function allowance(address, address) public pure returns (uint) { return 0; }
    function transfer(address, uint) public pure returns (bool) { return false; }
    function approve(address, uint) public pure returns (bool) { return false; }
    function transferFrom(address, address, uint) public pure returns (bool) { return false; }

    // conversion helper functions
    function toWei(uint intNum) public pure returns (uint bigInt) { return intNum * 10**18; }
    function fromWei(uint bigInt) public pure returns (uint intNum) { return bigInt / 10**18; }
}