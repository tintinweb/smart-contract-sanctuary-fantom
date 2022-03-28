/**
 *Submitted for verification at FtmScan.com on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface ILuxorStaking {
    function warmupInfo(address user) external view returns (uint deposit, uint gons, uint expiry, bool lock);
    function epoch() external view returns (uint number, uint distribute, uint32 length, uint32 endTime);
    function warmupPeriod() external view returns (uint period);
}

/// @title StakeHelper.sol
/// @author 0xBuns (https://twitter.com/0xBuns)
/// @notice Stake helper is used to view key aspects of staking Luxor DAO.

contract StakeHelper is Ownable {
    using SafeERC20 for IERC20;
    address public LuxorStakingAddress = 0xf3F0BCFd430085e198466cdCA4Db8C2Af47f0802;
    address public LuxorWarmupAddress = 0x2B6Fe815F3D0b8C13E8F908A2501cdDC23D4Ed48;
    IERC20 public LUX = IERC20(0x6671E20b83Ba463F270c8c75dAe57e3Cc246cB2b);

    /* ======= STAKE HANDLERS ======= */
    function updateStaking( address _staking ) public onlyPolicy() {
        require( LuxorStakingAddress != _staking, "already exists" );
        LuxorStakingAddress = _staking;
    }

    /* ======= STAKING CONRTRACT DETAILS ======= */
    
    function nextRebase() public view returns ( uint32 endTime ) { 
        ( ,,,endTime ) = ILuxorStaking( LuxorStakingAddress ).epoch();
    }
    
    function epoch() public view returns ( uint number ) { 
        ( number,,, ) = ILuxorStaking( LuxorStakingAddress ).epoch();
    }

    function epochLength() public view returns ( uint length ) { 
        ( ,,length, ) = ILuxorStaking( LuxorStakingAddress ).epoch();
    }

    function distribute() public view returns ( uint amount ) { 
        ( ,amount,, ) = ILuxorStaking( LuxorStakingAddress ).epoch();
    }

    function warmupPeriod() public view returns ( uint period ) { 
        period = ILuxorStaking( LuxorStakingAddress ).warmupPeriod();
    }

    /* ======= USER (QUERY) DETAILS ======= */

    function warmupInfo( address userAddress ) public view returns (
        uint deposit, uint gons, uint expiry, bool lock) {
            
            (deposit,,,) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
            (,gons,,) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
            (,,expiry,) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
            (,,,lock) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
    }

    function warmupValue( address userAddress  ) external view returns (uint deposit) {
        (deposit,,,) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
    }

    function warmupExpiry( address userAddress ) external view returns (uint expiry) {
        (,,expiry,) = ILuxorStaking( LuxorStakingAddress ).warmupInfo(userAddress);
    }

    /* ======= AUXILLIARY ======= */
    function recoverLostToken( address _token ) external returns ( bool ) {
        IERC20( _token ).safeTransfer( _owner, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}