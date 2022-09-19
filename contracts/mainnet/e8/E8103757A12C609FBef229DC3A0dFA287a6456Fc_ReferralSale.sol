/**
 *Submitted for verification at FtmScan.com on 2022-09-19
*/

// SPDX-License-Identifier: MIT

//    //   / /                                 //   ) )
//   //____     ___      ___                  //___/ /  //  ___      ___     / ___
//  / ____    //   ) ) ((   ) ) //   / /     / __  (   // //   ) ) //   ) ) //\ \
// //        //   / /   \ \    ((___/ /     //    ) ) // //   / / //       //  \ \
////____/ / ((___( ( //   ) )      / /     //____/ / // ((___/ / ((____   //    \ \
// Developed by Dogu Deniz UGUR (https://github.com/DoguD)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// NFT Contract Interface
interface EasyBlock {
    function shareCount(address _address) external view returns (uint256);
}

interface EasyAvatars {
    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenIncludesShare(uint256 tokenId) external view returns (bool);

    function mintForSelfFtm(uint256 amountOfTokens) external payable;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ReferralSale is Ownable, IERC721Receiver {
    uint256 public discountedPrice = 20 ether;
    uint256 public price = 100 ether;

    EasyAvatars easyAvatars =
        EasyAvatars(0x5d6f546f2357E84720371A0510f64DBC3FbACe33);
    EasyBlock easyBlock = EasyBlock(0x32Db9fcc61c3180F88515b1EdD7c41e76A5166aF);

    // General Stats
    uint256 public discountedMintCount = 0;
    uint256 public mintCount = 0;

    // Referral System
    uint256 public referralReward = 100; // In basis points
    uint256 public referralRewardDistributedTotal = 0;
    uint256 public referralSaleOccuredTotal = 0;
    mapping(address => uint256) public referralRewardDistributed;
    mapping(address => uint256) public referralSaleOccured;

    function setReferralReward(uint256 _referralReward) public onlyOwner {
        referralReward = _referralReward;
    }

    // Price
    function setdiscountedPrice(uint256 newPrice) public onlyOwner {
        discountedPrice = newPrice;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // EasyBlock Original Contract
    function setEasyBlockContract(address target) public onlyOwner {
        easyBlock = EasyBlock(target);
    }

    // Discount Eligibility
    function isEligible(address buyerAddress) public view returns (bool) {
        if (easyBlock.shareCount(buyerAddress) > 0) {
            return true;
        }

        for (uint256 i = 0; i < easyAvatars.balanceOf(buyerAddress); i++) {
            if (
                easyAvatars.tokenIncludesShare(
                    easyAvatars.tokenOfOwnerByIndex(buyerAddress, i)
                )
            ) {
                return true;
            }
        }

        return false;
    }

    function mint(address destination, uint256 amountOfTokens) private {
        // Mint more NFTs if not enough
        if (easyAvatars.balanceOf(address(this)) < amountOfTokens) {
            uint256 amountToPay = amountOfTokens * 100 ether;
            easyAvatars.mintForSelfFtm{value: amountToPay}(amountOfTokens);
        }

        for (uint256 i = 0; i < amountOfTokens; i++) {
            easyAvatars.safeTransferFrom(
                address(this),
                destination,
                easyAvatars.tokenOfOwnerByIndex(address(this), 0)
            );
        }
    }

    function mintForSelf(uint256 amountOfTokens, address referrer)
        public
        payable
        virtual
    {
        require(amountOfTokens > 0, "Must mint at least one token");
        // Check Eligibility
        if (isEligible(_msgSender())) {
            require(
                discountedPrice * amountOfTokens == msg.value,
                "ETH amount is incorrect"
            );
            discountedMintCount += amountOfTokens;
        } else {
            require(
                price * amountOfTokens == msg.value,
                "ETH amount is incorrect"
            );
            mintCount += amountOfTokens;
        }
        // Check for referral
        if (
            referrer != address(0) &&
            referrer != _msgSender() &&
            easyAvatars.balanceOf(referrer) > 0
        ) {
            uint256 referralRewardAmount = (msg.value * referralReward) / 1000;
            require(
                payable(0x60e2A70a4Ba833Fe94AF82f01742e7bfd8e18FA0).send(
                    referralRewardAmount
                )
            );
            referralSaleOccuredTotal++;
            referralSaleOccured[referrer]++;
            referralRewardDistributedTotal += referralRewardAmount;
            referralRewardDistributed[referrer] += referralRewardAmount;
        }
        mint(_msgSender(), amountOfTokens);
    }

    function replenishFTM() public payable virtual {
        require(msg.value > 0, "Must send some FTM");
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    // IERC721 Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}