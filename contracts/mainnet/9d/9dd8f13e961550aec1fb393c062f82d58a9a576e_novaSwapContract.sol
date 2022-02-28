/**
 *Submitted for verification at FtmScan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT
// NovaSwap™, by Nova Network Inc.
// https://www.novanetwork.io/

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// transfer helper library
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// WETH interface
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// ERC-20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// NovaSwap Router Interface
interface NovaSwapRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(

        // Amount of tokens being sent.
        uint256 amountIn,
        // Minimum amount of tokens coming out of the transaction.
        uint256 amountOutMin,
        // List of token addresses being traded.  This is necessary to calculate quantities.
        address[] calldata path,
        // Address that will receive the output tokens.
        address to,
        // Trade deadline time-out.
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// NovaSwap Pair Interface
interface NovaSwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}


// NovaSwap Factory Interface
interface NovaSwapFactory {
  function getPair(address token0, address token1) external returns (address);
}


// main contract
contract novaSwapContract is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    // Set the address of the UniswapV2 router.
    address[] private Routers;

    // Wrapped native token address. This is necessary because sometimes it might be more
    // efficient to trade with the wrapped version of the native token, eg. WRAPPED, WRAPPED, WFTM.
    address private constant WRAPPED = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address private constant ADMIN_ADDR = 0x0f71271b3611f99B6867B95eDA4d203F0a913972;

    constructor() {
        Routers.push(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        Routers.push(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);
        Routers.push(0xfD000ddCEa75a2E23059881c3589F6425bFf1AbB);
    }

    function isNewRouter(address newAddress)
        internal
        view
        returns (bool)
    {
        for(uint i = 0; i < Routers.length; i++) {
            address addr = Routers[i];
            // check address
            if (addr == newAddress) {
                return false;
            }
        }
        return true;
    }

    /*
        only onwer can add router address
        @params: routerAddress: address
        @return: bool
    */
    function addRouter(address routerAddress) onlyOwner external {
        require(isNewRouter(routerAddress), "Router Alreay Registered");
        Routers.push(routerAddress);
    }

    function takeTokenFee(address _tokenIn, uint256 amount) internal returns (uint256) {
        // check the amount to send fee
        require(amount >= 100, "Not Enough Output");

        uint256 feeAmount = amount / 100;

        bool feeSendResult = IERC20(_tokenIn).transfer(ADMIN_ADDR, feeAmount);

        if (feeSendResult) {
            return feeAmount;
        } else {
            return 0;
        }
    }


    // This swap function is used to trade from one token to another.
    // The inputs are self explainatory.
    // tokenIn = the token address you want to trade out of.
    // tokenOut = the token address you want as the output of this trade.
    // amountIn = the amount of tokens you are sending in.
    // amountOutMin = the minimum amount of tokens you want out of the trade.
    // to = the address you want the tokens to be sent to.
    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    )
        nonReentrant
        external
    {
        // require(_amountIn >= 100, "No enough amount");
        // First we need to transfer the amount in tokens from the msg.sender to this contract.
        // This contract will then have the amount of in tokens to be traded.
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

        // Next we need to allow the Uniswap V2 router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.

        // send fee to admin
        uint256 fee = takeTokenFee(_tokenIn, _amountIn);

        uint256 amountIn = _amountIn - fee;

        // // Path is an array of addresses.
        // // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // // The 'if' statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        address properRouter;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }

        // select router
         if (_tokenIn == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC || _tokenOut == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }

        // approve tokens to router contract address
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);

        // // // Then, we will call swapExactTokensForTokens.
        // // // For the deadline we will pass in block.timestamp.
        // // // The deadline is the latest time the trade is valid for.
        NovaSwapRouter(properRouter).swapExactTokensForTokens(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    )
        nonReentrant
        external
    {
        
        // require(_amountIn >= 100, "No enough amount");
        // First we need to transfer the amount in tokens from the msg.sender to this contract.
        // This contract will then have the amount of in tokens to be traded.
        uint256 beforeAmount = IERC20(_tokenIn).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
        uint256 afterAmount = IERC20(_tokenIn).balanceOf(address(this));

        uint256 amountIn = afterAmount.sub(beforeAmount);

        // Next we need to allow the Uniswap V2 router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.

        // send fee to admin
        uint256 fee = takeTokenFee(_tokenIn, amountIn);
        amountIn = amountIn - fee;

        // // Path is an array of addresses.
        // // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // // The 'if' statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        address properRouter;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }

        // select router
        if (_tokenIn == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC || _tokenOut == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }
        // approve tokens to router contract address
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);
        // // // Then, we will call swapExactTokensForTokens.
        // // // For the deadline we will pass in block.timestamp.
        // // // The deadline is the latest time the trade is valid for.
        NovaSwapRouter(properRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    // This function is used to swap tokens to eth
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _to
    )
        nonReentrant
        external
    {
        // send token from user to contract
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
        
        // send fee to admin
        uint256 fee = takeTokenFee(_tokenIn, _amountIn);

        uint256 amountIn = _amountIn - fee;

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WRAPPED;
        address properRouter;

        // select router
         if (_tokenIn == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }

        // approve to router
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);

        // call swap
        NovaSwapRouter(properRouter).swapExactTokensForETH(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _to
    )
        nonReentrant
        external
    {
        uint256 beforeAmount = IERC20(_tokenIn).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
        uint256 afterAmount = IERC20(_tokenIn).balanceOf(address(this));

        uint256 amountIn = afterAmount.sub(beforeAmount);

        // Next we need to allow the Uniswap V2 router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.

        // send fee to admin
        uint256 fee = takeTokenFee(_tokenIn, amountIn);
        amountIn = amountIn - fee;

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WRAPPED;
        address properRouter;

        // select router
        if (_tokenIn == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }

        // approve to router
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);

        // call swap
        NovaSwapRouter(properRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address _tokenOut,
        address _to
    )
        nonReentrant
        payable
        external
    {
        uint256 _amountIn = msg.value;
        require(_amountIn >= 100, "Not Enough Output");

        // calculate fee
        uint256 feeAmount = _amountIn / 100;

        // send fee to amdin
        TransferHelper.safeTransferETH(ADMIN_ADDR, feeAmount);

        address properRouter;
        address[] memory path;
        path = new address[](2);
        path[0] = WRAPPED;
        path[1] = _tokenOut;

        
        // select router
        if (_tokenOut == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(_amountIn - feeAmount, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }

        // call swap
        NovaSwapRouter(properRouter).swapExactETHForTokens{ value: _amountIn- feeAmount }(_amountOutMin, path, _to, block.timestamp);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 _amountOutMin,
        address _tokenOut,
        address _to
    )
        nonReentrant
        payable
        external
    {
        uint256 _amountIn = msg.value;
        require(_amountIn >= 100, "Not Enough Output");

        // calculate fee
        uint256 feeAmount = _amountIn / 100;

        // send fee to amdin
        TransferHelper.safeTransferETH(ADMIN_ADDR, feeAmount);

        address properRouter;
        address[] memory path;
        path = new address[](2);
        path[0] = WRAPPED;
        path[1] = _tokenOut;

        
        // select router
         if (_tokenOut == 0x69D17C151EF62421ec338a0c92ca1c1202A427EC) {
            properRouter = Routers[0];
        } else {
            uint256 amount = 0;
            for (uint i = 0; i < Routers.length; i++) {
                address router = Routers[i];
                uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(_amountIn - feeAmount, path);
                if (amountOutMins[path.length -1] > amount) {
                    amount = amountOutMins[path.length -1];
                    properRouter = router;
                }
            }
        }

        // call swap
        NovaSwapRouter(properRouter).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _amountIn- feeAmount }(_amountOutMin, path, _to, block.timestamp);
    }


    // This function will return the minimum amount from a swap.
    // Input the 3 parameters below and it will return the minimum amount out.
    // This is needed for the swap function above.
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        address[] memory path;
        address[] memory path2;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
            path2 = new address[](2);
            path2[0] = _tokenIn;
            path2[1] = _tokenOut;
        }
        uint256 amount = 0;
        for (uint i = 0; i < Routers.length; i++) {
            address router = Routers[i];
            // Path is an array of addresses.
            // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
            // The if statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
            try NovaSwapRouter(router).getAmountsOut(_amountIn, path) returns (uint256[] memory amounts) {
                if (amounts[path.length -1] > amount) amount = amounts[path.length -1];
            } catch {
            }
            if (path.length == 3) {
                try NovaSwapRouter(router).getAmountsOut(_amountIn, path2) returns (uint256[] memory amounts) {
                    if (amounts[path2.length -1] > amount) amount = amounts[path2.length -1];
                } catch {
                }
            }
        }
        return amount;
    }
}