/**
 *Submitted for verification at FtmScan.com on 2022-05-10
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
    function mint(address _to, uint256 _mintAmount) external payable returns (uint256[] memory);
    function setGenes(uint256 tokenId, uint256 sequence) external;
    function setStrength(uint256 tokenId, uint256 strentgh) external;
    function getGenes(uint256 tokenId) external view returns(uint256);
    function getStrength(uint256 tokenId) external view returns(uint256);
    function getOriginalSkeletoonBalance(address _owner) external view returns(uint256);
    function ownerOf(uint256 tokenId)  external view returns (address);
}

pragma solidity ^0.8.0;

interface IGlyph{
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getAppliesToTraitType(uint256 tokenId) external view returns(uint256);
    function getStrength(uint256 tokenId) external view returns(uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId)  external view returns (address);
}

pragma solidity ^0.8.0;

interface ITrait{
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTraitId(uint256 tokenId) external view returns(uint256);
    function mint(address _to, uint256 _mintAmount, uint256 _traitId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId)  external view returns (address);
}


pragma solidity ^0.8.0;

contract ToonWorldLogicV1 is Ownable{
    using Strings for uint256;
    using Address for address;

    mapping (uint256 => uint256) timeLock;

    mapping (uint256 => mapping(uint256 => bool)) isTraitMajor;

    uint256 public looper;

    uint256 constant public geneLength  =  1000;
    uint256 constant public strengthLength = 1000;

    uint256 public summonFee = 0;

    uint256 public strPointCost = 0;

    uint256 public startTime;


    address payable lpCollector;
    //require(payable(msg.sender).send(address(this).balance));
    // interface variableName = interface(addressOfContract
    // variableName.function
    ITrait public immutable traits;
    IGlyph public immutable glyphs;
    ISkeletoon public immutable skeletoons;


    constructor(address _ctraits, address _cglyphs, address _cskeletoons, address payable _lpCollector, uint256 _summonFee, uint256 _strFee) 
    {
        ITrait _traits = ITrait(_ctraits);
        IGlyph _glyphs = IGlyph(_cglyphs);

        ISkeletoon _skeletoons = ISkeletoon(_cskeletoons);

        traits = _traits;
        glyphs = _glyphs;
        skeletoons = _skeletoons;

        startTime = block.timestamp;

        lpCollector = _lpCollector;


        summonFee = _summonFee;

        strPointCost = _strFee;
    }


    function getGene(uint256 skeletoonTokenId, uint256 position) public {
        require(skeletoonTokenId <= 10000, "Only Original 10 000 Skeletoons can extract traits");
        uint256 positionStrength = (skeletoons.getStrength(skeletoonTokenId) / strengthLength ** (17-position)) % strengthLength;
        uint256 traitType = (skeletoons.getGenes(skeletoonTokenId) / geneLength ** (17-position)) % geneLength;
        require(traitType != 0, "Can extract void trait");
        require(positionStrength == 100, "Trait is not strong enough to extract");

        skeletoons.setStrength(skeletoonTokenId, (skeletoons.getStrength(skeletoonTokenId) - 100 * (strengthLength ** (17-position))));
        traits.mint(msg.sender, 1, traitType);
    }

    function increaseStrength(uint256 position, uint256 addedStrength, uint256 tokenId) internal {
        uint256 strengthAddition;
        uint256 tempStrength = (skeletoons.getStrength(tokenId) / strengthLength ** (17-position)) % strengthLength;
        if (tempStrength + addedStrength <= 100) {
            strengthAddition = addedStrength;
        } else {
            strengthAddition = 100 - tempStrength;
        }
        skeletoons.setStrength(tokenId , (skeletoons.getStrength(tokenId) + strengthAddition * (strengthLength ** (17-position))));
    }

    
    function getAvailablePoints(uint256 tokenId) public view returns(uint256) {
        if (timeLock[tokenId] == 0){
                return 1;
        } else {
            if (block.timestamp - timeLock[tokenId] < 1 hours){
                return 0;
            }
            if (block.timestamp - timeLock[tokenId] < 4 hours){
                return 1;
            }
            if (block.timestamp - timeLock[tokenId] < 8 hours){
                return 2;
            }
            if (block.timestamp - timeLock[tokenId] < 16 hours){
                return 3;
            }
            if (block.timestamp - timeLock[tokenId] < 32 hours){
                return 4;
            } else {
                return 5;
            }
        }
    }

    function getTimeLocked(uint256 tokenId) public view returns(uint256) {
        return timeLock[tokenId];
    }


    function reduceAvailablePoints(uint256 tokenId, uint256 pointsLeft) internal {
        if (pointsLeft == 5) {
            timeLock[tokenId] = block.timestamp - 32 hours;
        } else if (pointsLeft == 4) {
            timeLock[tokenId] = block.timestamp - 16 hours;
        } else if (pointsLeft == 3) {
            timeLock[tokenId] = block.timestamp - 8 hours;
        } else if (pointsLeft == 2) {
            timeLock[tokenId] = block.timestamp - 4 hours;
        } else if (pointsLeft == 1) {
            timeLock[tokenId] = block.timestamp - 1 hours;
        } else {
            timeLock[tokenId] = block.timestamp;
        } 
    }

    function swapGene(uint256 geneTokenId, uint256 skeletoonTokenId, uint256 position)  internal {
        uint256 geneSequenceNew = (skeletoons.getGenes(skeletoonTokenId) / (geneLength ** (18-position)) * (geneLength ** (18-position))) + (traits.getTraitId(geneTokenId) * (geneLength ** (17-position))) + (skeletoons.getGenes(skeletoonTokenId) % (geneLength ** (17-position)));
        uint256 strSequenceNew = (skeletoons.getStrength(skeletoonTokenId) / (strengthLength ** (18-position)) * (strengthLength ** (18-position))) +  (skeletoons.getStrength(skeletoonTokenId) % (strengthLength ** (17-position)));


        traits.transferFrom(msg.sender, address(this), geneTokenId);
        traits.burn(geneTokenId);

        skeletoons.setGenes(skeletoonTokenId, geneSequenceNew);
        skeletoons.setStrength(skeletoonTokenId, strSequenceNew);

    }

    function increaseStrengthWithGlyph(uint256 glyphTokenId, uint256 skeletoonTokenId, uint256 position) internal {
        glyphs.transferFrom(msg.sender, address(this), glyphTokenId);
        glyphs.burn(glyphTokenId);
        uint256 strengthAddition;
        uint256 tempStrength = (skeletoons.getStrength(skeletoonTokenId) / strengthLength ** (17-position)) % strengthLength;
        if (tempStrength + glyphs.getStrength(glyphTokenId) <= 100) {
            strengthAddition = glyphs.getStrength(glyphTokenId);
        } else {
            strengthAddition = 100 - tempStrength;
        }
        skeletoons.setStrength(skeletoonTokenId , (skeletoons.getStrength(skeletoonTokenId) + strengthAddition * (strengthLength ** (17-position))));
    }
    
    function setFeeSummon(uint256 _fee) public onlyOwner() {
        summonFee = _fee;
    }

    function setStrPointCost(uint256 cost) public onlyOwner(){
        strPointCost = cost;
    }


    function upgradeSkeletoon(uint256 skeletoonTokenId, uint256 glyphTokenId, uint256 geneTokenId, uint256 addedStrength, uint256 position) public {
        require (msg.sender == skeletoons.ownerOf(skeletoonTokenId), "msg sender is not owner of skeletoon");
        require (addedStrength <= getAvailablePoints(skeletoonTokenId), "not enough strength points");
        if (geneTokenId != 0) {
            require(traits.isApprovedForAll(msg.sender, address(this)) == true, "this contract needs to be approved in toonworld traits by msg.sender");
            require(msg.sender == traits.ownerOf(geneTokenId), "msg sender is not owner of trait");
            if (position % 2 == 0) {
                require(isTraitMajor[traits.getTraitId(geneTokenId)][position], "this trait is not major trait for this attribute");
            }
            swapGene( geneTokenId,  skeletoonTokenId,  position);
        }
        if (glyphTokenId != 0){
            require(glyphs.isApprovedForAll(msg.sender, address(this)) == true , "this contract needs to be approved in toonworld glyphs by msg.sender");
            require(msg.sender == glyphs.ownerOf(glyphTokenId), "msg sender is not owner of trait");
            if (position % 2 == 1) {
                require( (glyphs.getAppliesToTraitType(glyphTokenId) / 2**((19-position)/2))%2 == 1, "this glyph can't be applied to this attribute");
            } else {
                require( (glyphs.getAppliesToTraitType(glyphTokenId) / 2**((18-position)/2))%2 == 1, "this glyph can't be applied to this attribute");
            }
            increaseStrengthWithGlyph( glyphTokenId,  skeletoonTokenId,  position);

        }
        reduceAvailablePoints(skeletoonTokenId, (getAvailablePoints(skeletoonTokenId) - addedStrength));
        increaseStrength( position,  addedStrength,  skeletoonTokenId);

    }

    function upgradeSkeletoonPayed(uint256 skeletoonTokenId, uint256 glyphTokenId, uint256 geneTokenId, uint256 addedStrength, uint256 position) public payable{
        require (msg.sender == skeletoons.ownerOf(skeletoonTokenId), "msg sender is not owner of skeletoon");

        uint256 boughtPoints = addedStrength- getAvailablePoints(skeletoonTokenId);

        require(msg.value / (strPointCost) >= boughtPoints , "need FTM to make up for missing points");
        if (geneTokenId != 0) {
            require(traits.isApprovedForAll(msg.sender, address(this)), "this contract needs to be approved in toonworld traits by msg.sender");
            require(msg.sender == traits.ownerOf(geneTokenId), "msg sender is not owner of trait");
            if (position % 2 == 0) {
                require(isTraitMajor[traits.getTraitId(geneTokenId)][position], "this trait is not major trait for this attribute");
            }
            swapGene( geneTokenId,  skeletoonTokenId,  position);
        }
        if (glyphTokenId != 0){
            require(glyphs.isApprovedForAll(msg.sender, address(this)), "this contract needs to be approved in toonworld glyphs by msg.sender");
            require(msg.sender == glyphs.ownerOf(glyphTokenId), "msg sender is not owner of trait");
            require( (glyphs.getAppliesToTraitType(glyphTokenId) / 2**((18-position)/2))%2 == 1, "this glyph can't be applied to this attribute");
            increaseStrengthWithGlyph( glyphTokenId,  skeletoonTokenId,  position);

        }
        timeLock[skeletoonTokenId] = block.timestamp;
        
        lpCollector.transfer(msg.value);

        increaseStrength( position,  addedStrength,  skeletoonTokenId);


    }

    function addTraitAsMajor(uint256 _traitId, uint256 _geneIndex, bool _value) public onlyOwner {
        isTraitMajor[_traitId][_geneIndex] = _value; 
    }



    function summonSkeletoon(uint256[] memory _tokenIds) public payable{
        uint256 geneSeq = 0;
        uint256 skeletoonId = 0;
        require(msg.value >= (summonFee), "FTM sent is less than summoning cost");
        require(traits.isApprovedForAll(msg.sender, address(this)), "This contract is not approved for Traits transactions on behalf of msg.sender");
        require(_tokenIds.length == 9, "Need nine traits to summon");
        require(skeletoons.getOriginalSkeletoonBalance(msg.sender) > 0, "Need original Skeletoon to summon");
        for (looper = 0; looper < 9; looper++){
            require(msg.sender == traits.ownerOf(_tokenIds[looper]), "msg.sender is not owner of these traits");
            require(isTraitMajor[traits.getTraitId(_tokenIds[looper])][looper*2], "traits are mon major in their respective types");
        }
        
        for (looper = 0; looper < 9; looper++){
            geneSeq += traits.getTraitId(_tokenIds[looper]) * (geneLength ** (((9-looper)*2)-1) );
            traits.transferFrom(msg.sender, address(this), _tokenIds[looper]);
            traits.burn(_tokenIds[looper]);
        }
        lpCollector.transfer(msg.value);

        skeletoonId = skeletoons.mint(msg.sender, 1)[0];
        skeletoons.setGenes(skeletoonId , geneSeq);
        timeLock[skeletoonId] = block.timestamp;


         

    }


}