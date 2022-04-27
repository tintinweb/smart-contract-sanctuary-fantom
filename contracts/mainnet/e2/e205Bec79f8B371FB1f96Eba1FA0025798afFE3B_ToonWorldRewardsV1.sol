/**
 *Submitted for verification at FtmScan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

interface ISkeletoon{
    function mint(address _to, uint256 _mintAmount) external returns (uint256[] memory);
    function setGenes(uint256 tokenId, uint256 sequence) external;
    function setStrength(uint256 tokenId, uint256 strentgh) external;
    function getGenes(uint256 tokenId) external view returns(uint256);
    function getStrength(uint256 tokenId) external view returns(uint256);
    function getOriginalSkeletoonBalance(address _owner) external view returns(uint256[] memory);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
    function supplygen2() external view returns (uint256);
    function ownerOf(uint256 tokenId)  external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IGlyph{
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function _burn(uint256 tokenId) external;
    function getAppliesToTraitType(uint256 tokenId) external view returns(uint256);
    function getStrength(uint256 tokenId) external view returns(uint256);
    function mint(address _to, uint256 _mintAmount, uint256 _appliesToTraitType, uint256 _setGlyphStrength) external payable;
    //function approve(address to, uint256 tokenID ) external;
    //function safeTransferFrom (address sender, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId)  external view returns (address);
}

pragma solidity ^0.8.0;

interface ITrait{
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function _burn(uint256 tokenId) external;
    function getTraitId(uint256 tokenId) external view returns(uint256);
    function mint(address _to, uint256 _mintAmount, uint256 _traitId) external payable;
    function transfer(address recipient, uint256 amount) external returns (bool);
    //function approve(address to, uint256 tokenID ) external;
    //function safeTransferFrom (address sender, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId)  external view returns (address);
}

pragma solidity ^0.8.0;

interface IBucks{
    function _burn(address account, uint256 amount) external;
    function approve(address to, uint256 tokenID ) external;
    function safeTransferFrom (address sender, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId)  external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.8.0;

contract ToonWorldRewardsV1 is Ownable{
    using Strings for uint256;
    using Address for address;

    mapping (uint256 => uint256) timeLock;
    mapping (uint256 => uint256) geneReward;
    mapping (uint256 => uint256) geneRewardMulti;
    mapping (uint256 => uint256) mintedGlyphAppliesTo;
    mapping (uint256 => uint256) glyphTraitMultiBonus;
    mapping (uint256 => uint256) personalTickets;


    uint256 public startTime;

    uint256 constant public geneLength  =  1000;
    uint256 constant public strengthLength = 1000;

    uint256 public baseToonBuckReward = 2000000000000000000;
    uint256 public rewardMulti = 1;
    uint256 public allTickets = 0;

    uint256 looper;

    ITrait public immutable traits;
    IGlyph public immutable glyphs;
    ISkeletoon public immutable skeletoons;
    IBucks public immutable toonBucks;

    constructor(address _ctraits, address _cglyphs, address _cbucks, address _cskeletoons) 
    {
        ITrait _traits = ITrait(_ctraits);
        IGlyph _glyphs = IGlyph(_cglyphs);
        IBucks _toonBucks = IBucks(_cbucks);
        ISkeletoon _skeletoons = ISkeletoon(_cskeletoons);

        traits = _traits;
        glyphs = _glyphs;
        skeletoons = _skeletoons;
        toonBucks = _toonBucks;
        startTime = block.timestamp;
    }

    function claimSingleReward (uint256 skeletoonTokenId) public {
        require(msg.sender == skeletoons.ownerOf(skeletoonTokenId));
        require(getAvailableRewards(skeletoonTokenId) > 0, "This skeletoon needs to wait a bit more for reward");
        uint256 availableRewards = getAvailableRewards(skeletoonTokenId);
        timeLock[skeletoonTokenId] = block.timestamp;
        uint256 geneSeq = skeletoons.getGenes(skeletoonTokenId);
        uint256 strengthSeq = skeletoons.getStrength(skeletoonTokenId);
        uint256 TWBamount = 0;
        uint256 glyphStrength = 0;
        for (looper = 0; looper < 18; looper++){
            uint256 tempGene = (geneSeq / (geneLength**(17-looper))) % geneLength;
            uint256 tempStr = (strengthSeq / (strengthLength**(17-looper))) % strengthLength;
            if ((tempStr != 0) && (geneReward[tempGene] == 1 || geneReward[tempGene] == 4 || geneReward[tempGene] == 6 || geneReward[tempGene] == 7)) {
                if (toonBucks.balanceOf(address(this)) >=  (baseToonBuckReward * rewardMulti * geneRewardMulti[tempGene] * tempStr * availableRewards)) {
                    TWBamount += baseToonBuckReward * rewardMulti * geneRewardMulti[tempGene] * tempStr * availableRewards;
                } else {
                    TWBamount += toonBucks.balanceOf(address(this));
                }
            } 
            if (geneReward[tempGene] == 2 || geneReward[tempGene] == 4 || geneReward[tempGene] == 5 || geneReward[tempGene] == 7){
                if (skeletoonTokenId <= 10000)
                {
                allTickets = allTickets + tempStr;
                personalTickets[skeletoonTokenId] =  personalTickets[skeletoonTokenId] + tempStr;
                }
            } 
            if (geneReward[tempGene] == 3 || geneReward[tempGene] == 5 || geneReward[tempGene] == 6 || geneReward[tempGene] == 7){
                glyphStrength = (tempStr / 10) * glyphTraitMultiBonus[tempGene];
                if (glyphStrength > 0)
                {
                    glyphs.mint(msg.sender , availableRewards, mintedGlyphAppliesTo[tempGene] , glyphStrength );
                }
            }
            geneSeq = geneSeq % (geneLength**(18-looper));
            strengthSeq = strengthSeq % (strengthLength**(18-looper));
        }
        if (TWBamount > 0 ){
            toonBucks.transfer(msg.sender, TWBamount);
        }
    }

    function getPersonalTickets (uint256 tokenId) public view returns (uint256) {
        return personalTickets[tokenId];
    }


    function baseRewardMulti (uint256 _rewardMulti) public onlyOwner {
        rewardMulti = _rewardMulti;
    }

    function addRewardType(uint256 _rewardType, uint256 _traitId) public onlyOwner {
        geneReward[_traitId] = _rewardType;
    }

    function getRewardType(uint256 traitId) public view returns (uint256) {
       return geneReward[traitId];
    }

    function addMintedGlyphAppliesTo(uint256 _glyphAppliesTo, uint256 _traitId) public onlyOwner{
        mintedGlyphAppliesTo[_traitId] = _glyphAppliesTo;
    }

    
    function getMintedGlyphAppliesTo(uint256 traitId) public view returns (uint256) {
       return mintedGlyphAppliesTo[traitId];
    }

    function setGlyphTraitMultiBonus(uint256 _rewardMulti, uint256 _traitId) public onlyOwner {
        glyphTraitMultiBonus[_traitId] = _rewardMulti;
    }

    function getGlyphTraitMultiBonus(uint256 traitId) public view returns (uint256) {
       return glyphTraitMultiBonus[traitId];
    }

    function addRewardMulti(uint256 _rewardMulti, uint256 _traitId) public onlyOwner {
        geneRewardMulti[_traitId] = _rewardMulti;
    }

    function getRewardMulti(uint256 traitId) public view returns (uint256) {
       return geneRewardMulti[traitId];
    }


    function getTimeLock(uint256 skeletoonTokenId) public view returns (uint256) {
       return timeLock[skeletoonTokenId];
    }

    function getAvailableRewards(uint256 skeletoonTokenId) public view returns(uint256){
        if (skeletoonTokenId <= 10000) {
            if (timeLock[skeletoonTokenId] == 0){
                return 1;
            } else {
                if (block.timestamp - timeLock[skeletoonTokenId] < 8 hours){
                    return 0;
                }
                if (block.timestamp - timeLock[skeletoonTokenId]  < 24 hours){
                    return 1;
                }
                if (block.timestamp - timeLock[skeletoonTokenId]  < 48 hours){
                    return 2;
                } else {
                    return 3;
                } 
            }
        } else {
            if (timeLock[skeletoonTokenId] == 0){
                return 1;
            } else {
                if (block.timestamp - timeLock[skeletoonTokenId] < (skeletoons.supplygen2()* 3)){
                    return 0;
                }
                if (block.timestamp - timeLock[skeletoonTokenId]  < (skeletoons.supplygen2()* 9)){
                    return 1;
                }
                if (block.timestamp - timeLock[skeletoonTokenId]  < (skeletoons.supplygen2()* 18)){
                    return 2;
                } else {
                    return 3;
                } 
            }
        }
    }

}