/**
 *Submitted for verification at FtmScan.com on 2022-04-26
*/

/**
 *Submitted for verification at FtmScan.com on 2022-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MineAuction {
    event Bid(address bidder, uint amount, uint charType, uint tokenId);

    IERC20 public acceptableToken;
    IERC721 public mms2;
    IERC721 public mms1;
    IERC721 public hero;

    uint public phrase;             // 1 - started/free bid, 2 - bid then extend
    uint public phraseOneEndAt;     // when will the free bid end
    uint public endedAt;            // when will the limited time bid end
    bool public ended;              // note: flag to indicate if auction is ended, might not be valid if no one trigger its change via bidding
    address public highestBidder;   // bid winner
    address public owner;
    address public target;          // final address where bidding fund will be transferred to
    uint public highestBid;
    uint public bidInc;             // bidding amount increment
    uint public tokenId;            // which char will get entry fee, used with charType, 1: hero, 2: mms1, 3: mms2
    uint public charType;
    uint public phraseOneDelay;
    uint public phraseTwoDelay;
    uint public round;

    constructor(address _a, address _h, address _m1, address _m2, uint _startingBid, uint _bidInc) {
        owner = msg.sender;
        acceptableToken = IERC20(_a);
        hero = IERC721(_h);
        mms1 = IERC721(_m1);
        mms2 = IERC721(_m2);

        highestBid = _startingBid * 10 ** 18;
        bidInc = _bidInc * 10 ** 18;

        // note: for testnet only
        phraseOneDelay = 24 hours;
        phraseTwoDelay = 15 minutes;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function bid(uint _charType, uint _tokenId, uint _amount) external {
        // note: tokenId could be changed between biddings
        _amount = _amount * 10 ** 18;
        require(ended == false, "auc ended - ended");
        require(_amount >= highestBid + bidInc, "value < highest");

        if (_charType == 3) {
            if (msg.sender != mms2.ownerOf(_tokenId)) {
                revert("wrong NFT owner");
            }
        } else if (_charType == 2) {
            if (msg.sender != mms1.ownerOf(_tokenId)) {
                revert("wrong NFT owner");
            }
        } else if (_charType == 1) {
            if (msg.sender != hero.ownerOf(_tokenId)) {
                revert("wrong NFT owner");
            }
        } else {
            revert("wrong char type");
        }

        if (phrase == 0) {  // start and go into phrase 1
            phrase = 1;
            phraseOneEndAt = block.timestamp + phraseOneDelay;
        } else if (phrase == 1) {
            if (block.timestamp > phraseOneEndAt) {
                if (block.timestamp <= phraseOneEndAt + phraseTwoDelay) {  // if new bid time in oneendat and first twodelay, then enter 2 phrase
                    phrase = 2;
                    endedAt = block.timestamp + phraseTwoDelay;
                } else {  // time beyond oneendat and first twodelay, then auction ends at phrase 1
                    ended = true;
                    revert("auc ended - expired 1");
                }
            }
        } else if (phrase == 2) {
            if (block.timestamp > endedAt) {
                ended = true;
                revert("auc ended - expired 2");
            }
            endedAt = block.timestamp + phraseTwoDelay;
        } else {
            revert("illegal phrase");
        }

        acceptableToken.transferFrom(msg.sender, address(this), _amount);  // get this bid first
        if (highestBidder != address(0)) {
            acceptableToken.transfer(highestBidder, highestBid);  // send back to last bidder if we have one
        }

        highestBidder = msg.sender;
        highestBid = _amount;
        tokenId = _tokenId;
        charType = _charType;
        round = round + 1;

        emit Bid(highestBidder, highestBid, charType, tokenId);
    }

    function isAuctionEnd() public view returns (bool) {  // observer which can tell actual status of this auction
        if (phrase == 1) {
            if (block.timestamp > phraseOneEndAt + phraseTwoDelay) {
                return true;
            }
        } else if (phrase == 2) {
            if (block.timestamp > endedAt) {
                return true;
            }
        }

        return false;
    }

    function setTarget(address _t) external onlyOwner validAddress(_t) {
        target = _t;
    }

    function changeTokenId(uint _charType, uint _tokenId) external onlyOwner {
        charType = _charType;
        tokenId = _tokenId;
    }

    function withdraw() external onlyOwner {
        require(target != address(0), "invalid target");
        require(isAuctionEnd(), "auc not ended");

        acceptableToken.transfer(target, highestBid);
    }
}

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

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}