/**
 *Submitted for verification at FtmScan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVoter {
    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;

    function totalWeight() external view returns (uint256);

    function usedWeights(uint256) external view returns (uint256);

    function reset(uint256) external;
}

interface IVe {
    function increase_unlock_time(uint256, uint256) external;

    function balanceOfNFT(uint256) external view returns (uint256);

    function approve(address, uint256) external;

    function ownerOf(uint256) external view returns (address);
}

struct Vote {
    uint256 tokenId;
    address[] pools;
    int256[] votes;
}

interface IMigrationBurn {
    function burnVeNft(uint256) external;

    function refundVeNft(address, uint256) external;
}

/**************************************************
 *                 Burning Escrow
 **************************************************/

contract BurningEscrow {
    /**************************************************
     *                 Initialization
     **************************************************/

    IVoter constant voter = IVoter(0xdC819F5d05a6859D2faCbB4A44E5aB105762dbaE);
    IVe constant ve = IVe(0xcBd8fEa77c2452255f59743f55A3Ea9d83b3c72b);
    IMigrationBurn constant migrationBurn =
        IMigrationBurn(0x12e569CE813d28720894c2A0FFe6bEC3CCD959b2);
    uint256 constant MAXTIME = 4 * 365 * 86400;
    uint256[] public escrowedNfts;
    mapping(uint256 => address) public nftOwners;
    address public owner;
    address public operator0;
    address public operator1;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner ||
                msg.sender == operator0 ||
                msg.sender == operator1
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        operator0 = msg.sender;
        operator1 = msg.sender;
    }

    /**************************************************
     *                  User management
     **************************************************/

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setOperator0(address _operator) external onlyOwner {
        operator0 = _operator;
    }

    function setOperator1(address _operator) external onlyOwner {
        operator1 = _operator;
    }

    /**************************************************
     *               Voting and NFT management
     **************************************************/

    // Refunds

    function refundVeNfts(uint256[] memory tokenIds) external {
        for (uint256 tokenIndex; tokenIndex < tokenIds.length; tokenIndex++) {
            uint256 tokenId = tokenIds[tokenIndex];
            refundVeNft(tokenId);
        }
    }

    function refundVeNft(uint256 tokenId) public {
        refundVeNft(address(this), tokenId);
    }

    function refundVeNft(address ownerAddress, uint256 tokenId)
        public
        onlyOwnerOrOperator
    {
        migrationBurn.refundVeNft(ownerAddress, tokenId);
    }

    // Voting

    function vote(Vote[] memory votes) external {
        for (uint256 voteIndex; voteIndex < votes.length; voteIndex++) {
            Vote memory _vote = votes[voteIndex];
            vote(_vote.tokenId, _vote.pools, _vote.votes);
        }
    }

    function vote(
        uint256 tokenId,
        address[] memory pools,
        int256[] memory votes
    ) public onlyOwnerOrOperator {
        voter.vote(tokenId, pools, votes);
    }

    // Burn

    function burnVeNfts(uint256[] memory tokenIds) external {
        for (uint256 tokenIndex; tokenIndex < tokenIds.length; tokenIndex++) {
            uint256 tokenId = tokenIds[tokenIndex];
            burnVeNft(tokenId);
        }
    }

    function burnVeNft(uint256 tokenId) public onlyOwnerOrOperator {
        voter.reset(tokenId);
        ve.approve(address(migrationBurn), tokenId);
        migrationBurn.burnVeNft(tokenId);
    }

    // Locks

    function increaseUnlockTimes(uint256[] memory tokenIds)
        public
        onlyOwnerOrOperator
    {
        for (uint256 tokenIndex; tokenIndex < tokenIds.length; tokenIndex++) {
            try
                ve.increase_unlock_time(tokenIds[tokenIndex], MAXTIME)
            {} catch {}
        }
    }

    /**************************************************
     *                  View methods
     **************************************************/

    function voteWeight(uint256[] memory tokenIds)
        public
        view
        returns (uint256 totalBalance)
    {
        for (uint256 tokenIndex; tokenIndex < tokenIds.length; tokenIndex++) {
            uint256 tokenId = tokenIds[tokenIndex];
            uint256 balance = ve.balanceOfNFT(tokenId);
            totalBalance += balance;
        }
    }

    function voteWeightUsed(uint256[] memory tokenIds)
        public
        view
        returns (uint256 usedWeights)
    {
        for (uint256 tokenIndex; tokenIndex < tokenIds.length; tokenIndex++) {
            uint256 tokenId = tokenIds[tokenIndex];
            uint256 usedWeight = voter.usedWeights(tokenId);
            usedWeights += usedWeight;
        }
    }

    function voteWeightLeft(uint256[] memory tokenIds)
        public
        view
        returns (uint256 usedWeights)
    {
        return voteWeight(tokenIds) - voteWeightUsed(tokenIds);
    }

    function totalVoteWeight() public view returns (uint256) {
        return voter.totalWeight();
    }

    function totalVoteWeightAfterAllUsed(uint256[] memory tokenIds)
        public
        view
        returns (uint256)
    {
        return voter.totalWeight() + voteWeightLeft(tokenIds);
    }

    function votePercentage(uint256[] memory tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 tokensWeight = voteWeight(tokenIds);
        uint256 totalWeight = totalVoteWeightAfterAllUsed(tokenIds);
        return (tokensWeight * 10000) / totalWeight;
    }

    function getEscrowedNfts() external view returns (uint256[] memory) {
        return escrowedNfts;
    }

    function getEscrowedNftsLength() external view returns (uint256) {
        return escrowedNfts.length;
    }

    /**************************************************
     *                 ERC721 Receiving
     **************************************************/
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(msg.sender == address(ve));
        if (nftOwners[tokenId] == address(0)) {
            nftOwners[tokenId] = from;
            escrowedNfts.push(tokenId);
            ve.approve(address(migrationBurn), tokenId);
            migrationBurn.burnVeNft(tokenId);
        }
        return this.onERC721Received.selector;
    }

    /**************************************************
     *              Arbitrary code execution
     **************************************************/

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwner returns (bool success) {
        if (operation == Operation.Call) success = executeCall(to, value, data);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data);
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    function executeDelegateCall(address to, bytes memory data)
        internal
        returns (bool success)
    {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}