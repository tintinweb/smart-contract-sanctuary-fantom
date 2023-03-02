// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Company is Ownable {
  using SafeMath for uint256; 

  uint256 public currentId;  

  struct employeeInfo {
    uint256 employeeId;
    string employeeName;
    string employeeRank;
    address payable employeeAddress;
    uint256 payment;
  }

  mapping(uint256 => employeeInfo) employee;
  uint256[] public employeeIds;

  event employeeCreated(string employeeName, string employeeRank, address employeeAddress, uint256 payment);
  event employeeInfoModified(string employeeName, string employeeRank, address employeeAddress, uint256 payment);
  event employeesPaid(string companyName, uint256 payment);
  
  uint256 public id;
  string public name;
  address public companyOwner;

  constructor(
    uint256 _id,
    string memory _name,
    address _owner
  )
  {
    id = _id;
    name = _name;
    companyOwner = _owner;
  }

  // add an employee
  function registerEmployee(string memory _employeeName, string memory _employeeRank , address payable _employeeAddress, uint256 _payment ) public {
      require(msg.sender == companyOwner, "only the owner can call this function");
      employeeInfo storage newEmployee = employee[currentId];
      newEmployee.employeeId = currentId;
      newEmployee.employeeName = _employeeName;
      newEmployee.employeeRank = _employeeRank;
      newEmployee.employeeAddress = _employeeAddress;
      newEmployee.payment = _payment;
      employeeIds.push(currentId);
      currentId += 1;
      emit employeeCreated(_employeeName, _employeeRank, _employeeAddress, _payment);
  }

  //Edit employee
  function editEmployee(string memory _employeeName, string memory _employeeRank , address payable _employeeAddress, uint256 _payment, uint256 _id ) public {
      require(msg.sender == companyOwner, "only the owner can call this function");
      employeeInfo storage modifyEmployee = employee[_id];
      modifyEmployee.employeeName = _employeeName;
      modifyEmployee.employeeRank = _employeeRank;
      modifyEmployee.employeeAddress = _employeeAddress;
      modifyEmployee.payment = _payment;
      emit employeeInfoModified(_employeeName, _employeeRank, _employeeAddress, _payment);
  }

  //query all employess
  function getAllEmployee() public view returns (string[] memory employeeNames, string[] memory employeeRanks, address[] memory employeeAddresses, uint256[] memory payments, uint256[] memory ids){
    uint256 count = currentId;
    employeeNames = new string[](count);
    employeeRanks = new string[](count);
    employeeAddresses = new address[](count);
    payments = new uint256[](count);
    ids = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      employeeInfo storage allEmployee = employee[i];
      employeeNames[i] = allEmployee.employeeName;
      employeeRanks[i] = allEmployee.employeeRank;
      employeeAddresses[i] = allEmployee.employeeAddress;
      payments[i] = allEmployee.payment;
      ids[i] = allEmployee.employeeId;
    }

    return (employeeNames, employeeRanks, employeeAddresses, payments, ids);
  }

  // pay employees
  function payEmployee() public payable {
      require(msg.sender == companyOwner, "only the owner can call this function");
      uint256 count = currentId;

      for (uint256 i = 0; i < count; i++) {
        employeeInfo storage allEmployee = employee[i]; 
        address payable employeeAddress = allEmployee.employeeAddress;
        uint256 amount = allEmployee.payment;
        employeeAddress.transfer(amount);
      }

      emit employeesPaid(name, msg.value);
  }
   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Company.sol";

contract CompanyFactory {
  Company[] private _companies;

  event CompanyCreated(Company indexed company, address indexed owner);

  uint256 constant maxLimit = 20;

  uint256 public currentId;

  function createCompany(
    string memory name
  )
  public
  {
    Company company = new Company(
      currentId,
      name,
      msg.sender
    );
    _companies.push(company);
    currentId += 1;
    emit CompanyCreated(company, msg.sender);
  }

  // Query the number of companied in our smart contract
  function companiesCount() public view returns(uint256) {
    return _companies.length;
  }

  // Query all companies in our smart contract
  function companies() 
    public 
    view
    returns(Company[] memory)
  {
    return  _companies;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}