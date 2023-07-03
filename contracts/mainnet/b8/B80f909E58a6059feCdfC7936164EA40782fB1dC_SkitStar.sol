// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@thirdweb-dev/contracts/extension/Ownable.sol";

interface IERC20Token {
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IERC1155BaseCreator   {
    function registerCreator(string memory, string memory, address, uint128) external returns (address);
    function setOwner(address) external;
}

contract SkitStar is Ownable {
    address tokenAddress;
    address erc1155BaseCreatorAddress;

    error UnregisteredAddress();
    error  Joined();
    error NotSubscribed();
    error Subscribed();

    struct Creator {
        address ERC1155TokenAddress;
        uint256 subscriberCount;
        uint256 giftBalance;
        string creatorInfoUrl;
        string[] videoAssets;
    }
    /// @dev mapping of creator address to their ERC1155 address
    mapping(address => Creator) public getStar;

    /// @dev array of all creators
    address[] public allStars ;

    /// @dev mapping userAccount address to the mapping of creatorAddress => subscription status
    mapping(address => mapping(address => bool)) public subscriptions;

    event CreatorRegistered(
        address indexed creatorAddress,
        address indexed erc1155tokenAddress,
        uint
    );

    constructor(address _tokenAddress, address _erc1155BaseCreatorAddress) {
        tokenAddress = _tokenAddress;
        erc1155BaseCreatorAddress = _erc1155BaseCreatorAddress;
        _setupOwner(msg.sender);
    }

    function registerCreator(
        string memory _name,
        string memory _symbol,
        string memory _infoUrl,
        uint128 _royaltyBps
    ) external returns (address skitStarAddress) {
        //check that the creator has not joined with the same wallet before
        if(getStar[msg.sender].ERC1155TokenAddress != address(0)) {
            revert Joined();
        }
        skitStarAddress = IERC1155BaseCreator(erc1155BaseCreatorAddress).registerCreator(_name, _symbol, msg.sender, _royaltyBps);
        getStar[msg.sender] = Creator(
            skitStarAddress,
            0,
            0,
            _infoUrl,
            new string[](0)
        );
        allStars.push(msg.sender);
        emit CreatorRegistered(msg.sender, skitStarAddress, allStars.length);
    }

    function subscribe(address creatorAdd) external {
        if (getStar[creatorAdd].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        if (subscriptions[msg.sender][creatorAdd] == true){
            revert Subscribed();
        }
        subscriptions[msg.sender][creatorAdd] = true;
        getStar[creatorAdd].subscriberCount++;
    }

    function unSubscribe(address creatorAdd) external {
        if (getStar[creatorAdd].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        if (subscriptions[msg.sender][creatorAdd] == false){
            revert NotSubscribed();
        }    
        delete subscriptions[msg.sender][creatorAdd];
        getStar[creatorAdd].subscriberCount--;
    }

    function giftCreator(
        address creatorAdd,
        uint256 amount
    ) external {
        if (getStar[creatorAdd].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        require(
            IERC20Token(tokenAddress).transferFrom(
                msg.sender,
                address(creatorAdd),
                amount
            ),
            "failed"
        );
        getStar[creatorAdd].giftBalance += amount;
    }

    function saveVideoAsset(string memory assetid) public {
        if (getStar[msg.sender].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        Creator storage creator = getStar[msg.sender];
        creator.videoAssets.push(assetid);
        getStar[msg.sender] = creator;
    }

    function getVideoAssets(address creatorAddress) external view returns (string[] memory)  {
        if (getStar[creatorAddress].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        return getStar[creatorAddress].videoAssets;
    }

    function getAllCreators() external view returns (Creator[] memory) {
        uint256 length = allStars.length;
        Creator[] memory creators = new Creator[](length);

        for (uint256 i = 0; i < length; i++) {
            creators[i] = getStar[allStars[i]];
        }

        return creators;
    }

    function deleteVideo(string memory _video) external {
       if (getStar[msg.sender].ERC1155TokenAddress == address(0)){
            revert UnregisteredAddress();
        }
        string[] storage videoAssets = getStar[msg.sender].videoAssets;
        for (uint256 i = 0; i < videoAssets.length; i++) {
            if (keccak256(bytes(videoAssets[i])) == keccak256(bytes(_video))) {
                // Remove the video from the videoAssets array by swapping it with the last element
                // and then reducing the array length by one
                videoAssets[i] = videoAssets[videoAssets.length - 1];
                videoAssets.pop();
                break;
            }
        }
    }

    function updateProfile(string memory _infoUrl) public {
        if (getStar[msg.sender].ERC1155TokenAddress == address(0)) {
            revert UnregisteredAddress();
        }
        Creator storage creator = getStar[msg.sender];
        creator.creatorInfoUrl = _infoUrl;
        getStar[msg.sender] = creator;
    }

    function setERC1155BaseCreatorContractAddress(address _erc1155BaseCreatorAddress) external onlyOwner {
        erc1155BaseCreatorAddress = _erc1155BaseCreatorAddress;
    }

    function setTokenContractAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    
}