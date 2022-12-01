/**
 *Submitted for verification at FtmScan.com on 2022-12-01
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/token.sol


pragma solidity ^0.8.2;


contract Test is Ownable{

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "Test";
    string public symbol = "TST";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    address admin;

    address taxWallet = 0x9444b4C276f36D988A30F5C06958345FfF8439F2;
    address burnWallet;

    uint taxFee = 5;
    uint burnFee = 0;
    uint taxFee1 = 0;
    uint totalFee = 5;
    
    uint taxedCoins;

    constructor() {
        balances[msg.sender] = totalSupply;
        admin = msg.sender;
    }

    function balanceOf(address owner) public view returns(uint) {
        uint actualBalance = balances[owner] + ((balances[owner] * taxedCoins) / totalSupply);
        return actualBalance;
    }

/*
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
*/

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Balance is too low");

        balances[taxWallet] += (taxFee * value) / 100;
        balances[burnWallet] += (burnFee * value) / 100;

        taxedCoins += (taxFee1 * value) / 100;

        balances[to] += (value * (100 - totalFee)) / 100;
        if (value <= balances[msg.sender]) {
            balances[msg.sender] -= value;
        } else {
            uint leftoverCoins = value - balances[msg.sender];
            balances[msg.sender] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Balance is too low");
        require(allowance[from][msg.sender] >= value, "Allowance is too low");

        balances[taxWallet] += (taxFee * value) / 100;
        balances[burnWallet] += (burnFee * value) / 100;

        taxedCoins += (taxFee1 * value) / 100;

        balances[to] += (value * (100 - totalFee)) / 100;
        if (value <= balances[from]) {
            balances[from] -= value;
        } else {
            uint leftoverCoins = value - balances[from];
            balances[from] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getNumberOfTaxedCoins() public view returns(uint) {
        return taxedCoins;
    }

    function getTaxFee() public view returns(uint) {
        return taxFee1;
    }

    function changeFees(uint charity, uint burn, uint tax) public {
        require(msg.sender == admin, "Only admin is allowed to change the fees");
        taxFee = charity;
        burnFee = burn;
        taxFee1 = tax;
        totalFee = charity + burn + tax;
    }

}