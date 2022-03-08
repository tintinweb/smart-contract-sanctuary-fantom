// Earth Rocket
// Welcome to Earth Rocket. Attempt to save the world and earn yourself some juicy rewards.
// SPDX-License-Identifier: MIT

// https://www.earthrocketgame.com
/*
 ```..........`:/:-.`
.:///////////////////-`
  .-//////////////++++/.      /-
    .:////////////++++++:-`   -+/-. `
     `:////+++++++++++oooo+///+++++/+/-.`
      .///++++oooooosssossso++++oooooo+++-`-.
      .+/+++++oooosssyyyyyyoo+ooo+oosssooo//`
      .++++++++osssssyyhhhyoo+ossoooosyhyo+/-
      `:+ooo++++syyyyyydddyooossssooosyhdh+/+:.`
   `---://+ssso+yhyyyyhdmdsooosyyyosoohdddo+o++/-.
     `.:/+osyyyosddhyydmmdsssssyhhyhyshdmhshd+++++-
       `://oyyyy+hmmhyhhhyssssyhhhhdhshmmmmmd+ooooo:
         :///+++/+ymmddNNdssssshdddddyhmmmmmoosysooo`
          ://+oso+ooydNMMmyyyyyddddddhhmNNNmysshdhss+
          .////osooososhdhyyhddddmmmdysshmNNdhyhmmhs+
          .////syysssssyyyyyyhdmmmdo:-.-:///oydhmNhy.
           :///syyyhhhhyyhhhhhhmhd+-:///:--...+hmmho
         .`.//+osyhhhhddhhdddddmh+:oo:-:::--..-/shs.
         .:-:+++syyhdddddhdmmmdmm+y+/////::///::---       ````
          `:/+++++oshdddmddmmmmmdyo/+o+/+so++//:-..   ``````````````````
            ``.:/++osydmmmhdmNNNmh++o+oyyyyso+/-.`````....----.....`` ````
              ```-/oosymmmmdhdmNNmhooyhydmdyo:.`....-----......:::-:.`  `````
              --:/++oosymmmmmmddmmmdhyyhdmh/...---::--:/:-.-...:::--.```` ```.`
                  `-:oooshmNNNNNNNNNdysyy+-.--://+o++//:--.-.--:--:-.`.````.`.-
                      .:ossyhdddddhhs/-/-.-::/+oossoooso+/:--`.:/--.--.`  `-`/+.`   ```
                         `-:::::::.`    .-/+osso+soo+++/:....-/+++/:...``.-.+o:``    ````   `
                                      `-:/ossso///s//:/:-:....-:sdyo-/soshho:./.    ``````` ``
                                      .://ooos++/sh:ohddo-..--//so/+-smmmmy/:+.`   ` `-...```
                                     .:/+osssoyys:sodmhs--/+/-/+o+/:+sdmmy--+:``  ```.+//:`````
                                    .:++ysyyyyhy/-:omNmy:---+:..-.--/odmo:.````   ``..-://....``
                                   `:/ssyosoyhhdy/yhmds+/::----...--+ymy+:.``.`.``````.`.-:-.-.``
                                   -//+os/ohhooshhysssss/://::----:+/oyo:.   ``..``.```-////-:-```
                                  `:+++os+shdy/:++hyshh+:-/+:://::/y/-s/`     ```````../+ooo/++-``
                                  ./o+sso+oydy+++/hmmms//o/+/////+o/::/`   ``:::+:--`.://o+ysso.```
                                  -o++yo/:/+ysyyyydmy/:+++++ossssss+++:```. .omdydh::+:o++oyyy+.```
                                  -o/+s/--::+yhdhhdy+`-:/ossyNmysoosys+:.`--/sdy::/oy::/+syys/..```
                                  `:-+/..-/sosooosyhs:.+yhydMmds:--:oso+:::oo--``--..:/++sho/-....`
                                  `.-o-..-:/ymmhydyyhsooymmyhmhooo+/:---...:/``.`..-+oo//shso/:::-`
                                   .-+-.---.sdmdddddhyyhhhhyyyssssso/-..`` ````` :ooo/:+yyy/++///-
                                   `..-.::/-/shdhyosyyhdhhhdddhhsoo+o+/.--``-/::+s/--oyyhhhhhys+:`
                                    ..-://:///oshhhhhdmmy//++s+//o+::-...:``ohho/--/ssyyhdhysoo/.
                                     .--/s:::+oysoshhdNdy:.`.---.--:/.`...-/oy+:so+//syoyhyyso/.
                                     `.--::---::/:--:omo/:.``.:++:+::-:+:-/-:++:so+oosoooo+sso:
                                      `.-----:-----.--::..``-+:-../-+ys--+/:+:-/osysooo+//ss+:`
                                        .-:-.-------.---..::/-/+/oy:s/.:/o--/-:-/syhso+//+/:.
                                         `:+/--:-///------::/osy/++::.-::-./:-::oyhs+/::::-`
                                           .:++oyhdysso/:::-::::-::::-:---.--/+o+so/:::/:.
                                             ./oyhhys/:---..---:/::::.--:::://+o+///+//.`
                                               `.-//::::::-::---:-----:://:-:+++++o+:`
                                                  `-:///::--------::-:::///:/:-::-.
                                                      .-:+oo++oo/////oshys/::..`
                                                            `..--::---..``

*/
pragma solidity ^0.7.6;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // Silence state mutability warning without creating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the total amount of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens owned by an account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    // Admin address is given limited ownership power to handle game rewards once full ownership has been renounced
    address payable private _adminAddress = 0x882193F4604E13a4a6329cC3755df8F424Ab6C2F;
    address payable private _champAddress = 0xB61016d1Dcf112CB939Cb759135e779717b14601;
    address payable private _teamAddress = 0xe58f113E7b8c458ed5444a369D70B9A554F80921;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin user.
     */
    modifier onlyAdmin() {
        require(_adminAddress == _msgSender() || _owner == _msgSender(), "Ownable: caller is not the admin user");
        _;
    }

    function admin() public view returns (address) {
        return _adminAddress;
    }

    function champ() public view returns (address) {
        return _champAddress;
    }

    function team() public view returns (address) {
        return _teamAddress;
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
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers admin usership of the contract to a new account (`newAdmin`).
     * Can only be called by the current owner or admin user.
     */
    function transferAdmin(address payable newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Ownable: new admin user is the zero address");
        _adminAddress = newAdmin;
    }

    function transferChamp(address payable newChamp) public virtual onlyAdmin {
        require(newChamp != address(0), "Ownable: new champ user is the zero address");
        _champAddress = newChamp;
    }

    function transferTeam(address payable newTeam) public virtual onlyAdmin {
        require(newTeam != address(0), "Ownable: new team user is the zero address");
        _teamAddress = newTeam;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
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
        require(c >= a, "SafeMath: addition overflow.");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow.");
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


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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


contract ERGT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tAdminFeeTotal;
    uint256 private _tChampFeeTotal;
    uint256 private _tTeamFeeTotal;

    string private _name = 'Earth Rocket Game Token';
    string private _symbol = 'ERGT';
    uint8 private _decimals = 9;

    uint256 private _taxFee = 5;    // Reflection pool % gained per transaction
    uint256 private _champFee = 2;  // % of every transaction rewarded to the champion
    uint256 private _teamFee = 1;  // % of every transaction for dev and marketing team
    uint256 private _adminFee = 2;  // % of transaction to help replenish the rewards pool
    uint256 private _initialAdminPercentage = 40;  // % of transaction to help replenish the rewards pool
    uint256 private _initialTeamPercentage = 10;  // % of transaction to help replenish the rewards pool
    uint256 private _maxTxAmount = 50**7 * 10**9;
    bool private _rewardsActive = true;
    bool private _maxTxLimited = false;
    bool private _taxEnabled = false;

    struct TValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tAdminFee;
        uint256 tChampFee;
        uint256 tTeamFee;
    }

    struct RValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rAdminFee;
        uint256 rChampFee;
        uint256 rTeamFee;
    }

    struct Values {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rAdminFee;
        uint256 rChampFee;
        uint256 rTeamFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tAdminFee;
        uint256 tChampFee;
        uint256 tTeamFee;
    }

    constructor ()  {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        _transfer(_msgSender(), admin(), _tTotal.mul(_initialAdminPercentage).div(100));
        _transfer(_msgSender(), team(), _tTotal.mul(_initialTeamPercentage).div(100));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalAdminFees() public view returns (uint256) {
        return _tAdminFeeTotal;
    }

    function totalChampFees() public view returns (uint256) {
        return _tChampFeeTotal;
    }

    function totalTeamFees() public view returns (uint256) {
        return _tTeamFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        Values memory vals_struct = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vals_struct.rAmount);
        _rTotal = _rTotal.sub(vals_struct.rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        Values memory vals_struct = _getValues(tAmount);
        if (!deductTransferFee) {
            return vals_struct.rAmount;
        } else {
            return vals_struct.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyAdmin() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyAdmin() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(_maxTxLimited && (sender != owner() && recipient != owner()))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        Values memory vals_struct = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vals_struct.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vals_struct.rTransferAmount);
        _reflectFee(vals_struct);
        emit Transfer(sender, recipient, vals_struct.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        Values memory vals_struct = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vals_struct.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vals_struct.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vals_struct.rTransferAmount);
        _reflectFee(vals_struct);
        emit Transfer(sender, recipient, vals_struct.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        Values memory vals_struct = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vals_struct.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vals_struct.rTransferAmount);
        _reflectFee(vals_struct);
        emit Transfer(sender, recipient, vals_struct.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        Values memory vals_struct = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(vals_struct.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(vals_struct.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(vals_struct.rTransferAmount);
        _reflectFee(vals_struct);
        emit Transfer(sender, recipient, vals_struct.tTransferAmount);
    }

    function _reflectFee(Values memory vals_struct) private {
        _rTotal = _rTotal.sub(vals_struct.rFee).sub(vals_struct.rAdminFee).sub(vals_struct.rChampFee).sub(vals_struct.rTeamFee);
        _tFeeTotal = _tFeeTotal.add(vals_struct.tFee);
        _tAdminFeeTotal = _tAdminFeeTotal.add(vals_struct.tAdminFee);
        _tChampFeeTotal = _tChampFeeTotal.add(vals_struct.tChampFee);
        _tTeamFeeTotal = _tTeamFeeTotal.add(vals_struct.tTeamFee);
        _rOwned[admin()].add(vals_struct.tAdminFee);
        _rOwned[champ()].add(vals_struct.tChampFee);
        _rOwned[team()].add(vals_struct.tTeamFee);
    }

    function _getValues(uint256 tAmount) private view returns (Values memory) {
        TValues memory tvals_struct = _getTValues(tAmount);
        RValues memory rvals_struct = _getRValues(tAmount, tvals_struct);
        Values memory vals_struct;

        vals_struct.rAmount = rvals_struct.rAmount;
        vals_struct.rTransferAmount = rvals_struct.rTransferAmount;
        vals_struct.rFee = rvals_struct.rFee;
        vals_struct.rAdminFee = rvals_struct.rAdminFee;
        vals_struct.rChampFee = rvals_struct.rChampFee;
        vals_struct.rTeamFee = rvals_struct.rTeamFee;
        vals_struct.tTransferAmount = tvals_struct.tTransferAmount;
        vals_struct.tFee = tvals_struct.tFee;
        vals_struct.tAdminFee = tvals_struct.tAdminFee;
        vals_struct.tChampFee = tvals_struct.tChampFee;
        vals_struct.tTeamFee = tvals_struct.tTeamFee;

        return vals_struct;
    }

    function _getTValues(uint256 tAmount) private view returns (TValues memory) {
        TValues memory tvals_struct;
        if(_taxEnabled){
            tvals_struct.tFee = tAmount.mul(_taxFee).div(100);
            tvals_struct.tAdminFee = tAmount.mul(_adminFee).div(100);
            tvals_struct.tChampFee = tAmount.mul(_champFee).div(100);
            tvals_struct.tTeamFee = tAmount.mul(_teamFee).div(100);
        }else{
            tvals_struct.tFee = 0;
            tvals_struct.tAdminFee = 0;
            tvals_struct.tChampFee = 0;
            tvals_struct.tTeamFee = 0;
        }
        tvals_struct.tTransferAmount = tAmount.sub(tvals_struct.tFee).sub(tvals_struct.tAdminFee).sub(tvals_struct.tChampFee).sub(tvals_struct.tTeamFee);  // Remaining tokens from the original transaction amount
        return tvals_struct;
    }

    function _getRValues(uint256 tAmount, TValues memory tvals_struct) private view returns (RValues memory) {
        RValues memory rvals_struct;
        uint256 currentRate =  _getRate();
        rvals_struct.rAmount = tAmount.mul(currentRate);

        if(_taxEnabled){
            rvals_struct.rFee = tvals_struct.tFee.mul(currentRate);
            rvals_struct.rAdminFee = tvals_struct.tAdminFee.mul(currentRate);
            rvals_struct.rChampFee = tvals_struct.tChampFee.mul(currentRate);
            rvals_struct.rTeamFee = tvals_struct.tTeamFee.mul(currentRate);
        }else{
            rvals_struct.rFee = 0;
            rvals_struct.rAdminFee = 0;
            rvals_struct.rChampFee = 0;
            rvals_struct.rTeamFee = 0;
        }
        rvals_struct.rTransferAmount = rvals_struct.rAmount.sub(rvals_struct.rFee).sub(rvals_struct.rAdminFee).sub(rvals_struct.rChampFee).sub(rvals_struct.rTeamFee);
        return rvals_struct;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getTaxFee() private view returns(uint256) {
        return _taxFee;
    }

    function _getAdminFee() private view returns(uint256) {
        return _adminFee;
    }

    function _getChampFee() private view returns(uint256) {
        return _champFee;
    }

    function _getTeamFee() private view returns(uint256) {
        return _teamFee;
    }

    function _getMaxTxAmount() private view returns(uint256) {
        return _maxTxAmount;
    }

    function _setTaxFee(uint256 taxFee) external onlyAdmin() {
        require(taxFee >= 1 && taxFee <= 10, 'taxFee should be in 1 - 10');
        _taxFee = taxFee;
    }


    function _getTaxEnabled() public view returns (bool) {
        return _taxEnabled;
    }

    function _setTaxEnabled(bool is_enabled) external onlyOwner() {
        _taxEnabled = is_enabled;
    }

    function _getMaxTxLimited() public view returns (bool) {
        return _maxTxLimited;
    }

    function _setMaxTxLimited(bool is_limited) external onlyOwner() {
        _maxTxLimited = is_limited;
    }

    function getRewardsActive() public view returns (bool) {
        return _rewardsActive;
    }

    function _setrewardsActive(bool activate) external onlyAdmin() {
        _rewardsActive = activate;
    }

    function processBatchRewards(address[] calldata addresses, uint256[] calldata tokenRewards) public onlyAdmin {
        require(addresses.length == tokenRewards.length , 'Invalid input. Arrays do not match in size.');
        require(getRewardsActive() , 'Rewards are currently disabled.');
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(admin(), addresses[i], tokenRewards[i] * 10**9);
        }
    }
}