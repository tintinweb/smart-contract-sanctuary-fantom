/**
 *Submitted for verification at FtmScan.com on 2022-02-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Fight is Ownable {
    address public adminAddr = 0xd755085F7cC22920b327A5d7Ad9234073dc89379;
    address player;
    uint maxid = 0;
    uint randNonce = 0;
    uint internal supply = 0;

    struct avatar {
        uint256 id;
        uint256 reusableCount;
        uint256 winningProbability;
        uint256 price;
    }

    mapping(uint256 => avatar) public avatars;
    mapping(address => mapping(uint256 => uint256)) public playerAvailableCountForAvatar;

    event choosedAvatar(address who, uint256 which);
    event gamePlayed(address who, uint256 which, string result);

    constructor() {
    }

    modifier setPlayer {
        player = msg.sender;
        _;
    }

    function setAdminChestAddr(address admin) public onlyOwner {
        adminAddr = admin;
    }

    function chooseAvatar(uint256 avatarId) public payable setPlayer returns(uint256) {
        avatar memory hero = avatars[avatarId];
        playerAvailableCountForAvatar[player][avatarId] = hero.reusableCount;

        require(msg.value >= hero.price, 'Incorrect payment');
        payable(adminAddr).transfer(hero.price/2);

        emit choosedAvatar(player, avatarId);

        return hero.id;
    }

    function canFight(address actor, uint256 avatarId) public view returns(bool) {
        if (playerAvailableCountForAvatar[actor][avatarId] > 0) return true;
        else return false;
    }

    function fight(uint256 avatarId) public payable setPlayer returns(string memory) {
        require(canFight(player, avatarId) == true, 'Not available anymore!');

        string memory vResult;
        avatar memory hero = avatars[avatarId];
        randNonce = randNonce + 1;
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % (10 ** 7);

        if (rand < hero.winningProbability) {
            vResult = "true";
            payable(msg.sender).transfer(address(this).balance);
        }
        else vResult = "false";

        playerAvailableCountForAvatar[player][avatarId] -= 1;

        emit gamePlayed(player, avatarId, vResult);

        return vResult;
    }

    function setAvatar(uint256 avatarId, uint256 price, uint256 reusableCount, uint256 winningProbability) public onlyOwner {
        if(avatars[avatarId].id == 0) {
            supply ++;
            maxid ++;
        }
        avatars[avatarId] = avatar(avatarId, reusableCount, winningProbability, price);
    }

    function delAvatar(uint256 avatarId) public onlyOwner {
        supply --;
        delete(avatars[avatarId]);
    }

    function totalSupply() external view returns(uint) {
        return supply;
    }

    function getMaxid() external view returns(uint) {
        return maxid;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        (bool success, ) = address(this).call{ value: balance }("");
        require(success, "Failed to withdraw FTM");
    }

    receive() external payable { }
}