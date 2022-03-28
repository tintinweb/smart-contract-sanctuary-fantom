// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Operator.sol";
import "./Token.sol";

contract Alpha is Context, Operator {

    enum State {READY,INPROGRESS}

    struct Instance {
        uint sizeAmount;
        bytes seed; 

        uint8 guess;
        bytes proof;
        bool completed;
    }

    Token immutable public tokenContract;

    address immutable public pubkey;

    address immutable public aContract;

    constructor(address _pubkey, Token _tokenContract) {
        pubkey = _pubkey;
        tokenContract = _tokenContract;
        aContract = address(this);
    }

    mapping (address=>Instance[]) private instances;

    function one(address account, uint amount, uint8 guess, bytes memory seed) external {
        require(_state(account) == State.READY, "not in correct state");
        require(_msgSender() == account || isOperator(), "caller is not operator");
        require(guess >= 1 && guess <= 3, "guess is out of bounds");
        tokenContract.transferFrom(account, aContract, amount);

        Instance memory b = Instance({
            sizeAmount: amount,
            completed: false,
            seed: seed,
            guess: guess,
            proof: bytes("0x0")
        });
        
        instances[account].push(b);
        uint currentGame = instances[account].length-1;
        emit One(account, currentGame, amount, guess, seed);
    }

    function two(address account, bytes memory proof) external onlyOperator {
        uint id = instances[account].length-1;

        Instance storage b = instances[account][id];
        require(b.completed == false, "already done");

        uint8 outcome = _proofToOutcome(proof);
        uint outSize = _outSize(b.sizeAmount);

        if (outcome == b.guess) {
            tokenContract.transferFrom(aContract, account, outSize);
        }

        b.completed = true;
        b.proof = proof;
        emit Two(account, id, proof, outSize);
    }

    function _proofToOutcome(bytes memory proof) private pure returns (uint8 outcome) {
        bytes32 hashed = sha256(abi.encodePacked(proof));
        uint256 number = uint256(hashed);

        uint mod = number % 150;

        if (mod >= 0 && mod <= 48) {
            return 1;
        } else if (mod >= 49 && mod <= 97) {
            return 2;
        } else if (mod >= 98 && mod <= 146) {
            return 3;
        } else if (mod >= 147 && mod <= 149) {
            return 0;
        }
        
        require(1==0, "Fatal");
    }

    function _outSize(uint sizeAmount) private pure returns (uint winAmount) {
        return sizeAmount * 3;
    }

    function _state(address account) private view returns (State) {
        uint iLength = instances[account].length;

        if (iLength == 0) {
            return State.READY;
        }
        
        Instance memory lastAccountI = instances[account][iLength-1];
        if (lastAccountI.completed == true) {
            return State.READY;
        } else {
            return State.INPROGRESS;
        }
    }

    function _previousProof(address account, uint id) private view returns (bytes memory) {
        if(id < 1) {
            bytes memory nothing;
            delete nothing;
            return nothing;
        } else {
            return instances[account][id-1].proof;
        }
    }

    function _validateSignature(bytes32, bytes memory) private pure returns (bool) {
        return true;
    }

    function verify(address account, uint id) external view returns (bool) {
        uint accountInstances = instances[account].length;
        if(accountInstances == 0) {
            return false;
        }
        
        if(id +1 > accountInstances) {
            return false;
        }
        if(id +1 == accountInstances && !instances[account][id].completed) {
            return false;
        }
        bytes memory accountSeed = instances[account][id].seed;
        bytes memory previousProof = _previousProof(account, id);        

        bytes memory proofToVerify = instances[account][id].proof;

        bytes32 signatureInput = keccak256(abi.encodePacked(aContract, account, accountSeed, previousProof));

        return _validateSignature(signatureInput, proofToVerify);
    }

    function history(address account) external virtual view returns (Instance[] memory) {
        return instances[account];
    }
    
    function state(address account) external virtual view returns (State) {
        return _state(account);
    }

    function info(address account, uint id) external virtual view returns (Instance memory) {
        return instances[account][id];
    }

    event One(address account, uint id, uint sizeAmount, uint8 guess, bytes seed);
    event Two(address account, uint id, bytes proof, uint outSize);

}