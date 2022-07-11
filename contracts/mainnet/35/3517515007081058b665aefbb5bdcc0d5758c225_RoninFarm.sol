/**
 *Submitted for verification at FtmScan.com on 2022-07-11
*/

pragma solidity 0.6.12;
//SPDX-License-Identifier: UNLICENSED

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
		uint256 allocPoint;       // How many allocation points assigned to this pool. RONINs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that RONINs distribution occurs.
        uint256 accRoninPerShare;   // Accumulated RONINs per share, times 1e18. See below.
		uint256 entry;
		uint256 exit;
    }

    // The RONIN TOKEN! Currency of this farm.
    address public ronin;
	uint256 private roninDeposits;
    // Dev address.
    address public devaddr;
    // RONIN tokens rewarded per block.
    uint256 public roninPerBlock;
    // Bonus muliplier for early ronin makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RONIN rewards start.
    uint256 public startBlock;
	
	uint256 maxEntryFee = 5;
	uint256 maxExitFee = 5;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
		require(multiplierNumber > 0, "Multiplier must be greater than 0.");
        BONUS_MULTIPLIER = multiplierNumber;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
	function farmableRonin() public view returns (uint256 farmable) {
        return IBEP20(ronin).balanceOf(address(this)).sub(roninDeposits);
    }
    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, IBEP20 _lpToken, uint256 entryFee, uint256 exitFee, bool _withUpdate) public onlyOwner {
		require(entryFee < maxEntryFee, "Entry fee too high");
		require(exitFee < maxExitFee, "Entry fee too high");
        if (_withUpdate) {
            massUpdatePools();
        }
		
		if(poolInfo.length > 0)
			for(uint8 i = 0; i < poolInfo.length; i++)
				require(poolInfo[i].lpToken != _lpToken, "Pool already added.");
				
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRoninPerShare: 0,
			entry: entryFee,
			exit: exitFee
        }));
    }
    // Update the given pool's RONIN allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 entryFee, uint256 exitFee, bool _withUpdate) public onlyOwner {
		require(entryFee < maxEntryFee, "Entry fee too high");
		require(exitFee < maxExitFee, "Entry fee too high");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
		poolInfo[_pid].entry = entryFee;
		poolInfo[_pid].exit = exitFee;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }
    function updateRoninPerBlock(uint256 _roninPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
		roninPerBlock = _roninPerBlock;
    }
    function outOfFarmables() private {
		roninPerBlock = 0;
    }
	function calcRoninPerDay() public view returns (uint256 roninPerDay) {
		roninPerDay = roninPerBlock.mul(24).mul(60).mul(60).mul(BONUS_MULTIPLIER).div(3);
		return roninPerDay;
	}
	function getPoolFees(uint256 _pid) public view returns (uint256 _entryFee, uint256 _exitFee) {
		return (poolInfo[_pid].entry, poolInfo[_pid].exit);
	}
	function getPoolPercent(uint256 _pid) public view returns (uint256 poolAlloc, uint256 totalAlloc) {
		return (poolInfo[_pid].allocPoint, totalAllocPoint);
	}

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    // View function to see pending RONIN on frontend.
    function pendingRonin(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRoninPerShare = pool.accRoninPerShare;
		
		uint256 lpSupply;
		if(address(pool.lpToken) == ronin)
			lpSupply = roninDeposits;
		else
			lpSupply = pool.lpToken.balanceOf(address(this));
		
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 roninReward = multiplier.mul(roninPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRoninPerShare = accRoninPerShare.add(roninReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accRoninPerShare).div(1e18).sub(user.rewardDebt);
    }
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
		
		uint256 lpSupply;
		if(address(pool.lpToken) == ronin)
			lpSupply = roninDeposits;
		else
			lpSupply = pool.lpToken.balanceOf(address(this));
		
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 roninReward = multiplier.mul(roninPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRoninPerShare = pool.accRoninPerShare.add(roninReward.mul(1e18).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Farm for RONIN allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRoninPerShare).div(1e18).sub(user.rewardDebt);
			if(pending >= farmableRonin()){
				pending = farmableRonin();
				outOfFarmables();
			}
            if(pending > 0) {
                safeRoninTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
			uint256 fee;
			if(pool.entry > 0)
				fee = (_amount.mul(pool.entry)).div(100);
			_amount = _amount.sub(fee);
			
            user.amount = user.amount.add( _amount );
			if(pool.lpToken == IBEP20(ronin))
				roninDeposits = roninDeposits.add( _amount );
			
            pool.lpToken.safeTransferFrom( address(msg.sender), address(this), _amount );
			
			if(pool.entry > 0)
				pool.lpToken.safeTransferFrom( address(msg.sender), devaddr, fee );
        }
			
        user.rewardDebt = user.amount.mul(pool.accRoninPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
		uint256 xfAmt = _amount;
		if(xfAmt > user.amount)
			xfAmt = user.amount;
			
        require(user.amount >= xfAmt, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRoninPerShare).div(1e18).sub(user.rewardDebt);
		if(pending >= farmableRonin()){
			pending = farmableRonin();
			outOfFarmables();
		}
		if(pending > 0) {
			safeRoninTransfer(msg.sender, pending);
		}
        if(xfAmt > 0) {
			uint256 fee;
			if(pool.exit > 0)
				fee = (xfAmt.mul(pool.exit)).div(100);
			if(pool.lpToken == IBEP20(ronin))
				roninDeposits = roninDeposits.sub(xfAmt);
			user.amount = user.amount.sub(xfAmt);
			
			xfAmt = xfAmt.sub(fee);
			pool.lpToken.safeTransfer(address(msg.sender), xfAmt );
			
			if(pool.exit > 0)
				pool.lpToken.safeTransfer(address(devaddr), fee );
        }
		
        user.rewardDebt = user.amount.mul(pool.accRoninPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, xfAmt);
    }

    // Safe ronin transfer function, just in case if rounding error causes pool to not have enough RONINs.
    function safeRoninTransfer(address _to, uint256 _amount) internal {
        IBEP20(ronin).safeTransfer(_to, _amount);
    }
	
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}

contract RoninFarm is Farm {
    constructor( address _ronin, uint256 _roninPerBlock ) public {
        ronin = _ronin;
        devaddr = msg.sender;
		roninPerBlock = _roninPerBlock;
    }
}