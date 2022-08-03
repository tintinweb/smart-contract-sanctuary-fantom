// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/* prePoloToken Presale
 After Presale you'll be able to swap this token for Polo. Ratio 1:1
*/
contract prePoloToken is ERC20('prePoloToken', 'PREPOLO'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address  constant presaleAddress = 0xD904EF4Ca577D376D00F58314a2a7A0da0EcdE38;

    IERC20 public USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);

    IERC20 prepoloToken = IERC20(address(this));

    uint256 public salePrice = 25;

    uint256 public constant prepoloMaximumSupply = 20000 * (10 ** 18); //50k

    uint256 public prepoloRemaining = prepoloMaximumSupply;

    uint256 public maxHardCap = 500000 * (10 ** 6); // 500k usdc

    uint256 public constant maxprePoloPurchase = 2000 * (10 ** 18); // 2000 prepolo

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public constant presaleDuration = 880000; // 15 days aprox

    mapping(address => uint256) public userprePoloTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event prepoloPurchased(address sender, uint256 usdcSpent, uint256 prepoloReceived);

    constructor(uint256 _startBlock) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        _mint(address(this), prepoloMaximumSupply);
    }

    function buyprePolo(uint256 _usdcSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(prepoloRemaining > 0, "No more prePolo remains!");
        require(prepoloToken.balanceOf(address(this)) > 0, "No more prePolo left!");
        require(_usdcSpent > 0, "not enough usdc provided");
        require(_usdcSpent <= maxHardCap, "prePolo Presale hardcap reached");
        require(userprePoloTotally[msg.sender] < maxprePoloPurchase, "user has already purchased too much prepolo");

        uint256 prepoloPurchaseAmount = (_usdcSpent * 1000000000000) / salePrice;

        // if we dont have enough left, give them the rest.
        if (prepoloRemaining < prepoloPurchaseAmount)
            prepoloPurchaseAmount = prepoloRemaining;

        require(prepoloPurchaseAmount > 0, "user cannot purchase 0 prepolo");

        // shouldn't be possible to fail these asserts.
        assert(prepoloPurchaseAmount <= prepoloRemaining);
        assert(prepoloPurchaseAmount <= prepoloToken.balanceOf(address(this)));

        //send prepolo to user
        prepoloToken.safeTransfer(msg.sender, prepoloPurchaseAmount);
        // send usdc to presale address
    	USDC.safeTransferFrom(msg.sender, address(presaleAddress), _usdcSpent);

        prepoloRemaining = prepoloRemaining - prepoloPurchaseAmount;
        userprePoloTotally[msg.sender] = userprePoloTotally[msg.sender] + prepoloPurchaseAmount;

        emit prepoloPurchased(msg.sender, _usdcSpent, prepoloPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}