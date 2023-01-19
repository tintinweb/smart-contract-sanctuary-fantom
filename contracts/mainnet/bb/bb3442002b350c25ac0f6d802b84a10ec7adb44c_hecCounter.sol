/**
 *Submitted for verification at FtmScan.com on 2023-01-19
*/

// SPDX-License-Identifier: MIT
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/hecIndex.sol


pragma solidity ^0.8.15;




interface IwsHEC {
    function wsHECTosHEC(uint256 _amount) external view returns (uint256);
}

interface IwfNFTs {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

interface ILockFarm {
    function fnfts(uint256 _tokenId)
        external
        view
        returns (
            uint256 id,
            uint256 amount,
            uint256 startTime,
            uint256 secs,
            uint256 multiplier,
            uint256 rewardDebt,
            uint256 pendingReward
        );
}

interface ILiquidityValueCalculator {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract hecCounter {
    address public hecAddress = 0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0;
    address public shecAddress = 0x75bdeF24285013387A47775828bEC90b91Ca9a5F;
    address public wshecAddress = 0x94CcF60f700146BeA8eF7832820800E2dFa92EdA;
    address public fNFTsAddress = 0x51aEafAC5E4494E9bB2B9e5176844206AaC33Aa3;
    address public hecUsdcLpAddress =
        0x0b9589A2C1379138D4cC5043cE551F466193c8dE;
    address public hecTorLpAddress =
        0x4339b475399AD7226bE3aD2826e1D78BBFb9a0d9;

    address public fNFTsFarmsHEC = 0x80993B75e38227f1A3AF6f456Cf64747F0E21612;
    address public fNFTsFarmsHECUSDC =
        0xd7faE64DD872616587Cc8914d4848947403078B8;
    address public fNFTsFarmsHECTOR =
        0xB13610B4e7168f664Fcef2C6EbC58990Ae835Ff1;

    struct FNFTInfo {
        uint256 id;
        uint256 amount;
        uint256 startTime;
        uint256 secs;
        uint256 multiplier;
        uint256 rewardDebt;
        uint256 pendingReward;
    }

    function computeLiquidityShareValue(uint256 liquidity, address _lp)
        public
        view
        returns (uint256 _LPHecs)
    {
        uint256 _lpSupply = IUniswapV2ERC20(_lp).totalSupply();
        uint256 _lpRatio = liquidity / (_lpSupply / 1 gwei);
        (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ) = ILiquidityValueCalculator(_lp).getReserves();
        _LPHecs = (_reserve1 / 1 gwei) * _lpRatio;
    }

    function getHecAmount(address _address) public view returns (uint256) {
        uint256 hecOwnedAmount = IERC20(hecAddress).balanceOf(_address);
        uint256 shecOwnedAmount = IERC20(shecAddress).balanceOf(_address);
        uint256 wshecOwnedAmount = IERC20(wshecAddress).balanceOf(_address);
        uint256 ownedwsHECtosHec = IwsHEC(wshecAddress).wsHECTosHEC(
            wshecOwnedAmount
        );
        uint256 totalHEC = hecOwnedAmount + shecOwnedAmount + ownedwsHECtosHec;
        uint256 ownedFNFTS = IERC721(fNFTsAddress).balanceOf(_address);
        if (ownedFNFTS > 0) {
            for (uint256 i = 0; i < ownedFNFTS; i++) {
                uint256 _tokenId = IwfNFTs(fNFTsAddress).tokenOfOwnerByIndex(
                    _address,
                    i
                );
                FNFTInfo memory _firstFarm;
                (
                    _firstFarm.id,
                    _firstFarm.amount,
                    _firstFarm.startTime,
                    _firstFarm.secs,
                    _firstFarm.multiplier,
                    _firstFarm.rewardDebt,
                    _firstFarm.pendingReward
                ) = ILockFarm(fNFTsFarmsHEC).fnfts(_tokenId);
                if (_firstFarm.amount >= 1) {
                    totalHEC += _firstFarm.amount;
                } else {
                    FNFTInfo memory _secondFarm;
                    (
                        _secondFarm.id,
                        _secondFarm.amount,
                        _secondFarm.startTime,
                        _secondFarm.secs,
                        _secondFarm.multiplier,
                        _secondFarm.rewardDebt,
                        _secondFarm.pendingReward
                    ) = ILockFarm(fNFTsFarmsHECUSDC).fnfts(_tokenId);
                    uint256 _LPHecs = computeLiquidityShareValue(
                        _secondFarm.amount,
                        hecUsdcLpAddress
                    );
                    if (_LPHecs > 0) {
                        totalHEC += _LPHecs;
                    } else {
                        FNFTInfo memory _thirdFarm;
                        (
                            _thirdFarm.id,
                            _thirdFarm.amount,
                            _thirdFarm.startTime,
                            _thirdFarm.secs,
                            _thirdFarm.multiplier,
                            _thirdFarm.rewardDebt,
                            _thirdFarm.pendingReward
                        ) = ILockFarm(fNFTsFarmsHECTOR).fnfts(_tokenId);
                        uint256 _LPHecs2 = computeLiquidityShareValue(
                            _thirdFarm.amount,
                            hecTorLpAddress
                        );
                        if (_LPHecs2 > 0) {
                            totalHEC += _LPHecs2;
                        }
                    }
                }
            }
        }

        return totalHEC;
    }
}