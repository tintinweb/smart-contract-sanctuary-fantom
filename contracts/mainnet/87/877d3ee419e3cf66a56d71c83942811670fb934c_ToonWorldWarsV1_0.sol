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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

interface IFractionReward{
    function sendWinning (address winner, uint256 prize) external;
}

pragma solidity ^0.8.0;

interface IReward{
    function pointSpender (uint256 points, uint256 pointType,uint256 tokenId) external;
    function getPoints(uint256 skeletoonTokenId) external returns(uint256[] memory);
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
    function getSkeletoonProperties(uint256 tokenId) external view returns(uint256[] memory);
}

pragma solidity ^0.8.0;

contract ToonWorldWarsV1_0 is Ownable, ReentrancyGuard{
    using Strings for uint256;
    using Address for address;

    mapping (uint256 => address) walletIndex;
    mapping (address => uint256) walletFraction;
    mapping (address => uint256) walletPoints;
    mapping (address => uint256) profilePic;

    uint256 public walletsInGame = 0;
    uint256 public skeletoonFractionCount = 0;
    uint256 public zombieFractionCount = 0;
    uint256 public demonFractionCount = 0;

    uint256 public skeletoonFractionPoints = 0;
    uint256 public zombieFractionPoints = 0;
    uint256 public demonFractionPoints = 0;


    uint256 looper;

    IReward public immutable rewards;
    ISkeletoon public immutable skeletoons;
    IFractionReward public immutable fractionReward;


    constructor(address _crewards, address _cskeletoons, address _cfractionReward) 
    {

        IReward _rewards = IReward(_crewards);
        ISkeletoon _skeletoons = ISkeletoon(_cskeletoons);
        IFractionReward _fractionReward = IFractionReward(_cfractionReward);

        rewards = _rewards;
        skeletoons = _skeletoons;
        fractionReward = _fractionReward;
    }

    function fortifyPoints (uint256 spTokenId, uint256 points) public nonReentrant{
        require(block.timestamp >= 1652202000,"Season has not yet started");
        require(skeletoons.ownerOf(spTokenId) == msg.sender, "msg.sender bust be owner of token");
        require(walletFraction[msg.sender] != 0, "You must belong to a fraction");
        require((rewards.getPoints(spTokenId)[0] + rewards.getPoints(spTokenId)[walletFraction[msg.sender]]) >= points, "You dont have enought Points");
        if (points <= rewards.getPoints(spTokenId)[0]){
            rewards.pointSpender(points, 0, spTokenId);
            walletPoints[msg.sender] += points;
            if (walletFraction[msg.sender] == 1)
            {
                skeletoonFractionPoints += points;
            }
            if (walletFraction[msg.sender] == 2)
            {
                zombieFractionPoints += points;
            }
            if (walletFraction[msg.sender] == 3)
            {
                demonFractionPoints += points;
            }
        } else {
            uint256 fractionPoints = points - rewards.getPoints(spTokenId)[0];
            rewards.pointSpender(rewards.getPoints(spTokenId)[0], 0, spTokenId);
            rewards.pointSpender(fractionPoints, walletFraction[msg.sender], spTokenId);
            walletPoints[msg.sender] += points;
            if (walletFraction[msg.sender] == 1)
            {
                skeletoonFractionPoints += points;
            }
            if (walletFraction[msg.sender] == 2)
            {
                zombieFractionPoints += points;
            }
            if (walletFraction[msg.sender] == 3)
            {
                demonFractionPoints += points;
            }
        }
    }

    function attackPoints (uint256 spTokenId, uint256 points, address attacked) public nonReentrant{
        require(block.timestamp >= 1652202000,"Season has not yet started");
        require(walletFraction[msg.sender] != walletFraction[attacked], "You can't attack your own fraction");
        require(walletFraction[attacked] != 0, "You can't attack unaligned addresses");
        require(skeletoons.ownerOf(spTokenId) == msg.sender, "msg.sender bust be owner of token");
        require(rewards.getPoints(spTokenId)[walletFraction[msg.sender]] >= points, "You dont have enought Points");
            if (walletFraction[attacked] == 1)
            {
                if (walletPoints[attacked] < points) {
                    rewards.pointSpender(walletPoints[attacked], walletFraction[msg.sender], spTokenId);
                    skeletoonFractionPoints -= walletPoints[attacked];
                    walletPoints[attacked] = 0;               
                } else {
                    rewards.pointSpender(points, walletFraction[msg.sender], spTokenId);
                    walletPoints[attacked] -= points;
                    skeletoonFractionPoints -= points;
                }      
            }
            if (walletFraction[attacked] == 2)
            {
                if (walletPoints[attacked] < points) {
                    rewards.pointSpender(walletPoints[attacked], walletFraction[msg.sender], spTokenId);
                    zombieFractionPoints -= walletPoints[attacked];
                    walletPoints[attacked] = 0;                  
                } else {
                    rewards.pointSpender(points, walletFraction[msg.sender], spTokenId);
                    walletPoints[attacked] -= points;
                    zombieFractionPoints -= points;
                }   
            }
            if (walletFraction[attacked] == 3)
            {
                if (walletPoints[attacked] < points) {
                    rewards.pointSpender(walletPoints[attacked], walletFraction[msg.sender], spTokenId);
                    demonFractionPoints -= walletPoints[attacked];
                    walletPoints[attacked] = 0;                   
                } else {
                    rewards.pointSpender(points, walletFraction[msg.sender], spTokenId);
                    walletPoints[attacked] -= points;
                    demonFractionPoints -= points;
                }   
            }
    }

    function changeFraction (uint256 fraction) public nonReentrant{
        require (walletFraction[msg.sender] != fraction, "You can't change into same fraction");
        require (fraction == 1 || fraction == 2 || fraction == 3, "This fraction does not exist");
        if (walletFraction[msg.sender] == 0){
            walletFraction[msg.sender] = fraction;
            walletPoints[msg.sender] = 0;
            walletIndex[walletsInGame] = msg.sender;
            walletsInGame++;
        } else {
            if (walletFraction[msg.sender] == 1){
                skeletoonFractionPoints -= walletPoints[msg.sender];
            } else if (walletFraction[msg.sender] == 2){
                zombieFractionPoints -= walletPoints[msg.sender];
            } else if (walletFraction[msg.sender] == 3){
                demonFractionPoints -= walletPoints[msg.sender];
            }
            walletFraction[msg.sender] = fraction;
            walletPoints[msg.sender] = 0;
        }
    }

    function endSeason () public nonReentrant{
        require(block.timestamp >= 1653411600, "Season is not over yet.");
        uint256 winnerFraction = 0;
        uint256 winner1Points = 0;
        uint256 winner2Points = 0;
        uint256 winner3Points = 0;
        uint256 winner4Points = 0;
        uint256 winner5Points = 0;
        address winner1 = address(0);
        address winner2 = address(0);
        address winner3 = address(0);
        address winner4 = address(0);
        address winner5 = address(0);
        if (skeletoonFractionPoints > zombieFractionPoints && skeletoonFractionPoints > demonFractionPoints){
            winnerFraction = 1;
        } else if (zombieFractionPoints > demonFractionPoints){
            winnerFraction = 2;
        } else {
            winnerFraction = 3;
        }
        for (looper = 0; looper <= walletsInGame; looper++){
            if (walletFraction[walletIndex[looper]] == winnerFraction){
                if (walletPoints[walletIndex[looper]] > winner1Points) {
                    winner5 = winner4;
                    winner5Points = winner4Points;
                    winner4 = winner3;
                    winner4Points = winner3Points;
                    winner3 = winner2;
                    winner3Points = winner2Points;
                    winner2 = winner1;
                    winner2Points = winner1Points;
                    winner1 = walletIndex[looper];
                    winner1Points = walletPoints[walletIndex[looper]];
                } else if  (walletPoints[walletIndex[looper]] > winner2Points) {
                    winner5 = winner4;
                    winner5Points = winner4Points;
                    winner4 = winner3;
                    winner4Points = winner3Points;
                    winner3 = winner2;
                    winner3Points = winner2Points;
                    winner2 = walletIndex[looper];
                    winner2Points = walletPoints[walletIndex[looper]];
                } else if (walletPoints[walletIndex[looper]] > winner3Points) {
                    winner5 = winner4;
                    winner5Points = winner4Points;
                    winner4 = winner3;
                    winner4Points = winner3Points;
                    winner3 = walletIndex[looper];
                    winner3Points = walletPoints[walletIndex[looper]];
                } else if (walletPoints[walletIndex[looper]] > winner4Points) {
                    winner5 = winner4;
                    winner5Points = winner4Points;
                    winner4 = walletIndex[looper];
                    winner4Points = walletPoints[walletIndex[looper]];
                } else if (walletPoints[walletIndex[looper]] > winner5Points) {
                    winner5 = walletIndex[looper];
                    winner5Points = walletPoints[walletIndex[looper]];
                }
            }
        }
        fractionReward.sendWinning(winner1, 1);
        fractionReward.sendWinning(winner2, 2);
        fractionReward.sendWinning(winner3, 3);
        fractionReward.sendWinning(winner4, 4);
        fractionReward.sendWinning(winner5, 5);
    }

    function setProfilePicture (uint256 spTokenId) public {
        require(skeletoons.ownerOf(spTokenId) == msg.sender, "msg.sender bust be owner of token");
        profilePic[msg.sender] = spTokenId;
    }

    function getProfilePicture (address wallet) public view returns(uint256[] memory){
        return skeletoons.getSkeletoonProperties(profilePic[wallet]);
    }

    function getWalletProperties(address wallet) public view returns(uint256[] memory){
        uint256[] memory walletProperties = new uint256[](2);
        walletProperties[0] = walletFraction[wallet];
        walletProperties[1] = walletPoints[wallet];
        return walletProperties;
    }

    struct ActiveGameWallet {
        address wallet;
        uint256 fraction;
        uint256 points;
    }

    function getBatchWalletProperties(uint256 amount, uint256 offset) public view returns(ActiveGameWallet[] memory){
        require(offset + amount <= walletsInGame, "requesting wallet not in game.");
        ActiveGameWallet[] memory walletProperties = new ActiveGameWallet[](amount);
        uint256 i = 0;
        for (i = 0; i < amount; i++){
            walletProperties[i] = ActiveGameWallet(
                walletIndex[offset+i],
                walletFraction[walletIndex[offset+i]],
                walletPoints[walletIndex[offset+i]]
            );
        }
        return walletProperties;    
    }


}