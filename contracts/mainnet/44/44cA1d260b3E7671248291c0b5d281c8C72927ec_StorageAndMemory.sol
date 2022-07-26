/**
 *Submitted for verification at FtmScan.com on 2022-07-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract StorageAndMemory {
    struct Items {
        uint a;
        uint b;
        uint c;
        uint d;
        uint e;
        string f;
        string g;
        string h;
        string i;
        string j;
    }

    mapping(uint8 => Items) public items;

    uint256 public counter;

    constructor() {
        items[1] = Items(1,2,3,4,5,"start","stop","go","now","please");
    }

    function usingStorage1() public {
        items[1].a = 4;
        items[1].b = 3;
        items[1].c = 2;
        items[1].d = 1;
        items[1].e = 4;
        items[1].f = "start";
        items[1].g = "stop";
        items[1].h = "go";
        items[1].i = "now";
        items[1].j = "please";

    }
    function usingMemory1() public {
        Items memory item = items[1];
        item.a = 4;
        item.b = 3;
        item.c = 2;
        item.d = 1;
        item.e = 2;
        item.f = "start";
        item.g = "stop";
        item.h = "go";
        item.i = "now";
        item.j = "please";
        items[1] = item;
    }
    
    function usingStorage2() public {
        items[1].a = 4;
        items[1].b = 3;
        items[1].c = 2;
        items[1].g = "start";
        items[1].h = "go";
    }

    function usingMemory2() public {
        Items memory item = items[1];
        item.a = 4;
        item.b = 3;
        item.c = 2;
        item.g = "start";
        item.h = "go";

        items[1] = item;
    }

    function accessStorageInLoop(uint number) public {
        for(uint i = 0; i < number; i++){
            counter++;
        }
    }

    function accessMemoryInLoop(uint number) public {
        uint256 _counter = counter;
        for(uint i = 0; i < number; i++){
            _counter++;
        }
        counter  = _counter;
    }
}