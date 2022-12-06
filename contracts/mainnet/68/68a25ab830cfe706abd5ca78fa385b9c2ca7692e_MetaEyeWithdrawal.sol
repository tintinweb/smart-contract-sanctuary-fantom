/**
 *Submitted for verification at FtmScan.com on 2022-12-06
*/

/**
 *Submitted for verification at FtmScan.com on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




contract MetaEyeWithdrawal is Ownable,Pausable{
    using SafeMath for uint256; 
    IERC20 public Token;
    address public Multisender;

    bool private _paused;

    constructor ()
    {
        Token = IERC20(0x3247169137F7B7322D66DCF4D7Ee7BDC096904A9);
        Multisender = 0x0F3999fea4c76a135a344406f0Da7bc41F6d86B5;
    }

    modifier onlyMultiSender(){
        require(Multisender == _msgSender(), "Multisender: caller is not the Multisender");
        _;
    }


    function pauseContract() public onlyOwner{
        _pause();

    }
    function unpauseContract() public onlyOwner{
        _unpause();

    }
     
    function register(address _address)public pure returns(address){
        return _address;
    }
    
    function multisendToken(address[] memory _contributors, uint256[] memory __balances)
    public
    onlyMultiSender
    {
        for (uint256 i; i<_contributors.length; i++){
            Token.transfer(_contributors[i], __balances[i]);
        }
    }

    event FTMtransfer(address user,uint256 FTMamount);
   
    function multiSendFTM(address payable[]  memory  _contributors, uint256[] memory __balances)
    public
    onlyMultiSender
    {

        for (uint256 i; i<_contributors.length; i++) {
            require(_contributors.length==__balances.length);
            payable(_contributors[i]).transfer(__balances[i]);
            emit FTMtransfer(_contributors[i],__balances[i]);
        }
    }


    function buy() external payable whenNotPaused{
        require(msg.value>0,"Select amount first");
    }
    

    function sell(uint256 _token) external payable whenNotPaused{
        Token.transferFrom(msg.sender,address(this),_token);
    }


    function updateMultisenderAccount(address Multisender_) public onlyOwner{
        Multisender = Multisender_;
    }

    function updateTokenAddress(address tokenAddress) public onlyOwner{
        Token = IERC20(tokenAddress);
    }
    
    
    function ClaimBNB(uint256 _amount) public onlyOwner{
        payable(msg.sender).transfer(_amount);
    }

    
    function claimToken(address tokenAddress,uint256 _amount) public onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender,_amount);
    }

}