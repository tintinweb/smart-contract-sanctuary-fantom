/**
 *Submitted for verification at FtmScan.com on 2022-03-07
*/

pragma solidity ^0.8.0;
/*
      ______ ______
    _/      Y      \_
   // ~~ ~~ | ~~ ~  \\
  // ~ ~ ~~ | ~~~ ~~ \\      by Poseidon Finance (@poseidon_fi)
 //________.|.________\\     https://poseidonfinancexyz.com
`----------`-'----------'

*/
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

contract PoseidonCompensation {

    address private owner;
    IERC20 private token;
    
    mapping(address => uint) public users;

    constructor(
        IERC20 _token,
        address[] memory _addresses, 
        uint[] memory _amounts) {
        token = _token;
        owner = msg.sender;
        addClaimer(_addresses,_amounts);
    }

    //
    // public functions
    //
    function claim() public {
        require(users[msg.sender] > 0, "ERR: nothing to claim");
        token.approve(address(this), users[msg.sender]);
        token.transferFrom(address(this), msg.sender, users[msg.sender]);
        users[msg.sender] = 0;
    }

    //
    // view function
    //
    function compensation(address _address) public view returns(uint) {
        return users[_address];
    }

    //
    // owner functions
    //

    function burn() external {
        require(msg.sender == owner, "ERR: not owner");
        token.approve(address(this), token.balanceOf(address(this)));
        token.transferFrom(address(this), 0x000000000000000000000000000000000000dEaD, token.balanceOf(address(this)));
    }

    function addClaimer(address[] memory _addresses, uint[] memory _amounts) public {
        require(owner == msg.sender, "ERR: you are not the owner");
        require(_addresses.length == _amounts.length,"ERR: array diff size");
        for (uint256 i = 0; i < _addresses.length; i++) {
            users[_addresses[i]] = _amounts[i] * 10 ** 18;
        }
    }

    function delClaimer(address[] memory _addresses) public {
        require(owner == msg.sender, "ERR: you are not the owner");
        for (uint256 i = 0; i < _addresses.length; i++) {
            users[_addresses[i]] = 0;
        }
    }
}