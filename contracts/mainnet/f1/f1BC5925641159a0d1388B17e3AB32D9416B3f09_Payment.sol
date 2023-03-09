/**
 *Submitted for verification at FtmScan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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



contract Main {

    address public owner;

    uint public cut = 1;

    uint public qrcut = 1;

    mapping(bytes32 => address) public whitelist;

    bytes32[] public whiteSymbol;

    constructor (){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owners allowed");
        _;
    }

    function whiteSymbols() public view returns(bytes32[] memory) {
        return whiteSymbol;
    }

    function updateCut (uint ncut) external onlyOwner {
        require(ncut > 0, "Cut too small");
        cut = ncut;
    }

    function addWhitelist (bytes32 symbol, address _address) external onlyOwner {

        whitelist[symbol] = _address;

        whiteSymbol.push(symbol);

    }

    function removeWhitelist (bytes32 symbol) external onlyOwner {

        delete whitelist[symbol];

    }


    function updateQrCut (uint ncut) external onlyOwner {
        require(ncut > 0, "Cut too small");
        qrcut = ncut;
    }

}

contract Payment {

        event TransferReceived(address indexed _to, address indexed _from, uint indexed _amount);

        event TransferSent(address indexed _from, address indexed _desAddr , uint indexed _amount);

        Main parentContract = Main(0xB5450b0A11F5cb94B4bFc0aed63f8b75AF96891f);

        address public owner = parentContract.owner();
        address public contractAddress = address(this);
        uint256 public contractBalance;
        uint256 public wallet;  
        uint256 public percent = parentContract.cut();

        constructor () {
             
        }


        receive () external payable {

            emit TransferReceived(contractAddress, msg.sender, msg.value);

        }

        function transferNative (address payable to) payable external {
            require(msg.value > 0, "balance is insufficient");

            uint256 cut = (msg.value * percent) / 100;

            uint256 amount = msg.value - cut;

            to.transfer(amount);

            contractBalance = address(this).balance;

            payable(owner).transfer(cut);

            emit TransferSent(msg.sender, to, amount);
            
        }

        function transferToken (address payable to, uint256 value, bytes32 symbol) external {

            require (owner == msg.sender, "unauthorized");

             uint256 balance = IERC20(parentContract.whitelist(symbol)).balanceOf(contractAddress);

             require (balance > 0, "Balance low");

            uint256 cut = (value * percent) / 100;

            uint256 amount = value - cut;

            IERC20(parentContract.whitelist(symbol)).transfer(to, amount);

            IERC20(parentContract.whitelist(symbol)).transfer(owner, cut);
             
        }
}