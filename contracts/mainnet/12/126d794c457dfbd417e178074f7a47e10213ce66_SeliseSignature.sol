/**
 *Submitted for verification at FtmScan.com on 2022-06-13
*/

// File: @openzeppelin\contracts\utils\Context.sol

 

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

// File: @openzeppelin\contracts\security\Pausable.sol
 

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

 

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

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol

 

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts\signature\SeliseSignatureWithPayment.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity>=0.7.0 <0.9.0;
contract SeliseSignature is Ownable, Pausable, ReentrancyGuard {

    uint256 public balance;

    mapping(bytes32=>SigningEvidence) evidence;

    SigningEvidence private signingEvidence;

    uint256 public signaturePrice;

    struct  SigningEvidence {
        address signer;
        string contractHashOriginalState;
        string contractHashLastModifiedState;
        bool signed;
        uint appTimeStamp;
        uint blockTimeStamp;
    }

    event Signature (
        address account, 
        string originalContract, 
        string signedContract, 
        bool signatureConsent, 
        uint applicationTimeStamp, 
        uint blockTimeStamp
    );
    
    event Withdraw(
        address account, 
        uint256 balanceBefore, 
        uint256 balanceAfter
    );

    event PriceChange(
        uint256 priceBefore, 
        uint256 priceAfter,
        uint changedTime
    );

    constructor() Ownable() Pausable() ReentrancyGuard() { 
         
         signaturePrice = 1e17;
    }

    function withdraw() onlyOwner() nonReentrant() public {
       
        uint256 balanceBefore = address(this).balance; 
        address contractOwner = owner();
        payable(contractOwner).transfer(balanceBefore);
        balance = 0;

        emit Withdraw(
            contractOwner, 
            balanceBefore, 
            balance
        );
    }

    function sign (
        bool _signConsent, 
        string memory  _contractHashOriginalState, 
        string memory _contractHashLastModifiedState, 
        uint _appTimeStamp) 
        public hasNotPreviouslySigned ( _contractHashOriginalState) whenNotPaused()  payable{

        require(_signConsent, "You did not give consent to sign this/these contract/contracts");
        require(msg.value >= signaturePrice, "Signture price is more" );

        balance+= msg.value;

        bytes32 evidenceKey = callKeccak256(
            append(
                toString(msg.sender),
                "-", 
                _contractHashOriginalState
                )
            );

        signingEvidence = SigningEvidence(
            msg.sender, 
            _contractHashOriginalState, 
            _contractHashLastModifiedState, 
            _signConsent, 
            _appTimeStamp, 
            block.timestamp
            );

        evidence[evidenceKey] = signingEvidence;
       
        emit Signature(
            msg.sender,
            _contractHashOriginalState, 
            _contractHashLastModifiedState, 
            _signConsent, 
            _appTimeStamp, 
            block.timestamp
            );
    }
  
    function getEvidence(
        address _address, 
        string memory  _contractHashOriginalState
        ) public view returns( 
            bool _signed, 
            uint _appTimeStamp, 
            uint _blockTimeStamp
        ){

        bytes32 evidenceKey = callKeccak256(append(toString(_address),"-", _contractHashOriginalState));
        _signed = evidence[evidenceKey].signed;
        _blockTimeStamp = evidence[evidenceKey].blockTimeStamp;
        _appTimeStamp = evidence[evidenceKey].appTimeStamp;
    }

    function changeThePriceOfSignature(uint256 newPrice) onlyOwner() public {

        uint256 priceBefore = signaturePrice;
        signaturePrice = newPrice;

        emit PriceChange(
            priceBefore, 
            newPrice, 
            block.timestamp
        );
    }

    function pause() public  whenNotPaused() onlyOwner() {
        _pause();     
    }

    function unpause() public  whenPaused() onlyOwner() {
        _unpause();     
    }

    //Private functions
    function callKeccak256(string memory  _value) private pure returns(bytes32  _result){

      _result = keccak256(bytes(_value));
    }  
   
    function append(string memory  a, string memory  b, string memory  c) 
    private pure returns ( string memory  _value) {

        _value = string(abi.encodePacked(a, b, c));
    }

    function toString(address account) private pure returns(string memory) {

        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) private pure returns(string memory) {

        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    modifier hasNotPreviouslySigned(string memory  _documentsHash) {

        bytes32 evidenceKey = callKeccak256(append(toString(msg.sender),"-", _documentsHash));
        bool checkAlreadySigned = evidence[evidenceKey].signed;
        require(!checkAlreadySigned, "You have already signed");
        _;
    }

}