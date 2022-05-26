pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./include/Presale.sol";

/**
    @dev This is the private presale contract, derived from Presale.
        The authorization mechanism is a pair of merkle trees, with hashes pre-calculated
        off chain. 
        One tree represents (index = 0) standard whitelist holders, subject to presale maximum (First-come, first served)
        The second tree (index = 1) represents the reserved or "guaranteed" WL spots

        Prior to calling Presale::buyPresaleAllocation() the dapp will call an off-chain api with the wallet address. 
        The api will validate the wallet address, and return the whitelistIndex and Merkle tree proof array, which will 
        be passed to Presale::buyPresaleAllocation(), which will call the authorization functions here. 

        The proof is then validated against the respective tree, and the effective presaleMaximum is returned.
        If the proof fails, the call reverts.

 */

contract PrivatePresale is Presale {
    // Secondary tree
    bytes32 internal reservedRootHash = 0x0;

    // prettier-ignore
    constructor(
        address owner,
        address _presaleAllocationAddress,
        address _newVaultAddress
    )
        Presale(
            _presaleAllocationAddress,
            _newVaultAddress
        )
    {
        // Ownership is transferred immediately to Multi-sig
        // after deployment, Hashes and presale parameters will need to be proposed and set via multi-sig
        // Likewise, Multi-sig will need to unpause the contract
        _transferOwnership(owner);
    }

    /**
     * @dev The value used to check reserved permission. Base contract has storage for primary hash
     * @param root The rootHash value to save
     */
    function setSecondaryRootHash(bytes32 root) external onlyOwner {
        reservedRootHash = root;
    }

    /**
     * @dev Verification function. Tests the passed in proof.
     */
    function verify(
        address _address,
        uint8 whitelistIndex,
        bytes32[] memory proof
    ) private view returns (bool) {
        // Validate the whitelistIndex parameter
        require(whitelistIndex >= 0 && whitelistIndex <= 1, "invalid whitelist index");
        bytes32 root = whitelistIndex == 1 ? reservedRootHash : rootHash;
        // Ensure that the corresponding hash value is set
        require(root != 0x0, "Root not set");

        // Verify the proof
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev checkAccess called by Presale::buyPresaleAllocation().
     *      verify the proof and return effective presaleMaximum.
     *      MUST revert on failure.
     */
    function checkAccess(uint8 whitelistIndex, bytes32[] memory proof) internal view override returns (uint256) {
        require(verify(msg.sender, whitelistIndex, proof), "invalid merkle proof");

        // whitelistIndex 1 not subject to presale limits
        return whitelistIndex == 0 ? presaleMaximum : 0;
    }

    /**
     * @dev External test verification method
     */
    function verifyAccess(
        address _address,
        uint8 whitelistIndex,
        bytes32[] memory _proof
    ) external view override onlyOwner returns (bool) {
        return verify(_address, whitelistIndex, _proof);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./IPresaleAllocation.sol";

/**
 * @dev Base for presale contracts. 
 *      Both private and public presale contracts inherit this abstract contract,
 *      This provides hooks for validation based on a Merkle-tree style proof,
 *      requiring a bytes32[] parameter, and allows for multiple whitelists 
 *
 * Requires
 *    ALLOCATOR_ROLE in PresaleAllocation contract
 *    Approval for USDC in buyers wallet
 */
abstract contract Presale is Ownable, Pausable {
    /***************************
     * Events
     */
    event UnitsPurchased(address indexed buyer, uint256 currencySold, uint256 unitsBought, uint256 totalAllocation);

    /***************************
     * Data
     */

    // Redemption Factor - This is a divisor for the redemption factor
    uint256 private constant REDEMPTION_FACTOR_MAGNITUDE = 1e9;

    // Root hash used for authorization/presale whitelist
    bytes32 internal rootHash = 0x0;

    // Spending Limits - USDC is 6 decimals (mwei) on FTM
    uint256 public maximumPurchaseCurrency = 1000e6;
    uint256 public minimumPurchaseCurrency = 100e6;

    // Total max for presale. 0 if no limit. Expressed in currency units (USDC).
    // All buys contribute toward the presaleTotal which is checked against this.
    // Guaranteed wl spots will succeed even if presaleTotal > presaleMaximum
    uint256 internal presaleMaximum = 0;

    // For the current presale, this is a usdc to allocation units conversion factor
    // expressed as USDC (mwei) per allocation unit. 15e5 is $1.50 per unit
    uint256 private presalePrice = 0; // 15e5;

    // Launch time for the current presale. Setting this in the future stops the current presale
    // and sets the launch time for the next one
    uint256 private notBefore;

    // Currency used to buy units
    address public constant CURRENCY_TOKEN_ADDRESS=0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IERC20 private constant CURRENCY_TOKEN= IERC20(CURRENCY_TOKEN_ADDRESS);
    
    // Where currency goes
    address public currencyVaultAddress;

    // Allocation/redemption contract
    address public presaleAllocationAddress;
    IPresaleAllocation private allocation;

    // Track currency spent to enforce limits
    mapping(address => uint256) public currencySpent;
    
    // Total USDC received for the current presale
    uint256 public presaleTotal = 0;

    /***************************
     * Admin Methods
     */
    constructor(address _presaleAllocationAddress, address _vaultAddress) {
        require(_presaleAllocationAddress != address(0) && _vaultAddress != address(0), "INVALID PARAMETERS");

        presaleAllocationAddress = _presaleAllocationAddress;
        allocation = IPresaleAllocation(_presaleAllocationAddress);
        currencyVaultAddress = _vaultAddress;

          
        // Start paused.
         _pause();
    }


    /**
     * @dev The value used to check access permission. Implementation specific.
     * @param root The rootHash value to save
     */
    function setRootHash(bytes32 root) external onlyOwner {
        rootHash = root;
    }


    /**
     * @dev Set parameters for the next presale
     * @param unitPrice currency per Allocation Unit
     * @param minCurrency minimum spend per wallet
     * @param maxCurrency maximum spend per wallet
     * @param _notBefore Timestamp for start of presale
     * @param _presaleMaximum Maximum sales in USDC, 0 for unlimited. preSale total will be reset.
     */
    function setPresaleParameters(
        uint256 unitPrice,
        uint256 minCurrency,
        uint256 maxCurrency,
        uint256 _notBefore,
        uint256 _presaleMaximum
    ) external onlyOwner {
        // Max amount allowed (in USDC) per wallet
        maximumPurchaseCurrency = maxCurrency;
        // Min amount allowed (in USDC) per wallet
        minimumPurchaseCurrency = minCurrency;
        // Unit price per allocation unit
        presalePrice = unitPrice;
        // When does sale open?
        notBefore = _notBefore;
        // Ho much (in currency) before sale is sold out
        presaleMaximum = _presaleMaximum;
    }

    /**
     * @dev Remaining to sell in currency. Determines "sold-out" state.
     *      When presaleMaximum is 0, there is no limit.
     * @return available Available. Max uint256 is no limit.
     */
    function remainingForSale() public view returns (uint256 available) {
        // Note that it is possible for presaleTotal to exceed presaleMaximum due to guaranteed WL spots
        return presaleMaximum == 0 ? type(uint256).max : ( presaleTotal > presaleMaximum ? 0 : presaleMaximum - presaleTotal);
    }

    /******************************
     * Authorization implementation
     */

    /**
     * @dev This needs to check access and validate purchase amount within presale limits
     *      This returns the default, which is the presaleMaximum unaltered, because this base class does not do
     *      anything to authorize the wallet. Returning a presaleMaximum of zero effectively allows
     *      a wallet to purchase beyond the presale limit, i.e. guaranteed spot.
     *      Derived contracts can return 0 when a wallet should be permitted to buy in spite of reaching the
     *      presale maximum.
     *      Should revert on access failure
     *
     * @return uint256 effective presale maximum
     */
    function checkAccess(uint8 /* whitelistIndex */, bytes32[] memory /* proof */) internal view virtual returns (uint256) {
        return presaleMaximum;
    }

    /**
     * @dev External function suitable for checking authorization, which should use the same mechanism used by checkAccess().
     */
    function verifyAccess(address /*_address */, uint8 /* whitelistIndex */, bytes32[] calldata /*_proof */) external view virtual returns (bool) {
        return true;
    }

    /* solhint-disable no-empty-blocks */
    /** 
     * @dev Called at the end of a successful allocation or presale units.
     *      Useful when some action needs to occur after an authorized wallet has successfully purchased. NOOP here.
     * 
     */
    function successHook(address /*_address */, uint8 /* whitelistIndex */, bytes32[] memory /*_proof */) internal virtual {
        // 
        // No-op
    }
    /* solhint-enable no-empty-blocks */

    /**************************
     * Buy Tokens
     * @dev Exchange currency (USDC) for an allocation of presale units. 
     *      This is the public interface to presale. 
     *      Perform access checks, and record the allocation, tracking purchase for the wallet in this presale.
     *      This provides a means to pass whitelist parameters (whitelistIndex, proof) to the authorization functions
     *      in derived contracts. This function is agnostic to the value of those parameters. The effect of them is to
     *      either revert or return the effective presale maximum for the sender
     *
     * @param whitelistIndex Whitelist index returned by API
     * @param proof Proof used to establish auth, returned by API
     * @param inputCurrency Amount to spend on pre-sale allocation
     * @return allocationUnitsBought
     */
    function buyPresaleAllocation(uint8 whitelistIndex, bytes32[] calldata proof, uint256 inputCurrency) public whenNotPaused returns (uint256) {
        // Check that everything we need is set up correctly
        require(presalePrice > 0, "Presale price not set");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= notBefore, "PRESALE has not opened.");
        // Can't be a zero-value transaction
        require(inputCurrency > 0, "INVALID_VALUE");

        // Effective presaleMaximum - set to zero for guaranteed wl spots
        // This will revert if the wallet is unauthorized
        uint256 _presaleMaximum = checkAccess(whitelistIndex, proof);

        // Check extrema. Calculate the new spend total for the sender
        uint256 totalSpent = currencySpent[msg.sender] + inputCurrency;


        require(totalSpent >= minimumPurchaseCurrency, "Total Purchase below minimum");
        require(totalSpent <= maximumPurchaseCurrency, "Total purchase exceeds maximum allowed");

        // Sold out? If _presaleMaximum is zero, this wallet has guaranteed entry (still subject to per-wallet limits)
        require(_presaleMaximum == 0 || presaleTotal + inputCurrency <= _presaleMaximum, "Insufficient remaining supply");

        // Units are in gwei (REDEMPTION_FACTOR_MAGNITUDE)
        uint256 unitsToBuy = (inputCurrency * REDEMPTION_FACTOR_MAGNITUDE) / presalePrice;

        // Update total bought before transfer to avoid reentrancy problems
        currencySpent[msg.sender] = totalSpent;
        presaleTotal += inputCurrency;

        // Transfer the tokens from the purchaser
        require(CURRENCY_TOKEN.transferFrom(msg.sender, currencyVaultAddress, inputCurrency), "Currency transfer failed");
        // Allocate the units in the allocation contract
        uint256 totalAllocated = allocation.increaseAllocation(msg.sender, unitsToBuy);

        // Success Hook
        successHook(msg.sender, whitelistIndex, proof);

        // Log purchase
        emit UnitsPurchased(msg.sender, inputCurrency, unitsToBuy, totalAllocated);
        return unitsToBuy;
    }

    /*******************************
     * Pausable Implementation     *
     *******************************/

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT-0
// (c) 2022 Ooze.Finance team



interface IPresaleAllocation {

    
    /// @dev return allocation for the given address
    function allocated(address _address) external view returns (uint256 allocation);

    /// @dev increase the allocation for the given address
    function increaseAllocation(address _address, uint256 increase) external returns (uint256);

    /// @dev decrease the allocation for the given address
    function decreaseAllocation(address _address, uint256 decrease) external returns (uint256);

    /// @dev redeem the total allocation for tokens
    function redeem() external;

    /// @dev decrease allocation by number of tokens
    function decreaseAllocationByTokens(address _address, uint256 tokens) external returns (uint256 remaining, uint256 tokensIssued);

    /// @dev convert allocation units to tokens
    function allocationToTokens(uint256 allocation) external view returns (uint256);

    /// @dev convert tokens to allocation units
    function tokensToAllocation(uint256 tokens) external view returns (uint256);

    /// @dev return allocated tokens for address. 0 if redemption factor not set
    function allocatedTokens(address _address) external view returns (uint256);

    function redemptionFactor() external view returns (uint256);

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