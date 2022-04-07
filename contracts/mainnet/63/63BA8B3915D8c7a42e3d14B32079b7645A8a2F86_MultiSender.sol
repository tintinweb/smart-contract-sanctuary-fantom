// Be name Khoda
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= Multi Sender =========================
// ================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

import "./interfaces/Ive.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title Multi Sender
/// @author DEUS Finance
/// @notice veDEUS multi sender
contract MultiSender {
    address public veDeus;
    address public owner;

    constructor(address veDeus_) {
        veDeus = veDeus_;
        owner = msg.sender;
        address deus = Ive(veDeus).token();
        IERC20(deus).approve(veDeus_, type(uint256).max);
    }

    function send(address[] calldata users, uint256[] calldata amounts, uint256[] calldata lock_time) external {
        require(msg.sender == owner, "Only owner can send");
        for (uint256 i = 0; i < users.length; i++) {
            Ive(veDeus).create_lock_for(amounts[i], lock_time[i], users[i]);
        }
    }

    function withdrawERC20(address token, uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(IERC20(token).transfer(msg.sender, amount), "Failed to transfer");
    }

    function approve(address token, address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner can approve");
        require(IERC20(token).approve(to, amount), "Failed to approve");
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint256 ts;
    uint256 blk; // block
}

struct LockedBalance {
    int128 amount;
    uint256 end;
}

interface Ive {
    function token() external view returns (address);

    function supply() external view returns (uint256);

    function locked(uint256 i) external view returns (LockedBalance calldata);

    function ownership_change(uint256 i) external view returns (uint256);

    function epoch() external view returns (uint256);

    function point_history(uint256 i) external view returns (Point calldata);

    function user_point_history(uint256 i)
        external
        view
        returns (Point[] calldata);

    function user_point_epoch(uint256 i) external view returns (uint256);

    function slope_changes(uint256 i) external view returns (int128);

    function attachments(uint256 i) external view returns (uint256);

    function voted(uint256 i) external view returns (bool);

    function voter() external view returns (address);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function version() external view returns (string calldata);

    function decimals() external view returns (uint8);

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);

    function get_last_user_slope(uint256 _tokenId)
        external
        view
        returns (int128);

    function user_point_history__ts(uint256 _tokenId, uint256 _idx)
        external
        view
        returns (uint256);

    function locked__end(uint256 _tokenId) external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function setVoter(address _voter) external;

    function voting(uint256 _tokenId) external;

    function abstain(uint256 _tokenId) external;

    function attach(uint256 _tokenId) external;

    function detach(uint256 _tokenId) external;

    function merge(uint256 _from, uint256 _to) external;

    function block_number() external view returns (uint256);

    function checkpoint() external;

    function deposit_for(uint256 _tokenId, uint256 _value) external;

    function create_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

    function create_lock(uint256 _value, uint256 _lock_duration)
        external
        returns (uint256);

    function increase_amount(uint256 _tokenId, uint256 _value) external;

    function increase_unlock_time(uint256 _tokenId, uint256 _lock_duration)
        external;

    function withdraw(uint256 _tokenId) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t)
        external
        view
        returns (uint256);

    function balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        external
        view
        returns (uint256);

    function totalSupplyAtT(uint256 t) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);
}