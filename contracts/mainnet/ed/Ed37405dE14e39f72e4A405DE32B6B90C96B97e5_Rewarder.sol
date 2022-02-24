/**
 *Submitted for verification at FtmScan.com on 2022-02-24
*/

// SPDX-License-Identifier: Unlicensed

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

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface IRewardToken {
    function mint(address to, uint256 amount) external;
}


contract Rewarder is Ownable {

    event ClaimedReward(address to, uint256 amount);

    // nft -> tokenId -> timestamp
    mapping(INFT => mapping(uint256 => uint256)) private _registry;

    IRewardToken public rewardToken;
    INFT[]       public nfts;
    uint256      public nftsCount;
    uint256      public rewardPerSecond;

    constructor(IRewardToken rewardToken_) {
        rewardToken = rewardToken_;
    }

    receive() external payable {}

    function update() external {
        uint256 amountRewarded = 0;

        for (uint256 i = 0; i < nfts.length; i++) {
            INFT nft = nfts[i];

            for (uint256 j = 0; j < nft.balanceOf(msg.sender); j++) {
                uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, j);

                uint256 checkpoint = _registry[nft][tokenId];

                // Token was registered previously; receipt exists
                if (checkpoint > 0) {
                    uint256 reward = (block.timestamp - checkpoint) * rewardPerSecond;
                    rewardToken.mint(msg.sender, reward);
                    amountRewarded += reward;
                }

                // Update timestamp regardless of if token
                // was previously registered or not.
                _registry[nft][tokenId] = block.timestamp;
            }
        }

        if (amountRewarded > 0) {
            emit ClaimedReward(msg.sender, amountRewarded);
        }
    }

    function pendingReward() external view returns (uint256) {
        uint256 amount = 0;

        for (uint256 i = 0; i < nfts.length; i++) {
            INFT nft = nfts[i];

            for (uint256 j = 0; j < nft.balanceOf(msg.sender); j++) {
                uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, j);

                uint256 checkpoint = _registry[nft][tokenId];

                // Token was registered previously; receipt exists
                if (checkpoint > 0) {
                    uint256 reward = (block.timestamp - checkpoint) * rewardPerSecond;
                    amount += reward;
                }
            }
        }
        
        return amount;
    }

    function lastCheckpoint(INFT nft, uint256 tokenId) external view returns (uint256) {
        return _registry[nft][tokenId];
    }

    function setNftAddresses(INFT[] memory nfts_) external onlyOwner {
        nfts = nfts_;
        nftsCount = nfts_.length;
    }

    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyOwner {
        rewardPerSecond = rewardPerSecond_;
    }
}