/**
 *Submitted for verification at FtmScan.com on 2023-02-27
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns(address);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
            ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external;
}

contract DaddyFarms {
    // DATA
        address private _operator;
        address private _feeReceiver;
        address private _devWallet;
        address private _daddy;
        address private _daddyLP;
        address private _router;
        mapping(address => bool) _auth;
        mapping(address => bool) _authRobot;

        uint256 public _depositFee;
        uint256 public _zapFee;
        uint256 public _marketFee;
        uint256 public _burnFee;

        uint256 private _lastEU;
        uint256 private _totalToDistribute;
        uint256 private _distRate;

        mapping(address => POOL) _pool;
            struct POOL {
                bool active;
                uint256 pendingTotal;
                uint256 userTotal;
                uint256 depositFee;
                uint256 emissions;
                uint256 totalToDistribute;

                address[] users;
                mapping(address => bool) isUser;
                mapping(address => uint256) uIndex;
                mapping(address => uint256) uDeposit;
                mapping(address => uint256) uPending;
            }

        constructor(address daddy, address router){
            _operator = msg.sender;
            _feeReceiver = msg.sender;
            _devWallet = msg.sender;
            _auth[msg.sender] = true;
            _daddy = daddy;
            _router = router;
            _daddyLP = _getPair();
        }

        receive() external payable {}

    // VIEW
        function getDaddy() public view returns(address){ return _daddy; }
        function getLP() public view returns(address){ return _daddyLP; }
        function getUserDeposit(address pool, address user) public view returns(uint256){ return _pool[pool].uDeposit[user]; }
        function getUserPending(address pool, address user) public view returns(uint256){ return _pool[pool].uPending[user]; }
        function getUserTotal(address pool) public view returns(uint256){ return _pool[pool].userTotal; }
        function getPendingDistribution(address pool) public view returns(uint256){ return _pool[pool].totalToDistribute; }
        function getEmissions(address pool) public view returns(uint256){ return _pool[pool].emissions; }

    // ACTIVE
        function zapETH() public payable open(_daddyLP) goodRobot {
            require(msg.value != 0, "Cannot zap the nothingness");
            uint256 zapValue = msg.value;
            if(_zapFee != 0){ 
                uint256 zFee = (zapValue * _zapFee) / 10000;
                zapValue -= zFee;
                _processFee(address(0), zFee);
            }
            uint256 eValue = zapValue / 2;
            uint256 tValue = _swapToken(eValue, false);
            uint256 zapRec = _addLiquidity(eValue, tValue);
            if(!_pool[_daddyLP].isUser[msg.sender]){ _modUser(msg.sender, _daddyLP, true); }
                _pool[_daddyLP].uDeposit[msg.sender] += zapRec;
                _pool[_daddyLP].userTotal += zapRec;
            _updateEmission();
            _tricycle(_daddyLP);
        }

        function zapToken(uint256 value) public open(_daddyLP) goodRobot {
            require(value != 0, "Cannot zap the nothingness");
            uint256 zapValue = _tokenIntake(_daddy, msg.sender, value);
            if(_zapFee != 0){
                uint256 zFee = (zapValue * _zapFee) / 10000;
                zapValue -= zFee;
                _processFee(_daddy, zFee);
            }
            uint256 tValue = zapValue / 2;
            uint256 eValue = _swapToken(tValue, true);
            uint256 zapRec = _addLiquidity(eValue, tValue);
            if(!_pool[_daddyLP].isUser[msg.sender]){ _modUser(msg.sender, _daddyLP, true); }
                _pool[_daddyLP].uDeposit[msg.sender] += zapRec;
                _pool[_daddyLP].userTotal += zapRec;
            _updateEmission();
            _tricycle(_daddyLP);
        }

        function removeLiquidity(uint256 value, bool getToken) public {
            uint256 lValue = _tokenIntake(_daddyLP, msg.sender, value);
            (uint256 rETH, uint256 rToken) = _removeLiquidity(lValue);
            if(getToken){
                uint256 rToken1 = _swapToken(rETH, false);
                IERC20(_daddy).transfer(msg.sender, rToken + rToken1);
            } else {
                IERC20(_daddy).transfer(msg.sender, rToken);
                (bool success,) = payable(msg.sender).call{ value: rETH }("");
                require(success, "User Denied Transfer");
            }
        }

        function deposit(address token, uint256 value) public open(token) goodRobot {
            require(value != 0, "Cannot deposit Nothing");
            uint256 depVal = _tokenIntake(token, msg.sender, value);
            if(_pool[token].depositFee != 0){ 
                uint256 dFee = (depVal * _pool[token].depositFee) / 10000;
                depVal -= dFee; 
                _processFee(token, dFee);
            }
            if(!_pool[token].isUser[msg.sender]){ _modUser(msg.sender, token, true); }
                _pool[token].uDeposit[msg.sender] += depVal;
                _pool[token].userTotal += depVal;
            _updateEmission();
            _tricycle(token);
        }

        function withdraw(address token, uint256 value) public {
            require(_pool[token].uDeposit[msg.sender] >= value);
                _pool[token].uDeposit[msg.sender] -= value;
                _pool[token].userTotal -= value;
            if(_pool[token].uDeposit[msg.sender] == 0){ _modUser(msg.sender, token, false); }
            if(_pool[token].uPending[msg.sender] != 0){ 
                uint256 pValue = _pool[token].uPending[msg.sender];
                    _pool[token].uPending[msg.sender] = 0;
                    _pool[token].pendingTotal -= pValue;
                IERC20(_daddy).transfer(msg.sender, pValue);
            }   IERC20(token).transfer(msg.sender, value);
            _updateEmission();
            _tricycle(token);
        }

        function emergencyWithdraw(address pool) public {
            require(_pool[pool].uDeposit[msg.sender] != 0, "User not found");
            uint256 uValue = _pool[pool].uDeposit[msg.sender];
                _pool[pool].uDeposit[msg.sender] = 0;
                _pool[pool].userTotal -= uValue;
            _modUser(msg.sender, pool, false);
            IERC20(pool).transfer(msg.sender, uValue);
        }

        function claimPending(address pool, bool compound) public goodRobot {
            require(_pool[pool].uPending[msg.sender] != 0, "Nothing to collect");
            uint256 value = _pool[pool].uPending[msg.sender];
                _pool[pool].uPending[msg.sender] = 0;
                _pool[pool].pendingTotal -= value;
            if(!compound){ IERC20(_daddy).transfer(msg.sender, value); }
            else {
                if(pool == _daddy){
                    require(_pool[_daddy].active, "Compound currently disabled");
                    if(!_pool[_daddy].isUser[msg.sender]){ _modUser(msg.sender, _daddy, true); }
                    _pool[pool].uDeposit[msg.sender] += value;
                    _pool[pool].userTotal += value;
                } else if(pool == _daddyLP){
                    require(_pool[_daddyLP].active, "Compound currently disabled");
                    if(!_pool[_daddyLP].isUser[msg.sender]){ _modUser(msg.sender, _daddyLP, true); }
                    uint256 tValue = value / 2;
                    uint256 eValue = _swapToken(tValue, true);
                    uint256 pValue = _addLiquidity(eValue, tValue);
                    _pool[pool].uDeposit[msg.sender] += pValue;
                    _pool[pool].userTotal += pValue;
                } else { revert("Invalid Pool"); }
            }
        }

    // OPERATIONS
        function setAuthState(address user, bool state) public OP { _auth[user] = state; }
        function setAuthRobot(address bot, bool state) public OP { _authRobot[bot] = state; }
        function emergencyResetTime() public OP { _lastEU = block.timestamp; }
        function setFeeReceiver(address account) public OP { _feeReceiver = account; }
        function setDevWallet(address account) public dev { _devWallet = account; }
        function setDistRate(uint256 rate) public OP { _distRate = rate; }

        function setEmissions(uint256 token, uint256 LP) public OP {
            require(token + LP == 100, "Invalid range");
            if(token == 0){ _pool[_daddy].active = false; }
            else { if(!_pool[_daddy].active){ _pool[_daddy].active = true; }}
            if(LP == 0){ _pool[_daddyLP].active = false; }
            else{ if(!_pool[_daddyLP].active){ _pool[_daddyLP].active = true; }}
                _pool[_daddy].emissions = token;
                _pool[_daddyLP].emissions = LP;
        }

        function transferOperator(address newOP) public OP {
            require(newOP != address(0), "Contract cannot be Renounced");
                _operator = newOP;
        }

        function setPoolFee(address pool, uint256 fee) public OP {
            require(fee <= 200, "Fee Capped at 2%");
                _pool[pool].depositFee = fee;
        }

        function setZapFee(uint256 fee) public OP {
            require(fee <= 200, "Fee Capped at 2%");
                _zapFee = fee;
        }

        function setBurnFee(uint256 fee) public OP {
            require(fee + _marketFee <= 100);
                _burnFee = fee;
        }

        function setMarketFee(uint256 fee) public OP {
            require(fee + _burnFee <= 100);
                _marketFee = fee;
        }

        function collectExcess(address token) public OP {
            uint256 userToken = _pool[token].userTotal;
            if(token == _daddy){
                uint256 uValue = _pool[_daddy].pendingTotal + _pool[_daddy].totalToDistribute
                    + _pool[_daddyLP].pendingTotal + _pool[_daddyLP].totalToDistribute + _totalToDistribute;
                userToken += uValue;
                require(IERC20(_daddy).balanceOf(address(this)) > userToken);
                uint256 send = IERC20(token).balanceOf(address(this)) - userToken;
                IERC20(_daddy).transfer(_feeReceiver, send);
            } else if(token == address(0)){ 
                payable(_feeReceiver).transfer(address(this).balance);
            } else { 
                uint256 send = IERC20(token).balanceOf(address(this)) - userToken;
                IERC20(token).transfer(_feeReceiver, send);
            }
        }

        function initialSetup(uint256 value, uint256 dRate, uint256 tRate, uint256 lRate) public OP {
            require(tRate + lRate == 100, "Invalid emission range");
            uint256 iValue = _tokenIntake(_daddy, msg.sender, value);
                _lastEU = block.timestamp;
                _totalToDistribute += iValue;
                _distRate = dRate;
            if(tRate != 0){
                _pool[_daddy].active = true;
                _pool[_daddy].emissions = tRate;
            } if(lRate != 0){
                _pool[_daddyLP].active = true;
                _pool[_daddyLP].emissions = lRate;
            }
        }

        function inject(uint256 value) public auth {
            uint256 injection = _tokenIntake(_daddy, msg.sender, value);
            _totalToDistribute += injection;
        }

        function directInject(uint256 value) public auth {
            uint256 injection = _tokenIntake(_daddy, msg.sender, value);
            if(_pool[_daddy].emissions != 0){
                uint256 tInject = (injection * _pool[_daddy].emissions) / 100;
                    _pool[_daddy].totalToDistribute += tInject;
            } if(_pool[_daddyLP].emissions != 0){
                uint256 lInject = (injection * _pool[_daddyLP].emissions) / 100;
                    _pool[_daddyLP].totalToDistribute += lInject;
            }
        }

    // INTERNAL
        function _tokenIntake(address token, address from, uint256 value) internal returns(uint256){
            require(IERC20(token).allowance(from, address(this)) >= value, "Insufficient Allowance");
            require(IERC20(token).balanceOf(from) >= value, "Insufficient Balance");
                uint256 spotToken = IERC20(token).balanceOf(address(this));
                IERC20(token).transferFrom(from, address(this), value);
                uint256 recToken = IERC20(token).balanceOf(address(this)) - spotToken;
            require(recToken != 0, "Token Transfer Failed");
            return recToken;
        }

        function _processFee(address token, uint256 value) internal {
            uint256 mFee;
            uint256 bFee;
            uint256 dFee;
            if(_marketFee != 0){ mFee = (value * _marketFee) / 100; }
            if(_burnFee != 0){ bFee = (value * _burnFee) / 100; }

            if(token == address(0)){
                dFee = value - mFee;
                if(mFee != 0){ payable(_feeReceiver).transfer(mFee); }
                if(dFee != 0){ payable(_devWallet).transfer(dFee); }
            } else {
                dFee = value - (mFee + bFee);
                if(mFee != 0){ IERC20(token).transfer(_feeReceiver, mFee); }
                if(dFee != 0){ IERC20(token).transfer(_devWallet, dFee); }
                if(bFee != 0){ IERC20(token).transfer(address(0xdead), bFee); }
            }
        }

        function _modUser(address user, address pool, bool add) internal {
            if(add){
                _pool[pool].isUser[user] = true;
                _pool[pool].uIndex[user] = _pool[pool].users.length;
                _pool[pool].users.push(user);
            } else {
                uint256 lastIndex = _pool[pool].users.length-1;
                uint256 thisIndex = _pool[pool].uIndex[user];
                address lastUser = _pool[pool].users[lastIndex];
                    _pool[pool].users[thisIndex] = lastUser;
                    _pool[pool].uIndex[lastUser] = thisIndex;
                    _pool[pool].isUser[user] = false;
                    _pool[pool].users.pop();
                delete _pool[pool].uIndex[user];
            }
        }

        function _swapToken(uint256 value, bool sell) internal returns(uint256){
            if(sell){
                address[] memory path = new address[](2);
                    path[0] = _daddy;
                    path[1] = IDexRouter(_router).WETH();
                uint256 spotETH = address(this).balance;
                IERC20(_daddy).approve(_router, value);
                IDexRouter(_router).swapExactTokensForETHSupportingFeeOnTransferTokens
                    (value, 0, path, address(this), block.timestamp);
                uint256 recETH = address(this).balance - spotETH;
                require(recETH != 0, "Swap Failed");
                return recETH;
            } else {
                address[] memory path = new address[](2);
                    path[0] = IDexRouter(_router).WETH();
                    path[1] = _daddy;
                uint256 spotToken = IERC20(_daddy).balanceOf(address(this));
                IDexRouter(_router).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: value }
                    (0, path, address(this), block.timestamp);
                uint256 recToken = IERC20(_daddy).balanceOf(address(this)) - spotToken;
                require(recToken != 0, "Swap Failed");
                return recToken;
            }
        }

        function _addLiquidity(uint256 eValue, uint256 tValue) internal returns(uint256){
            uint256 spotPair = IERC20(_daddyLP).balanceOf(address(this));
            IERC20(_daddy).approve(_router, tValue);
            IDexRouter(_router).addLiquidityETH{ value: eValue }
                (_daddy, tValue, 0, 0, address(this), block.timestamp);
            uint256 recPair = IERC20(_daddyLP).balanceOf(address(this)) - spotPair;
            require(recPair != 0, "LP Creation failed");
            return recPair;
        }

        function _removeLiquidity(uint256 pValue) internal returns(uint256,uint256){
            uint256 spotToken = IERC20(_daddy).balanceOf(address(this));
            uint256 spotETH = address(this).balance;
            IERC20(_daddyLP).approve(_router, pValue);
            IDexRouter(_router).removeLiquidityETH
                (_daddy, pValue, 0, 0, address(this), block.timestamp);
            uint256 recToken = IERC20(_daddy).balanceOf(address(this)) - spotToken;
            uint256 recETH = address(this).balance - spotETH;
            require(recToken != 0 && recETH != 0, "LP Destruction Failed");
            return(recETH,recToken);
        }

        function _updateEmission() internal {
            if(_lastEU + 60 <= block.timestamp){
                uint256 pastEpoch = block.timestamp - _lastEU;
                uint256 dValue = _distRate * pastEpoch;
                if(dValue <= _totalToDistribute){
                    _lastEU = block.timestamp;
                    if(_pool[_daddy].emissions != 0){
                        uint256 tInject = (dValue * _pool[_daddy].emissions) / 100;
                            _pool[_daddy].totalToDistribute += tInject;
                    } if(_pool[_daddyLP].emissions != 0){
                        uint256 lInject = (dValue * _pool[_daddyLP].emissions) / 100;
                            _pool[_daddyLP].totalToDistribute += lInject;
                    }   _totalToDistribute -= dValue;
                } else {
                    if(_totalToDistribute != 0){
                        _lastEU = block.timestamp;
                        if(_pool[_daddy].emissions != 0){
                            uint256 tInject = (_totalToDistribute * _pool[_daddy].emissions) / 100;
                                _pool[_daddy].totalToDistribute += tInject;
                        } if(_pool[_daddyLP].emissions != 0){
                            uint256 lInject = (_totalToDistribute * _pool[_daddyLP].emissions) / 100;
                                _pool[_daddyLP].totalToDistribute += lInject;
                        }   _totalToDistribute = 0;
                    }
                }
            }
        }

        function _tricycle(address token) internal {
            if(_pool[token].totalToDistribute >= _pool[token].users.length * 10000){
                uint256 distributed;
                for(uint256 u = 0; u < _pool[token].users.length; u++){
                    address user = _pool[token].users[u];
                    uint256 uPer = (_pool[token].uDeposit[user] * 10000) / _pool[token].userTotal;
                    uint256 uCut = (_pool[token].totalToDistribute * uPer) / 10000;
                        _pool[token].uPending[user] += uCut;
                        distributed += uCut;
                }   _pool[token].pendingTotal += distributed;
                    _pool[token].totalToDistribute -= distributed;
            }
        }

        function _getPair() internal view returns(address){
            address factory = IDexRouter(_router).factory();
            address weth = IDexRouter(_router).WETH();
            address pair = IDexFactory(factory).getPair(weth, _daddy);
            require(pair != address(0), "Cannot locate pair");
            return pair;
        }

        function isContract(address account) internal view returns(bool){
            uint256 size;
            assembly { size := extcodesize(account) }
            return size > 0;
        }

    // MODIFIERS
        modifier OP(){ require(msg.sender == _operator); _; }
        modifier auth(){ require(_auth[msg.sender], "User does not have permission"); _; }
        modifier dev(){ require(msg.sender == _devWallet); _; }
        modifier goodRobot(){ if(isContract(msg.sender)){ require(_authRobot[msg.sender], "Bad Robot!"); } _; }
        modifier open(address pool){ require(_pool[pool].active, "Pool is closed"); _; }
}