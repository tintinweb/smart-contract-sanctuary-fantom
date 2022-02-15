/**
 *Submitted for verification at FtmScan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.12;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;



interface IStrategy {
    
    function wantLockedTotal() external view returns (uint256);
    function sharesTotal() external view returns (uint256);
    function getTotalValueLocked() external view returns (uint256);
}

interface IMainStaking {

    function addStrategy(address _strat, uint256 _allocPoint, bool _noWithdraw) external;
    function setStrategyAllocs(uint256 _stratId, uint256 _allocPoint) external;
    function setStrategyNoWithdraw(uint256 _stratId, bool _noWithdraw) external;
    function strategyReinvestAll() external;
    function strategyReinvest(uint256 _stratId) external;
    function strategyReinvestToAnotherStrategy(uint256 _stratIdFrom, uint256 _stratIdTo, uint256 _amountInBUSD) external;
    function setUniRouterAddress(uint256 _stableID, address _uniRouterAddress) external;
    function setPathTokenToBUSD(uint256 _stableID, address[] memory _pathTokenToBUSD) external;
    function setStartBlock(uint256 _startBlock) external;
    function setLaunchTimestamp(uint256 _launchTimestamp) external;
    function setRewardPerBlock(uint256 _rewardPerBlock) external;
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;

    function transferOwnership(address _newOwner) external;

    function strategies(uint256 _index) external returns(uint256 allocPoints, bool noWithdraw, address strat);
    function BUSD() external returns(address busd);
    function NATIVE() external returns(address native);
}

contract MainStakingContractFTMWrap is Ownable {

    IMainStaking public mainStaking;
    address public gov;
    
    constructor(IMainStaking _mainStaking) public {
        mainStaking = _mainStaking;
        gov = msg.sender;
    }
    
    modifier onlyGov() {
        require(gov == _msgSender(), "Gov: caller is not the gov");
        _;
    }


    /** GOV */

    function setGov(address _address) public onlyGov {
        gov = _address;
    }

    function addStrategy(address _strat, uint256 _allocPoint, bool _noWithdraw) public onlyGov {
        require(_allocPoint == 0, "can't create strategy with alloc points");
        mainStaking.addStrategy(_strat, _allocPoint, _noWithdraw);
    }
    
    function setStrategyNoWithdraw(uint256 _stratId, bool _noWithdraw) public onlyGov {
        (, bool noWithdraw, address strat) = mainStaking.strategies(_stratId);
        require(IStrategy(strat).getTotalValueLocked() < 10e18 || noWithdraw == true, "wrong noWithdraw");
        mainStaking.setStrategyNoWithdraw(_stratId, _noWithdraw);
    }
    
    function setUniRouterAddress(uint256 _stableID, address _uniRouterAddress) public onlyGov {
        mainStaking.setUniRouterAddress(_stableID, _uniRouterAddress);
    }
    
    function setPathTokenToBUSD(uint256 _stableID, address[] memory _pathTokenToBUSD) public onlyGov {
        require(address(_pathTokenToBUSD[_pathTokenToBUSD.length-1]) == address(mainStaking.BUSD()), "wrong path");
        mainStaking.setPathTokenToBUSD(_stableID, _pathTokenToBUSD);
    }
    
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyGov {
        mainStaking.setRewardPerBlock(_rewardPerBlock);
    }
    
    function inCaseTokensGetStuck(address _token, uint256 _amount) public onlyGov {
        require(address(_token) == address(mainStaking.NATIVE()), "token not native");
        mainStaking.inCaseTokensGetStuck(_token, _amount);
        IBEP20(mainStaking.NATIVE()).transfer(address(msg.sender), _amount);
    }


    /** OWNER */

    function setStrategyAllocsAndReinvest(
        uint256 _stratId, 
        uint256 _allocPoint, 
        uint256 _stratIdFrom, 
        uint256 _stratIdTo, 
        uint256 _amountInBUSD
    ) public onlyOwner {
        mainStaking.setStrategyAllocs(_stratId, _allocPoint);
        strategyReinvestToAnotherStrategy(_stratIdFrom, _stratIdTo, _amountInBUSD);
    }

    function setStrategyAllocsAndReinvestAll(
        uint256 _stratId, 
        uint256 _allocPoint, 
        uint256 _stratIdFrom,
        uint256 _stratIdTo
    ) public onlyOwner {
        mainStaking.setStrategyAllocs(_stratId, _allocPoint);        
        strategyReinvestAllToAnotherStrategy(_stratIdFrom, _stratIdTo);
    }
    
    function setStrategyAllocs(uint256 _stratId, uint256 _allocPoint) public onlyOwner {
        mainStaking.setStrategyAllocs(_stratId, _allocPoint);
    }
    
    function strategyReinvestToAnotherStrategy(uint256 _stratIdFrom, uint256 _stratIdTo, uint256 _amountInBUSD) public onlyOwner {
        mainStaking.strategyReinvestToAnotherStrategy(_stratIdFrom, _stratIdTo, _amountInBUSD);
    }
    
    function strategyReinvestAllToAnotherStrategy(uint256 _stratIdFrom, uint256 _stratIdTo) public onlyOwner {
        (, , address strat) = mainStaking.strategies(_stratIdFrom);
        uint256 _amountInBUSD = IStrategy(strat).getTotalValueLocked();
        mainStaking.strategyReinvestToAnotherStrategy(_stratIdFrom, _stratIdTo, _amountInBUSD);
    }
}