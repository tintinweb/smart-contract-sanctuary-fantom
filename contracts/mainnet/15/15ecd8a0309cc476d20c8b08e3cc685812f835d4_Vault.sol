/**
 *Submitted for verification at FtmScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
}

interface Pair is IERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}


interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
    );
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface Masterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _wantAmt) external;
    function poolInfo(uint256 pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardTimestamp,uint256 accBSharePerShare, bool isStarted);
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
}

contract Vault {
    
    Masterchef public masterchef = Masterchef(0x1040085D268253e8D4f932399a8019f527e58d04);
    
    IUniswapV2Router02 public router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); // Spooky
    
    IERC20 public usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 public token = IERC20(0x6437ADAC543583C4b31Bf0323A0870430F5CC2e7); // 3SHARES
    IERC20 public pooltoken1 = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // WFTM
    IERC20 public pooltoken2 = IERC20(0x14DEf7584A6c52f470Ca4F4b9671056b22f4FfDE); // 3OHM

    address[] public tokenTousdc;
    address[] public tokenTopooltoken1;
    address[] public tokenTopooltoken2;
    address[] public pooltoken1Topooltoken2;

    address public owner;
    address public harvester;

    address proposedOwner = address(0);
    uint256[] public pools = [
        0 // 3OMB FTM 0x83A52eff2E9D112E9B022399A9fD22a9DB7d33Ae
    ];
    
    constructor() {
        owner = msg.sender;
        harvester = msg.sender;
        
        token.approve(address(router), type(uint256).max);
        pooltoken1.approve(address(router), type(uint256).max);
        pooltoken2.approve(address(router), type(uint256).max);
        
        tokenTousdc = [address(token), address(usdc)];
        tokenTopooltoken1 = [address(token), address(pooltoken1)];
        tokenTopooltoken2 = [address(token), address(pooltoken2)];
        pooltoken1Topooltoken2 = [address(pooltoken1), address(pooltoken2)];
    }
    
    // View functions
    function getpoolInfo(uint256 pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardTimestamp,uint256 accBSharePerShare, bool isStarted) {
        return masterchef.poolInfo(pools[pid]);
    }

    function harvest() public {
        require(msg.sender == harvester || msg.sender == owner, "harvest");
        _claimAllRewards();
        _convertRewards(); // We don't compound because I don't think the protocol wills urvive very long
    }

    function harvestandcompound() public {
        require(msg.sender == harvester || msg.sender == owner, "harvestandcompound");
        _claimAllRewards();
        _compoundRewards(); // This is a good project and will go 10x easy.
    }

    function addPool(uint256 pid) public {
        require(msg.sender == owner, "addPool");

        // Check for duplicated PIDs
        uint256 length = pools.length;
        bool poolExists = false;
        for (uint256 i = 0; i < length; ++i) {
            if(pools[i] == pid) poolExists = true;
        }

        if(!poolExists) pools.push(pid);
    }

    function depositAll() public {
        require(msg.sender == harvester || msg.sender == owner, "depositAll");
        for (uint256 i = 0; i < pools.length; i++) {
            _deposit(pools[i]);
        }
    }
    
    function stakeall(uint256 pid) public {
        require(msg.sender == owner, "harvest");
        (address want,,,,) = masterchef.poolInfo(pid);
        IERC20 wantToken = IERC20(want);
        uint256 amount = wantToken.balanceOf(address(msg.sender));
        wantToken.transferFrom(address(msg.sender), address(this), amount);

        addPool(pid); // Always add pool when staking in case you forget to add manually.
        _deposit(pid);
    }       

    function stake(uint256 pid, uint256 amount) public {
        require(msg.sender == owner, "harvest");
        require(amount > 0, "Stake amount must be larger than 0");
        (address want,,,,) = masterchef.poolInfo(pid);
        IERC20 wantToken = IERC20(want);
        wantToken.transferFrom(address(msg.sender), address(this), amount);

        addPool(pid); // Always add pool when staking in case you forget to add manually.
        _deposit(pid);
    }

    function deposit(uint256 pid) public {
        require(msg.sender == harvester || msg.sender == owner, "deposit");
        _deposit(pid);
    }
    
    function _deposit(uint256 pid) internal {
        //(address want,,,,uint16 depositFee,) = masterchef.poolInfo(pid);
        //require(depositFee <= 100, "!DEPFEE"); // NO DEPOSIT FEE
        (address want,,,,) = masterchef.poolInfo(pid);

        IERC20 wantToken = IERC20(want);
        uint256 amount = wantToken.balanceOf(address(this));
        if(amount > 0){
            wantToken.approve(address(masterchef), amount);
            masterchef.deposit(pid, amount);
        }
    }
    
    //withdraw staked tokens from masterchef
    function withdraw(uint256 pid) public {
        require(msg.sender == owner, "withdraw all");
        (uint256 amount,) = masterchef.userInfo(pid, address(this)); 
        masterchef.withdraw(pid, amount);
    }
    
    function withdraw(uint256 pid, uint256 amount) public {
        require(msg.sender == owner, "withdraw");
        masterchef.withdraw(pid, amount);
    }
    
    function emergencyWithdrawAll() public {
        require(msg.sender == owner, "emergencyWithdrawAll");
        for (uint256 i = 0; i < pools.length; i++) {
            masterchef.emergencyWithdraw(pools[i]);
        }
    }
    
    function emergencyWithdraw(uint256 pid) public {
        require(msg.sender == owner, "emergencyWithdraw");
        masterchef.emergencyWithdraw(pid);
    }
    
        
    function withdrawEverythingToWallet() public {
        require(msg.sender == owner, "widhrawEverythingToWallet");
        for (uint256 i = 0; i < pools.length; i++) {
            masterchef.emergencyWithdraw(pools[i]);
            (address want,,,,) = masterchef.poolInfo(pools[i]);
            inCaseTokensGetStuck(want);
        }
    }
    
    function claimAllRewards() public {
        require(msg.sender == harvester || msg.sender == owner, "claimAllRewards");
        _claimAllRewards();
    }

    function _claimAllRewards() internal {
        for (uint256 i = 0; i < pools.length; i++) {
            _claimRewards(pools[i]);
        }
    }
    
    function claimRewards(uint256 pid) public {
        require(msg.sender == harvester || msg.sender == owner, "claimRewards");
        _claimRewards(pid);
    }
    
    function _claimRewards(uint256 pid) internal {
        masterchef.deposit(pid, 0);
    }
    function convertRewards() public {
        require(msg.sender == harvester || msg.sender == owner, "convertRewards");
        _convertRewards();
    }

    function _convertRewards() internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                0,
                tokenTousdc,
                address(this),
                block.timestamp
            );
        }
    }

    function compoundRewards() external {
       require(msg.sender == harvester || msg.sender == owner, "convertRewards");
        _compoundRewards();
    }

    function _compoundRewards() internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                0,
                tokenTopooltoken1,
                address(this),
                block.timestamp
            ); // Convert all to WFTM first
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                pooltoken1.balanceOf(address(this)) / 2,
                0,
                pooltoken1Topooltoken2,
                address(this),
                block.timestamp
            ); // Convert 50% of WTFM to pooltoken2
            router.addLiquidity(
                address(pooltoken1),
                address(pooltoken2),
                pooltoken1.balanceOf(address(this)),
                pooltoken2.balanceOf(address(this)),
                0,
                0,
                address(this),
                block.timestamp
            ); // Add liquidity
            _deposit(pools[0]);
        }
    }

    function getBalance(uint256 pid) public view returns (uint256){
        (uint256 shares,) = masterchef.userInfo(pid, address(this));
        return shares;
    }
    
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public {
        require(msg.sender == owner, "inCaseTokensGetStuck");
        IERC20(_token).transfer(_to, _amount);
    }

    function inCaseTokensGetStuck(
        address _token
    ) public {
        require(msg.sender == owner, "inCaseTokensGetStuck");
        IERC20 t = IERC20(_token);
        uint256 balance = t.balanceOf(address(this));
        t.transfer(msg.sender, balance);
    }
    
    function executeTransaction(address target, uint value, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == owner, "executeTransaction: owner only");
        (bool success, bytes memory returnData) = target.call{value:value}(data);
        require(success, "Reverted.");
        return returnData;
    }
    
    function executeDelegateTransaction(address target, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == owner, "executeTransaction: owner only");
        (bool success, bytes memory returnData) = target.delegatecall(data);
        require(success, "Reverted.");
        return returnData;
    }

    function setrouter(IUniswapV2Router02 _router) public {
        require(msg.sender == owner);
        router = _router;
        token.approve(address(router), type(uint256).max);
        pooltoken1.approve(address(router), type(uint256).max);
        pooltoken2.approve(address(router), type(uint256).max);
    }

    function setToken(address _token) public {
        require(msg.sender == owner);
        token = IERC20(_token);
        token.approve(address(router), type(uint256).max);
    }

    function setPoolTokens(address _pooltoken1, address _pooltoken2) public {
        require(msg.sender == owner);
        pooltoken1 = IERC20(_pooltoken1);
        pooltoken2 = IERC20(_pooltoken2);
        pooltoken1.approve(address(router), type(uint256).max);
        pooltoken2.approve(address(router), type(uint256).max);
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        proposedOwner = _owner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == proposedOwner);
        owner = proposedOwner;
    }
    
    function changeHarvester(address _harvester) public {
        require(msg.sender == owner);
        harvester = _harvester;
    }
}