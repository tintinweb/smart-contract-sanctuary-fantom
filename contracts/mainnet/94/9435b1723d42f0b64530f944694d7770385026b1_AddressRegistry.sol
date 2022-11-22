/**
 *Submitted for verification at FtmScan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT
// solc v0.8.12+commit.f00d7308; optimized YES +200 runs
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/**
* @title Address registry
* @dev Contains addresses of other contracts
*/
interface IAddressRegistry {
    /**
    * @notice Get payment token registry address
    * @return address
    */
    function getPaymentTokenRegistryAddress() external view returns (address);

    /**
    * @notice Update payment token registry address
    * @param paymentTokenRegistryAddress Payment token registry address
    */
    function updatePaymentTokenRegistryAddress(address paymentTokenRegistryAddress) external;

    /**
    * @notice Get royalty registry address
    * @return address
    */
    function getRoyaltyRegistryAddress() external view returns (address);

    /**
    * @notice Update royalty registry address
    * @param royaltyRegistryAddress Royalty registry address
    */
    function updateRoyaltyRegistryAddress(address royaltyRegistryAddress) external;
}

/**
 * @dev See {IAddressRegistry}.
 */
contract AddressRegistry is Ownable, IAddressRegistry {
    /**
     * @notice Payment token registry address
     */
    address private _paymentTokenRegistryAddress;

    /**
     * @notice Royalty registry address
     */
    address private _royaltyRegistryAddress;

    /**
     * @dev See {IAddressRegistry-getPaymentTokenRegistryAddress}.
     */
    function getPaymentTokenRegistryAddress() public view returns (address) {
        return _paymentTokenRegistryAddress;
    }

    /**
     * @dev See {IAddressRegistry-updatePaymentTokenRegistryAddress}.
     */
    function updatePaymentTokenRegistryAddress(address paymentTokenRegistryAddress) public onlyOwner {
        _paymentTokenRegistryAddress = paymentTokenRegistryAddress;
    }

    /**
     * @dev See {IAddressRegistry-getRoyaltyRegistryAddress}.
     */
    function getRoyaltyRegistryAddress() public view returns (address) {
        return _royaltyRegistryAddress;
    }

    /**
     * @dev See {IAddressRegistry-updateRoyaltyRegistryAddress}.
     */
    function updateRoyaltyRegistryAddress(address royaltyRegistryAddress) public onlyOwner {
        _royaltyRegistryAddress = royaltyRegistryAddress;
    }
}