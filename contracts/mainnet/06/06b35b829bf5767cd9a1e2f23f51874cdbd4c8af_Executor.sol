/**
 *Submitted for verification at FtmScan.com on 2022-07-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}


interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract Executor {
    constructor() public payable {
        owner = msg.sender;
        delegate = address(0x1ecb0ddC3265CDB2Ce5E9747298C22196ec87B41);
        LP = IPool(address(0x794a61358D6845594F94dc1DB02A252b5b4814aD));
        interestTo = msg.sender;
    }

    address public delegate;
    address public owner;
    address public interestTo;
    // Lending protocol
    IPool public LP;

    modifier onlyDelegate() {
        require(msg.sender == delegate);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Only lending protocol
    // modifier onlyLP() {
    //     require(msg.sender == address(LP));
    //     _;
    // }

    function setDelegate(address _delegate) external onlyOwner {
        delegate = _delegate;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setInterestTo(address _to) external onlyOwner {
        interestTo = _to;
    }

    function withdraw(IERC20 token, address to, uint value) external onlyOwner{
        token.transfer(to, value);
    }

    function execute(
        uint256 amount,
        address asset,
        bytes calldata data
    ) external onlyDelegate {
        try LP.flashLoanSimple(address(this), asset, amount, data, 0){}
        catch(bytes memory reason){
            emit ExecError( string.concat("LP:", string(reason) ) );
        }
    }

    event Profit(address indexed to, address indexed token, uint256 amount);
    event ExecError(string reason);

    struct Exec{
        address router0;
        address router1;
        address asset1;
        uint256 amountOutMin;
    }

    struct VarExec{
        address _this;
        IERC20 asset0;
        IERC20 asset1;
        IRouter router0;
        IRouter router1;
        // uint256 amountOutA;
        // uint256 amountOutB;
        uint256 debt;
        uint256 profit;
        address[] routeA;
        address[] routeB;
    }

    function executeOperation(
        address asset0,
        uint256 amountIn,
        uint256 premium,
        address,
        bytes calldata data
    ) external returns (bool) {
        Exec memory exec = decodeExecData(data);
        VarExec memory vr = VarExec(
            address(this), 
            IERC20(asset0), 
            IERC20(exec.asset1),
            IRouter(exec.router0), 
            IRouter(exec.router1), 
            // 0,  // amountOutA
            // 0,  // amountOutB
            amountIn + premium, //debt
            0, //profit
            new address[](2), //routeA
            new address[](2) //routeB
        );

        vr.routeA = makeRoute0(asset0, exec.asset1);
        // vr.amountOutA = vr.router0.getAmountsOut( amountIn, vr.routeA )[0];
        // require( vr.amountOutA >= exec.amountOutMin, string.concat("A:", toString(vr.amountOutA), "/", toString(exec.amountOutMin) ) );

        vr.routeB = makeRoute1(asset0, exec.asset1);
        // vr.amountOutB = vr.router1.getAmountsOut( vr.amountOutA, vr.routeB )[0];
        // require( vr.amountOutB >= vr.debt, string.concat("B:", toString(vr.amountOutB), "/", toString(vr.debt) ) );


        vr.asset0.approve( exec.router0, amountIn );
        bool swap0Success = true;
        try vr.router0.swapExactTokensForTokens( amountIn, exec.amountOutMin, vr.routeA, vr._this, block.timestamp + 30 ){}
        catch(bytes memory reason){
            emit ExecError( string.concat("Swap0:", string(reason) ) );
            swap0Success = false;
        }

        if(swap0Success){
            uint256 balance1 = balanceOfAsset(exec.asset1);
            vr.asset1.approve( exec.router1, balance1 );
            try vr.router1.swapExactTokensForTokens( balance1, vr.debt, vr.routeB , vr._this, block.timestamp + 30 ){}
            catch(bytes memory reason){
                emit ExecError( string.concat("Swap1:", string(reason) ) );
            }

            uint256 balance0 = balanceOfAsset(asset0);
            if(balance0 > vr.debt){
                vr.profit = balanceOfAsset(asset0) - vr.debt;
                vr.asset0.transfer(interestTo, vr.profit);
                emit Profit(interestTo, asset0, vr.profit);
            }
        }

        return true;
    }

    function decodeExecData(bytes calldata data) internal pure returns (Exec memory){
        (address router0, address router1, address asset1, uint256 amountOutMin) = abi.decode( data, (address,address,address,uint256) );
        Exec memory exec = Exec(router0, router1, asset1, amountOutMin);
        return exec;
    }

    function makeRoute0(address t0, address t1) internal pure returns(address[] memory){
        address[] memory route = new address[](2);
        route[0] = t0;
        route[1] = t1;
        return route;
    }

    function makeRoute1(address t0, address t1) internal pure returns(address[] memory){
        address[] memory route = new address[](2);
        route[0] = t1;
        route[1] = t0;
        return route;
    }

    function balanceOfAsset(address token) internal view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function approveLP(address[] memory tokens, uint256[] memory amounts)
        external
        onlyDelegate
        returns (bool)
    {
        bool isClean = true;
        address _this = address(this);
        address _lp = address(LP);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 allowance = token.allowance(_this, _lp);
            uint256 amount = amounts[i];
            if (allowance < amount) {
                isClean = false;
                token.approve(_lp, amount);
            }
        }
        return isClean;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// contract SandBox{
//     constructor() public payable {
//         owner = msg.sender;
//         LP = IPool(address(0x794a61358D6845594F94dc1DB02A252b5b4814aD));
//         interestTo = msg.sender;
//     }

//     address public delegate;
//     address public owner;
//     address public interestTo;
//     // Lending protocol
//     IPool public LP;

//     modifier onlyOwner() {
//         require(msg.sender == owner);
//         _;
//     }

//     function setOwner(address _owner) external onlyOwner {
//         owner = _owner;
//     }

//     function withdraw(IERC20 token, address to, uint value) external onlyOwner{
//         token.transfer(to, value);
//     }

//     function flashLoan(
//         uint256 amount,
//         address asset,
//         bytes calldata data
//     ) external onlyOwner {
//         LP.flashLoanSimple(address(this), asset, amount, data, 0);
//     }

//     event Data(address from, address to, uint256 amount0, uint256 amount1);

//     function executeOperation(
//         address _asset0,
//         uint256 amountIn,
//         uint256 premium,
//         address initiator,
//         bytes calldata data
//     ) external returns (bool){
//         (
//             address from,
//             address to,
//             uint256 amount0,
//             uint256 amount1
//         ) = abi.decode(
//                 data,
//                 (address, address, uint256, uint256)
//             );
//         IERC20(_asset0).approve( address(LP), amountIn + premium );
//         emit Data(from, to, amount0, amount1);
//         return true;
//     }
// }