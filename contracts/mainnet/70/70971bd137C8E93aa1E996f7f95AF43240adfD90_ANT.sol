//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interfaces/IWorkerANT.sol";
import "./Interfaces/ISoldierANT.sol";
import "./Interfaces/IQueenANT.sol";
import "./Interfaces/ILarvaANT.sol";
import "./Interfaces/IMaleANT.sol";
import "./Interfaces/IPrincessANT.sol";
import "./Interfaces/IFunghiToken.sol";
import "./Interfaces/IFeromonToken.sol";
import "./Interfaces/IBuildingBlock.sol";

contract ANT {
    uint256 public immutable DECIMAL = 1e18;
    IWorkerANT public worker;
    ISoldierANT public soldier;
    IQueenANT public queen;
    ILarvaANT public larva;
    IMaleANT public male;
    IPrincessANT public princess;
    IFunghiToken public funghi;   
    IFeromonToken public feromon;
    IBuildingBlock public buildingblock;

    constructor(
        address _workerAddress,
        address _soldierAddress,
        address _queenAddress,
        address _larvaAddress,
        address _maleAddress,
        address _princessaddress,
        address _funghiaddress,
        address _feromonaddress,
        address _buildingblockaddress
        ){
        worker = IWorkerANT(_workerAddress);
        soldier = ISoldierANT(_soldierAddress);
        queen = IQueenANT(_queenAddress);
        larva = ILarvaANT(_larvaAddress);    
        male = IMaleANT(_maleAddress);
        princess = IPrincessANT(_princessaddress);      
        funghi = IFunghiToken(_funghiaddress);
        feromon = IFeromonToken(_feromonaddress);
        buildingblock = IBuildingBlock(_buildingblockaddress);
    }

    //larva actions
    function feedLarva(uint256 _food) public {
        uint256[] memory _larvaeList = larva.getLarvae();
        uint256 _amount = _food* larva.PORTION_FEE() * DECIMAL;
        uint256 _totalResource = larva.idToResource(0) + _food;
        require(_totalResource <= 9, "Larva is full.");
        funghi.transferFrom(msg.sender, address(this), _amount);
        larva.setResourceCount(_larvaeList[0], _totalResource);
        feromon.mint(_food * DECIMAL);
    }

    function hatch(uint256 _amount) public {
        uint256[] memory larvaeList;
        uint risk;
        uint chance;        
        for(uint j = 0; j < _amount; j++){
            larvaeList = larva.getLarvae();
            require(larvaeList.length > 0, "You don't have any more larva");
            risk = uint(
                keccak256(abi.encodePacked((block.number + j), block.timestamp)) ) % 100;
            chance = risk % (100 - larva.idToResource(larvaeList[0]) * 10);
            if (risk >= 5){
                if (chance < 6) {
                    if (larva.genesisCounter() < larva.MAX_GENESIS_MINT()){
                        queen.mint();
                        larva.burn(larvaeList[0]);
                    } else {
                        if (chance < 3){
                            male.mint();
                            larva.burn(larvaeList[0]);
                        } else {
                            princess.mint();
                            larva.burn(larvaeList[0]);
                        }
                    }            
                } else if (chance >= 6 && chance < 20) {
                    soldier.mint();
                    larva.burn(larvaeList[0]);
                } else if (chance >= 20 && chance < 100) {
                    uint256[] memory _unhousedWorkerList = worker.getUnHousedWorkers();
                    if(_unhousedWorkerList.length < 10 ){
                        worker.mint();
                        larva.burn(larvaeList[0]);
                    }
                }
            }
        }
        feromon.mint(_amount);
    }

    //Queen Actions
    function layEggs(uint256 _index) public {
        require(msg.sender == queen.ownerOf(_index), "You are not the owner.");
        uint256 fertilityWindow = block.timestamp - queen.idToTimestamp(_index);
        uint256 fertilityDays = fertilityWindow / 86400;
        uint256 noOfEggs;
        uint256 bonus = (queen.idToLevel(_index) - 1) * 3;
        fertilityDays >= 12 ? fertilityDays = 12 : fertilityDays = fertilityDays;
        for (uint i = 1; i <= fertilityDays; i++){
                uint256 eggsLaid = 6 + bonus - i;
                noOfEggs += eggsLaid; 
        }
        uint256 deservedEggs = noOfEggs-queen.idToEggs(_index);
        if (deservedEggs > 0){
            queen.setEggCount(_index, deservedEggs);
            larva.mint(deservedEggs);
            feromon.mint(deservedEggs * DECIMAL);
        }
   }

    function feedQueen(uint256 _index) public {
        uint256 fertilityWindow = block.timestamp - queen.idToTimestamp(_index);
        uint256 fertilityDays = fertilityWindow / 86400;
        fertilityDays = fertilityDays > 5 ? 5 : fertilityDays;
        uint256 _amount = fertilityDays * queen.PORTION_FEE() * DECIMAL;
        funghi.transferFrom(msg.sender, address(this), _amount);
        queen.setTimestamp(_index, block.timestamp);
        queen.resetEggCount(_index, 0);
        feromon.mint(fertilityDays * DECIMAL);
    }

    function queenLevelUp (uint256 _index) public{
        if(queen.idToLevel(_index) == 1){
            feromon.transferFrom(msg.sender, address(this), feromon.QUEEN_UPGRADE_FEE());
        } else if (queen.idToLevel(_index)==2) {
            feromon.transferFrom(msg.sender, address(this), feromon.QUEEN_UPGRADE_FEE() * 3);
        }
        queen.queenLevelup(_index);
    }

//Worker Functions
    function stakeWorker(uint256 _amount) public {
        uint256[] memory availableWorkerList = worker.getAvailableWorkers();
        require(_amount <= availableWorkerList.length);  
        for (uint i; i < _amount; i++){
            worker.setStaked(availableWorkerList[i], true);
            worker.setStakeDate(availableWorkerList[i], block.timestamp);
            worker.transferFrom(msg.sender, address(this),availableWorkerList[i]);
            feromon.mint(_amount * DECIMAL);
        }
    }
    
    function stakeProtectedWorker(uint256 _workerAmount) public {
        uint256[] memory availableWorkerList = worker.getAvailableWorkers();  
        uint256[] memory availableSoldierList = soldier.getAvailableSoldiers();            
        require(_workerAmount <= availableWorkerList.length); 
        require(_workerAmount<= availableSoldierList.length);

        for (uint i; i < _workerAmount; i++){
            worker.setStaked(availableWorkerList[i], true);
            worker.setStakeDate(availableWorkerList[i], block.timestamp);
            worker.transferFrom(msg.sender, address(this),availableWorkerList[i]);
            worker.setProtected(availableWorkerList[i], true);
            feromon.mint(_workerAmount * DECIMAL);
            
            infectionSpread();
            soldier.setStaked(availableSoldierList[i], true);
            soldier.setStakeDate(availableSoldierList[i], block.timestamp);
            soldier.transferFrom(msg.sender, address(this),availableSoldierList[i]);
            feromon.mint(_workerAmount * 2 * DECIMAL);
        }
    }

    function claimFunghi() public {
        uint256[] memory _workerList = worker.getWorkers();
        uint256[] memory _soldierList = soldier.getSoldiers();
        
        for(uint i; i < _workerList.length ; i++) {
            if (worker.idToStaked(_workerList[i]) &&
                worker.STAKE_DURATION() <= block.timestamp - worker.idToStakeDate(_workerList[i])){
                funghi.mint(DECIMAL);
                worker.setStaked(_workerList[i], false);
                worker.transferFrom(address(this), msg.sender, _workerList[i]);
                worker.reduceHP(_workerList[i]);
                if(worker.idToProtected(_workerList[i])){
                    worker.setProtected(_workerList[i], false);
                }
            }
        }
        for(uint i; i<_soldierList.length ; i++) {           
            if (soldier.idToStaked(_soldierList[i]) &&
                soldier.STAKE_DURATION() <= block.timestamp - soldier.idToStakeDate(_soldierList[i])){
                soldier.setStaked(_soldierList[i] , false);
                soldier.transferFrom(address(this), msg.sender, _soldierList[i]);
            }
        }
    }


    function sendWorkerToBuild(uint256 _amount) public {
        uint256[] memory availableWorkerList = worker.getAvailableWorkers();
        require(_amount <= availableWorkerList.length);  
        for (uint j = 0; j < _amount; j++){
            worker.setBuildMission(availableWorkerList[j], true);
            worker.setBuildDate(availableWorkerList[j], block.timestamp);
            worker.transferFrom(msg.sender, address(this), availableWorkerList[j]);
            feromon.mint(_amount * DECIMAL);
        }
    }    

    function claimBuildingBlock() public {
        uint256[] memory _workerList = worker.getWorkers();
        for(uint i; i<_workerList.length ; i++) {
            if (worker.idToOnBuildMission(_workerList[i]) &&
            worker.BUILD_DURATION() <= block.timestamp - worker.idToBuildDate(_workerList[i])){
                buildingblock.mint();
                worker.setBuildMission(_workerList[i] , false);
                worker.transferFrom(address(this), msg.sender, _workerList[i]);
                worker.reduceHP(_workerList[i]);    
            }    
        }
    }

    function convertFromWorkerToSoldier(uint256 _index) public{
        feromon.transferFrom(msg.sender, address(this), feromon.CONVERSION_FEE());  
        worker.burn(_index);
        soldier.mint();
    }

//Soldier Actions
    function sendSoldierToRaid(uint256 _amount) public {
        uint256[] memory availableSoldierList = soldier.getAvailableSoldiers();
        require(_amount <= availableSoldierList.length,"Not enough soldiers.");
        infectionSpread();  
        for (uint i; i < _amount; i++){
            soldier.setRaidMission(availableSoldierList[i], true);
            soldier.setRaidDate(availableSoldierList[i], block.timestamp);
            soldier.transferFrom(tx.origin, address(this),availableSoldierList[i]);
            feromon.mint(_amount * DECIMAL);
            soldier.increaseDamage(availableSoldierList[i]);
            infectionSpread(); //passive olanlar enfeksiyon yayıyor
        }
    }    

    function claimStolenLarvae() public {
        uint256[] memory _soldierList = soldier.getSoldiers();
        uint chance = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100; 

        for(uint i; i<_soldierList.length ; i++) {
            if (soldier.idToOnRaidMission(_soldierList[i]) &&
            soldier.RAID_DURATION() <= block.timestamp - soldier.idToRaidDate(_soldierList[i])){
                soldier.setRaidMission(_soldierList[i], false);
                soldier.transferFrom(address(this), tx.origin,_soldierList[i]);
                if (chance < 50){
                    larva.mint(1);
                }
            }
        }
    }

    function infectionSpread() public {
        uint256[] memory _soldierList = soldier.getSoldiers();
        uint256[] memory _zombieSoldierList = soldier.getZombieSoldiers();
        //her bir soldier'a zar atıyor, %1 ihtimalle damage artırıyor, 3 damage'lılara dokunmuyor
        for (uint256 i=0; i<_soldierList.length; i++){
            if (_zombieSoldierList.length>0){
                uint chance = uint(
                keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
            ) % 100;  
                if(chance<1 && soldier.idToPassive(_soldierList[i])==false &&
                soldier.idToDamageCount(_soldierList[i])<3){
                soldier.increaseDamage(_soldierList[i]);
                }                               
            }
        }
    }

    function healSoldier(uint256 _soldierAmount) public {
        uint256[] memory _soldierList = soldier.getSoldiers(); 
        uint256 _healedSoldiers;
        for(uint256 i = 0; i < _soldierList.length; i++){
            uint256 _soldierDamage = soldier.idToDamageCount(_soldierList[i]);
            if (_soldierDamage == 3) {
                funghi.transferFrom(msg.sender, address(this), soldier.HEALING_FEE() * DECIMAL);
                soldier.reduceDamage(_soldierList[i],3);
                _healedSoldiers++;
            }
        }
        if (_healedSoldiers <= _soldierAmount) {
            for(uint256 i = 0; i < _soldierList.length; i++){
                uint256 _soldierDamage = soldier.idToDamageCount(_soldierList[i]);
                if (_soldierDamage == 2) {
                    funghi.transferFrom(msg.sender, address(this), soldier.HEALING_FEE() * DECIMAL);
                    soldier.reduceDamage(_soldierList[i],2);
                    _healedSoldiers++;
                }
            }
        }
        if (_healedSoldiers <= _soldierAmount) {
            for(uint256 i = 0; i < _soldierList.length; i++){
                uint256 _soldierDamage = soldier.idToDamageCount(_soldierList[i]);
                if (_soldierDamage == 1) {
                    funghi.transferFrom(msg.sender, address(this), soldier.HEALING_FEE() * DECIMAL);
                    soldier.reduceDamage(_soldierList[i],1);
                    _healedSoldiers++;
                }
            }
        }
        feromon.mint(DECIMAL * _soldierAmount);
    }

    function claimPassiveSoldierReward() public {
        uint256[] memory _soldierList = soldier.getSoldiers();
        for(uint i; i<_soldierList.length ; i++) {
            if (soldier.idToDamageCount(_soldierList[i])==3 &&
            soldier.idToPassive(_soldierList[i])){
                funghi.burst();
                //burada NFTnin tipi değişmeli
            }
        }
    }

//Building Block Actions
    function houseWorkers (uint256 _index) public {
        uint256[] memory _homelessWorkers = worker.getUnHousedWorkers();
        uint256 _capacity = buildingblock.idToCapacity(_index);
        uint256 _homelessCount = _homelessWorkers.length;
        uint256[] memory _toBeHoused;
        if (_capacity >= _homelessCount) {
            _toBeHoused = new uint256[](_homelessCount);
            for (uint c = 0 ; c < _homelessCount; c++){
                worker.setHousing(_homelessWorkers[c], true);              
                _toBeHoused[c] = _homelessWorkers[c];
                buildingblock.reduceCapacity(_index);
            }
        } else {
            _toBeHoused = new uint256[](_capacity);
            for (uint c = 0 ; c < _capacity; c++){
                worker.setHousing(_homelessWorkers[c], true); 
                _toBeHoused[c] = _homelessWorkers[c];
                buildingblock.reduceCapacity(_index);
            }
        }
        buildingblock.houseWorkers(_index, _toBeHoused);
    }

    function mergeBBs () public {
        buildingblock.startConstruction();
    }

    function claimUpgradedBuilding () public {
        buildingblock.finishConstruction();
    }

    // Male Princess Actions
    function mateMalePrincess (uint256 _pairAmount) public {
        uint256[] memory _maleList = male.getMales();
        uint256[] memory _princessList = princess.getPrincesses();
        for (uint i; i< _pairAmount; i++){
            male.setMatingTime(_maleList[i]);
            princess.setMatingTime(_princessList[i]);
            princess.setMatingStatus(_princessList[i]);
            male.setMatingStatus(_maleList[i]);
        }
    }

    function claimQueen(uint256 _amount) public {
        //uint256 _timeElapsed = block.timestamp - male.idToMateTime(_maleIndex);
        uint256[] memory  _matedMales = male.getMatedMales();
        uint256[] memory _matedPrincesses = princess.getMatedPrincesses();
        require(_matedPrincesses.length<_amount, "No queens to claim.");
        for (uint i; i<_amount; i++){
            uint256 _timeElapsed2 = block.timestamp - princess.idToMateTime(_matedPrincesses[i]);
            if (_timeElapsed2>princess.MATE_DURATION()){
                male.burn(_matedMales[i]);
                princess.burn(_matedPrincesses[i]);
                queen.mint();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWorkerANT is IERC721{
    //variables
    function STAKE_DURATION() external view returns(uint256); 
    function BUILD_DURATION() external view returns(uint256);

    //functions
    function getWorkers() external view returns(uint256[] memory);
    function getAvailableWorkers() external view returns(uint256[] memory);
    function getUnHousedWorkers() external view returns(uint256[] memory);
    function setStaked(uint256 _index, bool _status) external;
    function setHousing(uint256 _index,  bool _status) external;
    function setProtected (uint256 _index, bool _status) external;
    function setBuildMission (uint256 _index, bool _status) external;
    function setHP (uint256 _index, uint256 _healthPoints) external;
    function setStakeDate (uint256 _index, uint256 _stakeDate) external;
    function setBuildDate (uint256 _index, uint256 _buildDate) external;
    function reduceHP (uint256 _index)  external;
    function burn(uint _index) external;
    function mint() external;
    
    //mappings
    function idToHealthPoints(uint256) external view returns(uint256);
    function idToStakeDate(uint256) external view returns(uint256);
    function idToBuildDate(uint256) external view returns(uint256);
    function idToStaked(uint256) external view returns(bool);
    function idToProtected(uint256) external view returns(bool);
    function idToHousing(uint256) external view returns(bool);
    function idToOnBuildMission(uint256) external view returns(bool);
    function playerToWorkers(address) external view returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISoldierANT is IERC721 {
    //variables
    function STAKE_DURATION() external view returns(uint256); 
    function RAID_DURATION() external view returns(uint256); 
    function HEAL_WINDOW() external view returns(uint256); 
    function HEALING_FEE() external view returns(uint256);
    
    //functions
    function getAvailableSoldiers() external view returns(uint256[] memory);
    function getZombieSoldiers() external view returns(uint256[] memory);
    function getInfectedSoldiers() external view returns(uint256[] memory);
    function getSoldiers() external view returns(uint256[] memory);
    function setStaked(uint256 _index, bool _status) external;
    function setRaidMission (uint256 _index, bool _status) external;
    function killSoldier (uint256 _index, bool _status) external;
    function setStakeDate (uint256 _index, uint256 _stakeDate) external;
    function setRaidDate (uint256 _index, uint256 _buildDate) external;
    function increaseDamage (uint256 _index)  external;
    function reduceDamage (uint256 _index, uint256 _damageReduced)  external;
    function mint() external;
    //mappings
    function idToDamageCount(uint256) external view returns(uint256);
    function idToStakeDate(uint256) external view returns(uint256);
    function idToFinalDamageDate(uint256) external view returns(uint256);
    function idToRaidDate(uint256) external view returns(uint256);
    function idToStaked(uint256) external view returns(bool);
    function idToOnRaidMission(uint256) external view returns(bool);
    function idToPassive(uint256) external view returns(bool);    
    function playerToSoldiers(address) external view returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IQueenANT is IERC721{
    //variables
    function FERTILITY_DURATION() external view returns(uint256);
    function PORTION_FEE() external view returns(uint256); 

    //functions
    function getQueens() external view returns(uint256[] memory);
    function setEggCount (uint256 _index, uint256 _eggCount) external;
    function resetEggCount (uint256 _index, uint256 _eggCount) external;
    function setTimestamp (uint256 _index, uint256 _timestamp) external;
    function queenLevelup (uint256 _index) external;
    function mint() external;

    //mappings
    function idToTimestamp(uint256) external view returns(uint256);
    function idToLevel(uint256) external view returns(uint256);
    function idToEggs(uint256) external view returns(uint256);
    function playerToQueens(address) external view returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILarvaANT is IERC721 {
    //variables
    function genesisCounter() external view returns(uint256);
    function PORTION_FEE() external view returns(uint256);
    function MAX_GENESIS_MINT() external view returns(uint256);
    function LARVA_PRICE() external view returns(uint256);
    function HATCH_DURATION() external view returns(uint256);
    function MAX_GENESIS_PER_TX() external view returns(uint256);
    //functions
    function getLarvae() external view returns(uint256[] memory);
    function genesisMint(uint256 amount) external payable;
    function setResourceCount(uint256 _index, uint256 _amount) external;
    function mint(uint256 _amount) external;
    function burn(uint256 _index) external;
    function drain() external;
    
    //mappings
    function idToSpawnTime(uint256) external view returns(uint256);
    function idToResource(uint256) external view returns(uint256);
    function playerToLarvae(address) external view returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMaleANT is IERC721{
    //variables
    function MATE_DURATION() external view returns(uint256);
    //functions
    function setMatingTime(uint256) external;
    function setMatingStatus(uint256 _index) external;
    function getMales() external view returns(uint256[] memory);
    function getMatedMales() external view returns(uint256[] memory);
    function mint() external;
    function burn(uint256) external;
    //mappings
    function idToMateTime(uint256) external view returns(uint256);
    function playerToMales(address) external view returns(uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPrincessANT is IERC721{
    //variables
    function MATE_DURATION() external view returns(uint256);
    //functions
    function setMatingTime(uint256) external;
    function setMatingStatus(uint256 _index) external;
    function getPrincesses() external view returns(uint256[] memory);
    function getMatedPrincesses() external view returns(uint256[] memory);
    function mint() external;
    function burn(uint256) external;
    //mappings
    function idToMateTime(uint256) external view returns(uint256);
    function playerToPrincesses(address) external view returns(uint256[] memory);
    function idToVirginity(uint256) external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFunghiToken is IERC20{
    //functions
    function mint(uint256) external;
    function burst() external;
    //mappings

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeromonToken is IERC20{
    //vars
    function CONVERSION_FEE() external view returns(uint256);
    function QUEEN_UPGRADE_FEE() external view returns(uint256);

    //functions
    function mint(uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuildingBlock {
    //functions
    function getBuildingBlocks() external view returns(uint256[] memory);
    function getActiveBuildingBlocks() external view returns(uint256[] memory);
    function getPassiveBuildingBlocks() external view returns(uint256[] memory);
    function getWorkersHoused(uint256 _index) external view returns(uint256[] memory);
    function houseWorkers(uint256 _index,uint256[] memory _workersToBeHoused) external;
    function startConstruction () external;
    function finishConstruction () external;
    function increaseLevel(uint256 _index)  external; 
    function reduceCapacity(uint256 _index)  external;
    function increaseCapacity(uint256 _indexToEnlarge,uint256 _amount)  external;
    function mint() external;
    //mappings
    function idToConstructionTime(uint256) external view returns(uint256);
    function idToLevel(uint256) external view returns(uint256);
    function idToCapacity(uint256) external view returns(uint256);
    function idToCumulativeCapacity(uint256) external view returns(uint256);
    function idToActive(uint256) external view returns(bool);
    function idToFull(uint256) external view returns(bool);
    function idToWorkers(uint256) external view returns(uint256[] memory);
    function playerToBuildingBlocks(address) external view returns(uint256[] memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}