// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

contract LockToken{
    using SafeERC20 for IERC20;
    
   
    // ERC20 basic token contract being held
    IERC20 private immutable _token;
    
     uint256 private immutable _numDays;
    //records the start of the contract 
    uint256 private immutable _start;
 
    // beneficiary of tokens after they are released
    address private immutable _beneficiary;
    
    constructor(IERC20 token_, address beneficiary_, uint256 numDays_) {
        _token = token_;
        _beneficiary = beneficiary_;
        _start = block.timestamp;
        _numDays = numDays_;
    }
    
    /**
     * @return block.timestamp (used for testing).
     */
    function _blocktime() private view returns (uint256){
        return block.timestamp;
    }
    
    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }
    
    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }
    
    /**
     * @return number of tokens still locked up
     */
    function locked() public view returns(uint256){
        return token().balanceOf(address(this));
    }
    
    /**
     * @return number of days left until the token can be released
     */
    function daysUntilRelease() public view returns (uint256){
        uint256 end = _start+_numDays*(1 days);
        if(_blocktime()>=end) return 0;
        uint256 daysLeft = (end-_blocktime())/(1 days);
        return daysLeft;
    }
    
     /**
     * Releases the locked tokens to the benificiary
     */
    function release() public {
        require(locked()>0 && daysUntilRelease()==0);
        token().safeTransfer(beneficiary(),locked());
    }

}