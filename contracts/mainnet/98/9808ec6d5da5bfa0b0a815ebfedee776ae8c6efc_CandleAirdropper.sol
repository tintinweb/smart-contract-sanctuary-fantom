/**
 *Submitted for verification at FtmScan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
// Based on Loot (for Adventurers)
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
    function decimals() external view returns (uint8);
}


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

contract CandleAirdropper is Ownable {
    address[] public AirdropList = [
        0xfCF81069eabDF98cE02c9Fc3510e5C64135772eF, 0xb0FabE3bCAC50F065DBF68C0B271118DDC005402, 0x8DE3c3891268502F77DB7E876d727257DEc0F852, 0x7FA982AE8F9667B8D58ab09779029f228289B669, 0xa7952d5830084fE2d73EB8cF21c230E0e35D6734, 0x28aa4F9ffe21365473B64C161b566C3CdeAD0108, 0xE30D6736B740C9Ea51c5b21C2ac0646785fbF5AD, 0x5897eABd827d38A5A8042051b9210bF6802e89D6, 0x858AEf29849ad338BE4d7855E01C23FD66823E47, 0x2Bda28b8D384597cC5FDfFBF9C3Cb32789f600f8, 0x189589AbC6794F1C9b385099849C49598e987A68, 0x89557EDF57c4Ac779973e2C4e7Ac8530eFf69A1b, 0x3bD93BE19256A9639cA808B49A2cfaAc5076b5a8, 0x997338daC7cAdB07878C8483C512e901166fe4df, 0x5d02c857E98465f5b3a957B1f43569C4dAe58cA0, 0xED06B7C112F3FF075a03142eEc8B06350D69c8B3, 0x74c4C82AD166b621fa60A730C9d414fc17d33dB3, 0xCc879Ab4DE63FC7Be6aAca522285D6F5d816278e
        ];

    uint256[] public AllocationList = [
        2894 * 10 ** 18, 1166 * 10 ** 18, 947 * 10 ** 18, 788 * 10 ** 18, 719 * 10 ** 18, 578 * 10 ** 18, 560 * 10 ** 18, 510 * 10 ** 18, 371 * 10 ** 18, 273 * 10 ** 18, 257 * 10 ** 18, 203 * 10 ** 18, 182 * 10 ** 18, 182 * 10 ** 18, 182 * 10 ** 18, 91 * 10 ** 18, 91 * 10 ** 18, 1
    ];

    uint256 public listLength = 18;

    function changeAllocation(uint256 allocationNumber, uint256 allocation) public onlyOwner {
        AllocationList[allocationNumber] = allocation;
    }

    function changeRecipient(uint256 recipientNumber, address recipient) public onlyOwner {
        AirdropList[recipientNumber] = recipient;
    }

    function addRecipientAndAllocation(address recipient, uint256 allocation) public onlyOwner {
        AirdropList.push(recipient);
        AllocationList.push(allocation);
        listLength++;
    }

    function change(address[] memory newRecipients, uint256[] memory newAllocations) public onlyOwner {
        require(newAllocations.length == newRecipients.length, "Array lengths do not match");
        AirdropList = newRecipients;
        AllocationList = newAllocations;
        listLength = newAllocations.length;
    }


    function airdrop(address token) public {
        require(msg.sender == 0x97E82cb67d77d0f697A9A4ac419FDaAd5b342d5E, "not multisig");
        require(AllocationList.length == AirdropList.length, "Array lengths do not match");
        for (uint256 i = 0; i < listLength; i++) {
            if (AllocationList[i] > 0) {
                IERC20(token).transferFrom(
                    msg.sender,
                    address(AirdropList[i]),
                    AllocationList[i]);
            }
        }
    }

}