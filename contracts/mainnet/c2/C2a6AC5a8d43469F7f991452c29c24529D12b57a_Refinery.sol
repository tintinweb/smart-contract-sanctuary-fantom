//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IERC20R {
    function transferFrom(address,address,uint256) external returns (bool);
    function burn(uint256) external;
}

interface IContDutchAuctionPair {
    function swap(uint256 x, uint256 minY, address to) external returns (uint256 y);
    function getY(uint256 x) external view returns (uint256);
}

contract Refinery {
    address public operator;
    address public pendingOperator;
    bool public paused;
    mapping(address => Ore) ores; // opt. address instead of strings
    mapping(address => mapping(address => address)) public oreMaterialPairAddress;
    

    struct Ore {
        address[] materials;
        uint256[] percentages;
    }

    constructor(
        address _operator
    ) {
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this function!");
        _;
    }

    function refineOre(uint256 _oreAmount, address _ore, uint256[] calldata _minY) public {
        require(paused == false, "Contract is paused!");
        require(_ore != address(0), "Ore doesn't exist");
        uint256 accumulatedOre;
        IERC20R(_ore).transferFrom(msg.sender, address(this), _oreAmount);
        for(uint256 i=0; i<ores[_ore].materials.length; i++) {
            uint256 xAmount;
            if(i == ores[_ore].materials.length - 1) { 
                xAmount = _oreAmount - accumulatedOre; // For percision of 100%
            } else {
                xAmount = (_oreAmount * ores[_ore].percentages[i])/100;
            }
            IContDutchAuctionPair(getPairAddress(_ore, ores[_ore].materials[i])).swap(xAmount, _minY[i], msg.sender);
            accumulatedOre += xAmount;
        }
        IERC20R(_ore).burn(_oreAmount);
    }

    function getMaterialsOut(uint256 _oreAmount, address _ore) public view returns(uint256[] memory) {
        uint256[] memory materialsOut = new uint256[](ores[_ore].materials.length);
        uint256 accumulatedOre;
        for(uint256 i=0; i<ores[_ore].materials.length; i++) {
            uint256 xAmount;
            if(i == ores[_ore].materials.length - 1) { 
                xAmount = _oreAmount - accumulatedOre; // For percision of 100%
            } else {
                xAmount = (_oreAmount * ores[_ore].percentages[i])/100;
            }
            materialsOut[i] = IContDutchAuctionPair(getPairAddress(_ore, ores[_ore].materials[i])).getY(xAmount);
            accumulatedOre += xAmount;
        }
        return materialsOut;
    }

    function setOre(address _ore, address[] calldata _materials, uint256[] calldata _percentages) public onlyOperator {
        ores[_ore].materials = _materials;
        ores[_ore].percentages = _percentages;
    }
    
    function setPair(address _addr, address _ore, address _material) public onlyOperator {
       oreMaterialPairAddress[_ore][_material] = _addr;
    }

    // getters
    function getPairAddress(address _ore, address _material) public view returns(address) {
        return oreMaterialPairAddress[_ore][_material];
    }

    function getOreMaterialsAndPercentages(address _name) public view returns(address[] memory, uint256[] memory) {
        return (ores[_name].materials , ores[_name].percentages);
    }

    function setPaused(bool _isPaused) public onlyOperator {
        paused = _isPaused;
        emit SetPaused(_isPaused);
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

    event SetPaused(bool);
    event ChangeOperator(address);
}