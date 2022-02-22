/**
 *Submitted for verification at FtmScan.com on 2022-02-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IOre {
    function mint(address to, uint amount) external;
}

contract OresMinter {
    address public signer;
    address public operator;
    bool public paused;

    mapping(address => uint) public oreDailyLimit;
    // ore => day# => amount minted
    mapping(address => mapping(uint => uint)) public oreDailyMinted;
    // ore => user => withdrawn
    mapping(address => mapping(address => uint)) public oreUserWithdrawn;

    constructor(
        address _signer,
        address _operator
    ) {
        operator = _operator;
        signer = _signer;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this function!");
        _;
    }

    // getters
    function getAllowedDailyMint(address _ore) public view returns (uint) {
        return oreDailyLimit[_ore] - oreDailyMinted[_ore][block.timestamp / 24 hours];
    }

    // used to add ore or change its existing daily limit
    function setDailyLimit(address _ore, uint _limit) public onlyOperator {
        oreDailyLimit[_ore] = _limit;
        emit SetDailyLimit(_ore, _limit);
    }

    function mintOre(address[] calldata _ores, uint[] calldata _amounts, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(!paused, "Contract is paused!");
        require(_ores.length == _amounts.length, "Arrays not equal!"); // Sanity
        bytes32 _hash = keccak256(abi.encodePacked(_ores, _amounts, msg.sender, address(this), block.chainid));
        require(ecrecover(_hash, _v, _r, _s) == signer, "Signature is not valid!");
        for(uint i=0; i < _ores.length; i++) {
            uint withdrawableAmount = _amounts[i] - oreUserWithdrawn[_ores[i]][msg.sender];
            require(getAllowedDailyMint(_ores[i]) >= withdrawableAmount);
            oreDailyLimit[_ores[i]] += withdrawableAmount;
            oreUserWithdrawn[_ores[i]][msg.sender] += withdrawableAmount;
            IOre(_ores[i]).mint(msg.sender, withdrawableAmount);
        }
    }

    function changeOperator(address _newOperator) public onlyOperator {
        operator = _newOperator;
        emit ChangeOperator(_newOperator);
    }

    function changeSigner(address _newSigner) public onlyOperator {
        signer = _newSigner;
        emit ChangeSigner(_newSigner);
    }

    function setPaused(bool _isPaused) public onlyOperator {
        paused = _isPaused;
        emit SetPaused(_isPaused);
    }

    event SetDailyLimit(address, uint);
    event ChangeOperator(address);
    event ChangeSigner(address);
    event SetPaused(bool);
}