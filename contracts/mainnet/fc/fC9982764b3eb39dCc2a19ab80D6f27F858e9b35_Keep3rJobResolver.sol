/**
 *Submitted for verification at FtmScan.com on 2022-05-24
*/

pragma solidity ^0.8.0;
pragma abicoder v2;


// 
/*
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

// 
interface IResolver {
    function checker()
    external
    view
    returns (bool canExec, bytes memory execPayload);
}

interface CTokenInterface {
    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function exchangeRateCurrent() external returns (uint);

    function exchangeRateStored() external view returns (uint);

    function getCash() external view returns (uint);

    function accrueInterest() external returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}

interface CErc20Interface {
    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
}

interface ScToken is CTokenInterface, CErc20Interface {}

contract Keep3rJob is Ownable {

    event BorrowReduced(IERC20 token, uint256 amount);
    event CollateralRemoved(IERC20 token, uint256 amount);

    address constant addr = address(0xd1BbcA0dfDe1F51CCd17E33DE1A7EAD48fAa1D68);
    IERC20 constant usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 constant dai = IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
    ScToken constant scDai = ScToken(0x8D9AED9882b4953a0c9fa920168fa1FDfA0eBE75);
    ScToken constant scUsdc = ScToken(0xE45Ac34E528907d0A0239ab5Db507688070B20bf);
    address constant ops = address(0x6EDe1597c05A0ca77031cBA43Ab887ccf24cd7e8);
    uint256 constant amount = 500;
    uint256 constant usdcAmount = 500000000;
    uint256 constant daiAmount = 500000000000000000000;
    bool private _enabled = true;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyEnabled() {
        require(_enabled == true, "Currently disabled");
        _;
    }

    modifier onlyOps() {
        require(msg.sender == ops || msg.sender == this.owner(), "OpsReady: onlyOps or owner");
        _;
    }

    constructor() Ownable() {

    }

    function enabled() external view returns (bool) {
        return _enabled;
    }

    function enable() onlyOwner() external {
        _enabled = true;
    }

    function disable() onlyOwner() external {
        _enabled = false;
    }

    /**
     * Escape with liquidity from Scream.sh
     * Attempt to find the current DAI cash amount,
     * if there is cash available to withdraw we attempt
     * to withdraw it and repay part of the USDC hedge
     */
    function escape() onlyEnabled onlyOps external {

        uint256 cash = scDai.getCash();
        require(cash >= daiAmount, "Insufficient cash available for withdraw");
        uint256 redeemableAmount = daiAmount;

        // Transfer a chunk of 500 USDC to this contract from owner address
        require(usdc.transferFrom(addr, address(this), usdcAmount), "Could not take $500 USDC");

        // Approve scUSDC to spend usdc from this contract
        usdc.approve(address(scUsdc), usdcAmount);
        // Repay $500 on behalf of owner address BEFORE we transfer scDai out
        scUsdc.repayBorrowBehalf(addr, usdcAmount);

        // Transfer a chunk of scDAI (not DAI) to this contract from owner address
        require(scDai.transferFrom(addr, address(this), 5000000000000), "Could not take scDAI");
        // redeem $500 of DAI from the scDAI contract
        // uint 0=success, otherwise a failure.
        require(scDai.redeemUnderlying(redeemableAmount)==0, "Unable to redeem underlying amount");

        // send back remaining scDAI to the user
        scDai.transfer(addr, scDai.balanceOf(address(this)));
        // send $500 DAI back to the user
        dai.transfer(addr, redeemableAmount);

        // emit the appropriate messages
        emit BorrowReduced(usdc, usdcAmount);
        emit CollateralRemoved(dai, redeemableAmount);

        // disable this process as we want to ensure we don't exec this more than once.
        _enabled = false;
    }

    function reclaim(IERC20 token, uint256 _amount) public onlyOwner() {
        token.transfer(addr, _amount);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }
}

contract Keep3rJobResolver is IResolver, Ownable {

    address constant addr = address(0xd1BbcA0dfDe1F51CCd17E33DE1A7EAD48fAa1D68);
    ScToken constant scDai = ScToken(0x8D9AED9882b4953a0c9fa920168fa1FDfA0eBE75);
    IERC20 constant usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    uint256 constant daiAmount = 500000000000000000000;
    uint256 constant usdcAmount = 500000000;
    Keep3rJob keep3rJob;

    constructor(Keep3rJob _keep3rJob) Ownable() {
        keep3rJob = _keep3rJob;
    }

    /*
     * Allow gelato to understand whether it should execute the escape function
     */
    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        // cash must be available and greater than $500
        bool hasCash = scDai.getCash() > daiAmount;
        // user balance must be greater than $500 (because we repay this much)
        bool hasBal = usdc.balanceOf(addr) > usdcAmount;
        // must also have job enabled
        canExec = hasCash && hasBal && keep3rJob.enabled();
        execPayload = abi.encodeWithSelector(
            Keep3rJob.escape.selector
        );
    }
}