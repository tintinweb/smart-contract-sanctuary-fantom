// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

 interface IERC20Votes {

    function mint(address to, uint256 amount) external;

 }
    contract CertiBits is Ownable {
    
    IERC20Votes TokenBits;
    uint public totalCertiBits;
    uint256 public bonusReward; //Amount of Tokens for reward

    

    struct signature{

        address signer;
        string sign_data;
    }

    mapping (string => signature[]) hash2SignaturesList;
    mapping (address => string[]) address2SignaturesList;
    mapping (address => mapping(string => bool)) address2hashstate;
    mapping (address => uint) pubkey2IDu;
    mapping (address => bool) public address2state;
    mapping (address => uint) signatures;

    event newRewardValue(uint256 _rewardAmount);
    

    constructor (IERC20Votes _TokenBitsAddress, uint256 _bonusReward) {
        TokenBits = _TokenBitsAddress;
        bonusReward = _bonusReward;
    }

    function changeTokenAddress(IERC20Votes _newTokenBits) public onlyOwner {
        TokenBits = _newTokenBits;
    }


    function setReward (uint256 _rewardAmount) public onlyOwner {
        bonusReward = _rewardAmount;
        emit newRewardValue(_rewardAmount);
    }



    function Certify(string memory _hash, string memory _data) payable public {
        require(!address2hashstate[msg.sender][_hash],"Address already signed these hash");
        require(msg.value>=1 ether, "min payment for certi is 1 Celo");
        payable(owner()).transfer(msg.value);
        address2hashstate[msg.sender][_hash]=true;
        hash2SignaturesList[_hash].push(signature(msg.sender, _data));
        address2SignaturesList[_msgSender()].push(_hash);
        totalCertiBits++;
        TokenBits.mint(msg.sender,bonusReward);
        }

    
    function validateHash(string memory _hash) public view returns(signature[] memory) {
        return (hash2SignaturesList[_hash]);
    }
    function mySignatures() public view returns(string[] memory) {
        return (address2SignaturesList[_msgSender()]);
    }
    function validateSingleHash(string memory _hash, uint _i) public view returns(address, string memory) {
        return (hash2SignaturesList[_hash][_i].signer,hash2SignaturesList[_hash][_i].sign_data);
    }
    function mySingleSignature(uint _i) public view returns(string memory) {
        return (address2SignaturesList[_msgSender()][_i]);
    }
    function validateHashLength(string memory _hash) public view returns(uint) {
        return (hash2SignaturesList[_hash].length);
    }
    function mySignaturesLength() public view returns(uint) {
        return (address2SignaturesList[_msgSender()].length);
    }
}