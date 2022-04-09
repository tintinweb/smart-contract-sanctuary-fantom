/**
 *Submitted for verification at FtmScan.com on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

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

interface ISummoner {
    function poolLength() external view returns (uint length);
    
    function pendingSoul( uint pid, address _user ) external view returns (uint pendingAmount);

    function userInfo( uint pid, address user ) external view 
        returns ( uint amount, uint rewardDebt, uint rewardDebtAtTime, uint lastWithdrawTime,
            uint firstDepositTime, uint timeDelta, uint lastDepositTime );
    
    function poolInfo( uint pid ) external view 
        returns ( address lpToken, uint allocPoint, uint lastRewardTime, uint accSoulPerShare );
}

/// @title SummonerHelper.sol
/// @author 0xBuns (https://twitter.com/0xBuns)
/// @notice Summoner helper is used to view key aspects of any farm for SoulSwap Finance.

contract SummonerHelper is Ownable {
    using SafeERC20 for IERC20;

    uint[] public Inactive;
    ISummoner public SummonerContract = ISummoner(0xce6ccbB1EdAD497B4d53d829DF491aF70065AB5B);

    /* ======= FARM HANDLERS ======= */

    function allocationPoints(uint pid) public view returns (uint points) {
        (,points,,) = SummonerContract.poolInfo( pid );
    }

    function poolLength() public view returns (uint length) {
        length = SummonerContract.poolLength();
    }

    function getInactivePools() public view returns (uint[] memory pools) {
        pools =  Inactive;
    }

    /* ======= USER DETAILS ======= */

    function getUserPayout(uint pid, address account) public view returns (uint payout) {
        payout = SummonerContract.pendingSoul( pid, account );
    }

    function getUserBalance(uint pid, address account) public view returns (uint balance) {
            (balance,,,,,,) = SummonerContract.userInfo(pid, account);
    }

    function getUserInfo(uint pid, address account) public view returns (
        uint amount, uint rewardDebt, uint rewardDebtAtTime, uint lastWithdrawTime,
        uint firstDepositTime, uint timeDelta, uint lastDepositTime) {
             (amount,,,,,,) = SummonerContract.userInfo(pid, account);
             (,rewardDebt,,,,,) = SummonerContract.userInfo(pid, account);
             (,,rewardDebtAtTime,,,,) = SummonerContract.userInfo(pid, account);
             (,,,lastWithdrawTime,,,) = SummonerContract.userInfo(pid, account);
             (,,,,firstDepositTime,,) = SummonerContract.userInfo(pid, account);
             (,,,,,timeDelta,) = SummonerContract.userInfo(pid, account);
             (,,,,,,lastDepositTime) = SummonerContract.userInfo(pid, account);
    }
 
    function userInfo(uint pid) public view returns (
        uint amount, uint rewardDebt, uint rewardDebtAtTime, uint lastWithdrawTime,
        uint firstDepositTime, uint timeDelta, uint lastDepositTime) {
             (amount,,,,,,) = SummonerContract.userInfo(pid, msg.sender);
             (,rewardDebt,,,,,) = SummonerContract.userInfo(pid, msg.sender);
             (,,rewardDebtAtTime,,,,) = SummonerContract.userInfo(pid, msg.sender);
             (,,,lastWithdrawTime,,,) = SummonerContract.userInfo(pid, msg.sender);
             (,,,,firstDepositTime,,) = SummonerContract.userInfo(pid, msg.sender);
             (,,,,,timeDelta,) = SummonerContract.userInfo(pid, msg.sender);
             (,,,,,,lastDepositTime) = SummonerContract.userInfo(pid, msg.sender);
    }

    // Update Inactive Pools //

    function updateInactivePools() public {
        for( uint pid = 0; pid < poolLength(); pid++ ) {
            if ( allocationPoints(pid) == 0 ) {
                    Inactive.push(pid);
                }
            }
    }

    /* ======= AUXILLIARY ======= */
    function recoverLostToken( address _token ) external returns ( bool ) {
        IERC20( _token ).safeTransfer( _owner, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}