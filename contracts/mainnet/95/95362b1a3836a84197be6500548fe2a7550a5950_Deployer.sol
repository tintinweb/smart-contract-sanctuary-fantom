/**
 *Submitted for verification at FtmScan.com on 2022-02-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    uint public totalSupply;
    address public operator;
    address public pendingOperator;
    bool public transferable;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping (address => bool) public minters;
    mapping(address => bool) public recipientWhitelist;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        operator = msg.sender;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function setPendingOperator(address newOperator_) public onlyOperator {
        pendingOperator = newOperator_;
    }

    function claimOperator() public {
        require(msg.sender == pendingOperator, "ONLY PENDING OPERATOR");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit ChangeOperator(operator);
    }

    function addMinter(address minter_) public onlyOperator {
        minters[minter_] = true;
        emit AddMinter(minter_);
    }

    function removeMinter(address minter_) public onlyOperator {
        minters[minter_] = false;
        emit RemoveMinter(minter_);
    }

    function mint(address to, uint amount) public {
        require(minters[msg.sender] == true || msg.sender == operator, "ONLY MINTERS OR OPERATOR");
        _mint(to, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(transferable || recipientWhitelist[to], "Token is not transferrable and the recipient is not whitelisted!");
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function whitelist(address _recipient, bool _isWhitelisted) public onlyOperator {
        recipientWhitelist[_recipient] = _isWhitelisted;
        emit WhiteList(_recipient, _isWhitelisted);
    }

    function openTheGates() public onlyOperator {
        transferable = true;
    }

    // operator can seize tokens during the guarded launch only while tokens are non-transferable
    function seize(address _user, uint _amount) public onlyOperator {
        require(!transferable, "Cannot seize while token is transferable");
        _transfer(_user, address(0), _amount);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);
    event ChangeOperator(address indexed newOperator);
    event WhiteList(address indexed _recipient, bool _isWhitelisted);
}

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

contract Deployer {

    constructor(address _signer, address _operator) {
        // deploy contracts
        OresMinter oresMinter = new OresMinter(_signer, address(this));
        ERC20 halfinium = new ERC20("Halfinium", "HALF"); 
        ERC20 sangius = new ERC20("Sangius", "SAN");
        ERC20 shigerium = new ERC20("Shigerium", "SHI");
        ERC20 zisek = new ERC20("Zisek", "ZIS");

        // config contracts
        halfinium.addMinter(address(oresMinter));
        sangius.addMinter(address(oresMinter));
        shigerium.addMinter(address(oresMinter));
        zisek.addMinter(address(oresMinter));
        oresMinter.setDailyLimit(address(halfinium), 1000000 ether);
        oresMinter.setDailyLimit(address(sangius), 1000000 ether);
        oresMinter.setDailyLimit(address(shigerium), 1000000 ether);
        oresMinter.setDailyLimit(address(zisek), 1000000 ether);

        // transfer ownerships to operator
        oresMinter.changeOperator(_operator);
        halfinium.setPendingOperator(_operator);
        sangius.setPendingOperator(_operator);
        shigerium.setPendingOperator(_operator);
        zisek.setPendingOperator(_operator);
    }

}