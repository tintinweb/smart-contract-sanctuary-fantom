/**
 *Submitted for verification at FtmScan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERCXXX {
    
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external pure returns(uint); // 0

    function totalSupply() external view returns(uint);

    function cumulativeBalanceOf(address account) external view returns(uint);

    function fragmentsBalanceOf(address account) external  view returns(uint[] memory start, uint[] memory length);

    function realFragmentsBalanceOf(address account) external view returns(uint[] memory start, uint[] memory length);

    function transfer(address to, uint _sector_start, uint _sector_length) external;

    function defragmaentation() external;

    function allowance(address _owner, address spender) external view returns(uint _start, uint _length);

    function approve(address spender, uint _start, uint _length) external;

    function transferFrom(address from, address to, uint _sector_start, uint _sector_length ) external;

}

contract One_dimentional_NFT is IERCXXX {
    uint totalTokens;
    address owner;
    mapping(address => uint[]) sector_start;
    mapping(address => uint[]) sector_length;

    mapping(address => mapping(address => uint)) allowances_start;
    mapping(address => mapping(address => uint)) allowances_length;
    string _name;
    string _symbol;

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external pure returns(uint) {
        return 18; 
    }

    function totalSupply() external view returns(uint) {
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint _sector_start, uint _sector_length) {
       bool enough=false;
       uint l1 = sector_start[_from].length;

        for(uint i = 0; i < l1 ; i += 1) {
             if ( sector_start[_from][i]<=_sector_start && sector_start[_from][i]+sector_length[_from][i]>=_sector_start+_sector_length ) {
              enough=true;
              break;   
             }
        }
       require(enough && _sector_length != 0, "not enough tokens!");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint _sector_start, uint _sector_length) {
        _name = name_;
        _symbol = symbol_;
        owner=msg.sender;
        mint(_sector_start, _sector_length, msg.sender);
    }

    function cumulativeBalanceOf(address account) public view returns(uint) {
        uint balance;
        uint l = sector_start[account].length;
    
        for(uint i = 0; i < l ; i += 1) {
            if (sector_length[account][i] !=0 ) {
                 balance+=sector_length[account][i];
                  }
        }
        return balance;
    }

    function fragmentsBalanceOf(address account) public view returns(uint[] memory start, uint[] memory length)  {
         uint l = sector_start[account].length;
         uint k=0;
         uint temp=0;

            for(uint j = 0; j < l ; j += 1) {
             if ( sector_length[account][j] == 0) { temp++; }
            // if ( sector_length[account][l-j-1] != 0) { break; }   // if there is some null regions?
            }

         start = new uint[](l-temp);
         length = new uint[](l-temp);
 
         for(uint i = 0; i < l ; i += 1) {
            if (sector_length[account][i] !=0 ) {
               start[k]=sector_start[account][i];
               length[k]=sector_length[account][i];
               k++;               
            }
        }
    return(start, length);
    }

    function realFragmentsBalanceOf(address account) public view returns(uint[] memory start, uint[] memory length)  {
         uint l = sector_start[account].length;
         uint k=0;

         start = new uint[](l);
         length = new uint[](l);
 
         for(uint i = 0; i < l ; i += 1) {     
               start[k]=sector_start[account][i];
               length[k]=sector_length[account][i];
               k++;               
        }
    return(start, length);
    }

    function mint(uint _sector_start, uint _sector_length, address user) internal  {
        sector_start[user].push(_sector_start);
        sector_length[user].push(_sector_length);
        totalTokens+= _sector_length;
    }
 
    function allowance(address _owner, address spender) public view returns(uint _start, uint _length) {
        _start = allowances_start[_owner][spender];
        _length = allowances_length[_owner][spender];
        return(_start, _length);
    }

    function approve(address spender, uint _start, uint _length) public {
        allowances_start[msg.sender][spender] = _start;
        allowances_length[msg.sender][spender] = _length;
    }

    function defragmaentation() external {
        uint l = sector_start[msg.sender].length;
        uint temp=0;

        for(uint k = 0; k < l ; k+= 1) {
            for(uint n = 0; n < l ; n+= 1) {
                if ( (sector_start[msg.sender][k]+sector_length[msg.sender][k] == sector_start[msg.sender][n] ) && (k != n) && sector_start[msg.sender][n] != 0) {
                    sector_length[msg.sender][k]+=sector_length[msg.sender][n];
                    sector_start[msg.sender][n]=0;
                    sector_length[msg.sender][n]=0;
                }
            }
        }

        for(uint j = 0; j < l ; j += 1) {
            if ( sector_length[msg.sender][l-j-1] == 0) { temp++; }
            if ( sector_length[msg.sender][l-j-1] != 0) { break; }  
        }

        for(uint i = 0; i < l ; i += 1) {
            if ( i >= (l-temp) )  {  break; }

            if (sector_length[msg.sender][i] == 0 && temp < l)  { 
                
                 sector_start[msg.sender][i]=sector_start[msg.sender][l-temp-1];  
                 sector_length[msg.sender][i]=sector_length[msg.sender][l-temp-1];
                 sector_start[msg.sender][l-temp-1]=0;
                 sector_length[msg.sender][l-temp-1]=0;
                 temp++;

                 for(uint ti = 0; ti < l-temp ; ti += 1)  {
                     if (sector_length[msg.sender][l-temp-1-ti] ==0 ) {  temp++;  }
                     if (sector_length[msg.sender][l-temp-1-ti] !=0 ) {  break;  }
                 }

            }
        }
    }

    function transfer(address to, uint _sector_start, uint _sector_length) public enoughTokens(msg.sender, _sector_start, _sector_length) {

        uint l = sector_start[msg.sender].length;
        uint temp1;
        uint temp2;
        uint tempi;
        bool intermediate=false;

        uint temp=0;
        for(uint j = 0; j < l ; j += 1) {
            if ( sector_length[msg.sender][l-j-1] == 0) { temp++; }
            if ( sector_length[msg.sender][l-j-1] != 0) { break; }
        }

        for(uint i = 0; i < (l-temp) ; i += 1) {


            if ( sector_start[msg.sender][i] == _sector_start ) {
                if (sector_length[msg.sender][i]==_sector_length) {
                    sector_start[msg.sender][i]=0;
                    sector_length[msg.sender][i]=0;
                    break;
                }

                if (sector_length[msg.sender][i] > _sector_length) { 
                    sector_start[msg.sender][i]=_sector_start+_sector_length;
                    sector_length[msg.sender][i]-=_sector_length;
                    break;
                }
            }


            if ( sector_start[msg.sender][i]<_sector_start ) {

               if ( sector_start[msg.sender][i]+sector_length[msg.sender][i] == _sector_start+_sector_length) {
                   sector_length[msg.sender][i]= _sector_start - sector_start[msg.sender][i];
                   break;
               }

                if ( sector_start[msg.sender][i]+sector_length[msg.sender][i] > _sector_start+_sector_length) {   
    
                      intermediate=true; 
                      tempi=i;
                      temp1=sector_start[msg.sender][i] + sector_length[msg.sender][i] - (_sector_start + _sector_length);
                      temp2=_sector_start + _sector_length;
                      break;
                }                                  
            }              
        }

        if (intermediate) {
            sector_length[msg.sender][tempi]= _sector_start - sector_start[msg.sender][tempi];
            sector_start[msg.sender].push(temp2);
            sector_length[msg.sender].push(temp1);
        }

        sector_start[to].push(_sector_start);
        sector_length[to].push(_sector_length);

    }

    function transferFrom(address from, address to, uint _sector_start, uint _sector_length ) public  {

        bool enough=false;
        uint l1 = sector_start[from].length;
        for(uint j = 0; j < l1 ; j += 1) {
             if ( sector_start[from][j]<=_sector_start && sector_start[from][j]+sector_length[from][j]>=_sector_start+_sector_length ) {
              enough=true;
              break;   
            }
        }
        require(enough && _sector_length != 0, "not enough tokens!");
        
        require( (allowances_start[from][msg.sender] == _sector_start) && (allowances_length[from][msg.sender] == _sector_length), "check allowance!");
        allowances_start[from][msg.sender] = 0; 
        allowances_length[from][msg.sender] = 0;         
        sector_start[to].push(_sector_start);
        sector_length[to].push(_sector_length);

        uint l = sector_start[from].length;
        uint temp1;
        uint temp2;
        uint tempi;
        bool intermediate=false;

        for(uint i = 0; i < l ; i += 1) {
            if ( sector_start[from][i] == _sector_start ) {
                if (sector_length[from][i]==_sector_length) {
                    sector_start[from][i]=0;
                    sector_length[from][i]=0;
                    break;
                }
                if (sector_length[from][i] > _sector_length) { 
                    sector_start[from][i]=_sector_start+_sector_length;
                    sector_length[from][i]-=_sector_length;
                    break;
                }
            }

            if ( sector_start[from][i]<_sector_start ) {
               if ( sector_start[from][i]+sector_length[from][i] == _sector_start+_sector_length) {
                   sector_length[from][i]= _sector_start - sector_start[from][i];
                   break;
               }

                if ( sector_start[from][i]+sector_length[from][i] > _sector_start+_sector_length) {                                            
                      intermediate=true; 
                      tempi=i;
                      temp1=sector_start[from][i] + sector_length[from][i] - (_sector_start + _sector_length);
                      temp2=_sector_start + _sector_length;              
                       break;
                   }                                
            }                           
        }

                if (intermediate) {
                    sector_length[from][tempi]= _sector_start - sector_start[from][tempi];
                    sector_start[from].push(temp2);
                    sector_length[from].push(temp1);
                }

    }

    receive() external payable {  
        payable(owner).transfer(msg.value);
    }

}