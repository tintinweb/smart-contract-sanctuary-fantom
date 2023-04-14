/**
 *Submitted for verification at FtmScan.com on 2023-04-14
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/lib/Ownable.sol

pragma solidity ^0.8.0;

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


// File contracts/periphery/PearlsReferrals.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISocialChef {
    function updateShare(uint256 _pid, address _account) external;
}

contract PearlsReferralStorage is Ownable {

    mapping (address => bool) public isHandler;

    ISocialChef public socialChef;

    mapping (bytes32 => address) public codeOwners;
    mapping (address => bytes32) public pearlProtectorReferralCodes;
    uint256 public totalReferralPoints = 0;
    mapping (address => uint256) public pointsTracked;
    uint256 public totalReferralPointsLP = 0;
    mapping (address => uint256) public pointsTrackedLP;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);
    event userIncreased(address referrer, address referral, uint256 amount);
    event totalIncreased(uint256 amount);
    event userDecreased(address referrer, address referral, uint256 amount);
    event totalDecreased(uint256 amount);
    event userIncreasedLP(address referrer, address referral, uint256 amount);
    event totalIncreasedLP(uint256 amount);
    event userDecreasedLP(address referrer, address referral, uint256 amount);
    event totalDecreasedLP(uint256 amount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "PearlsReferralStorage: forbidden");
        _;
    }

    constructor (ISocialChef _socialChef) {
        socialChef = _socialChef;
    }

    function setSocialChef(ISocialChef _newSocialChef) external onlyOwner {
        socialChef = _newSocialChef;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    //UI
    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "PearlsReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "PearlsReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external onlyOwner {
        require(_code != bytes32(0), "PearlsReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function govSetTraderReferralCode(address _account, bytes32 _code) external onlyOwner {
        pearlProtectorReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }

    function getTraderReferralInfo(address _account) public view returns (bytes32, address) {
        bytes32 code = pearlProtectorReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        if(pearlProtectorReferralCodes[_account] != bytes32(0) || codeOwners[_code] == _account){
            // do nothing
        }else{
            pearlProtectorReferralCodes[_account] = _code;
            emit SetTraderReferralCode(_account, _code);
        }
    }
    
    function trackAddPoints(address _referral, uint256 _points) external onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            pointsTracked[referrer] += _points;
            if(address(socialChef) != address(0)){
                socialChef.updateShare(0, referrer);
            }
            totalReferralPoints += _points;
            emit userIncreased(referrer, _referral, _points);
            emit totalIncreased(_points);
        }
    }

    function trackAddPointsLP(address _referral, uint256 _points) external onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            pointsTrackedLP[referrer] += _points;
            if(address(socialChef) != address(0)){
                socialChef.updateShare(1, referrer);
            }
            totalReferralPointsLP += _points;
            emit userIncreasedLP(referrer, _referral, _points);
            emit totalIncreasedLP(_points);
        }
    }

    function trackSubPointsLP(address _referral, uint256 _points) external onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            if(_points >= pointsTrackedLP[referrer]){
                pointsTrackedLP[referrer] = 0;
                emit userDecreasedLP(referrer, _referral, pointsTrackedLP[referrer]);
            }else{
                pointsTrackedLP[referrer] -= _points;
                emit userDecreasedLP(referrer, _referral, _points);
            }

            if(address(socialChef) != address(0)){
                socialChef.updateShare(1, referrer);
            }

            if(_points >= totalReferralPointsLP){
                totalReferralPointsLP = 0;
                emit totalDecreasedLP(totalReferralPoints);
            }else{
                totalReferralPoints -= _points;
                emit totalDecreasedLP(_points);
            }
        }
    }

    function trackSubPoints(address _referral, uint256 _points) external onlyHandler {
        (, address referrer) = getTraderReferralInfo(_referral);
        if(referrer == address(0)){
            // do nothing
        }else{
            if(_points >= pointsTracked[referrer]){
                pointsTracked[referrer] = 0;
                emit userDecreased(referrer, _referral, pointsTracked[referrer]);
            }else{
                pointsTracked[referrer] -= _points;
                emit userDecreased(referrer, _referral, _points);
            }

            if(address(socialChef) != address(0)){
                socialChef.updateShare(0, referrer);
            }

            if(_points >= totalReferralPoints){
                totalReferralPoints = 0;
                emit totalDecreased(totalReferralPoints);
            }else{
                totalReferralPoints -= _points;
                emit totalDecreased(_points);
            }

        }
    }
}