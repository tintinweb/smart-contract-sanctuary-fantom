/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// File: contracts/interfaces/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function mint(uint amount) external;
}
// File: contracts/TEST_TOKEN_MINTER.sol


pragma solidity ^0.8.0;



contract NEKO_TEST_TOKEN_MINTER {

    address owner;
    mapping(address => bool) public isStaff;
    address[] public tokenContractsArray;

    constructor(){
        owner = msg.sender;
        isStaff[msg.sender] = true;
    }

    function addTokens(address[] memory _tokenContractsArray) public {
        require(isStaff[msg.sender], "Only staff can add tokens");
        tokenContractsArray = _tokenContractsArray;
    }

    function mintTester() public {
    

    IERC20(tokenContractsArray[0]).mint(10000 ether); // USDC
    IERC20(tokenContractsArray[1]).mint(5 ether); // WETH
    IERC20(tokenContractsArray[2]).mint(0.5 ether); // WBTC
    IERC20(tokenContractsArray[3]).mint(600 ether); // LINK
    IERC20(tokenContractsArray[4]).mint(10000 ether); // DAI

    IERC20(tokenContractsArray[0]).transfer(msg.sender, 10000 ether); // USDC
    IERC20(tokenContractsArray[1]).transfer(msg.sender, 5 ether); // WETH
    IERC20(tokenContractsArray[2]).transfer(msg.sender, 0.5 ether); // WBTC
    IERC20(tokenContractsArray[3]).transfer(msg.sender, 600 ether); // LINK
    IERC20(tokenContractsArray[4]).transfer(msg.sender, 10000 ether); // DAI


    // IERC20(tokenContractsArray[4]).mint(10000 ether); // aMATIC
    // IERC20(tokenContractsArray[5]).mint(5 ether); // aWETH
    // IERC20(tokenContractsArray[6]).mint(10000 ether); // aUSDC
    // IERC20(tokenContractsArray[7]).mint(0.5 ether); // aWBTC

    // IERC20(tokenContractsArray[4]).mint(10000 ether); // MaticX
    // IERC20(tokenContractsArray[5]).mint(10000 ether); // USDT
    // IERC20(tokenContractsArray[6]).mint(10000 ether); // DAI
    // IERC20(tokenContractsArray[7]).mint(5 ether); //wstETH
    // IERC20(tokenContractsArray[8]).mint(10000 ether); // GHST
    // IERC20(tokenContractsArray[9]).mint(1600 ether); // LINK
    // IERC20(tokenContractsArray[10]).mint(2000 ether); // BAL
    // IERC20(tokenContractsArray[11]).mint(10000 ether); // EURS
    // IERC20(tokenContractsArray[12]).mint(10000 ether); // CRV
    // IERC20(tokenContractsArray[13]).mint(10000 ether); // agEUR
    // IERC20(tokenContractsArray[14]).mint(10000 ether); // miMATIc
    // IERC20(tokenContractsArray[15]).mint(10000 ether); // SUSHI
    // IERC20(tokenContractsArray[16]).mint(151 ether); // DPI


    }

}