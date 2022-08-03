// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import "./prePoloToken.sol";

contract prePoloDream is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    prePoloToken public immutable  prepoloToken;

    IERC20 public immutable POLOToken;

    address  poloAddress;

    bool  hasBurnedUnsoldPresale;

    uint256 public startBlock;

    event prePoloToPolo(address sender, uint256 amount);
    event burnUnclaimedPOLO(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _prepoloAddress, address _poloAddress) {
        require(_prepoloAddress != _poloAddress, "prepolo cannot be equal to polo");
        startBlock = _startBlock;
        prepoloToken = prePoloToken(_prepoloAddress);
        POLOToken = IERC20(_poloAddress);
    }

    function swapprePoloForPOLO() external nonReentrant {
        require(block.number >= startBlock, "prepolo still awake.");

        uint256 swapAmount = prepoloToken.balanceOf(msg.sender);
        require(POLOToken.balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        require(prepoloToken.transferFrom(msg.sender, BURN_ADDRESS, swapAmount), "failed sending prepolo" );
        POLOToken.safeTransfer(msg.sender, swapAmount);

        emit prePoloToPolo(msg.sender, swapAmount);
    }

    function sendUnclaimedPOLOToDeadAddress() external onlyOwner {
        require(block.number > prepoloToken.endBlock(), "can only send excess prepolo to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(prepoloToken.prepoloRemaining() <= POLOToken.balanceOf(address(this)),
            "burning too much polo, check again please");

        if (prepoloToken.prepoloRemaining() > 0)
            POLOToken.safeTransfer(BURN_ADDRESS, prepoloToken.prepoloRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedPOLO(prepoloToken.prepoloRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if presale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

}