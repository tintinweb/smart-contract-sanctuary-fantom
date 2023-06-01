/**
 *Submitted for verification at FtmScan.com on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract GameOfLife {
    uint public width;
    uint public height;
    bool[][] public grid;
    
    event GridInitialized(uint width, uint height);
    event CellActivated(uint xCoord, uint yCoord);
    event NextIterationCompleted(bool[][] newGrid);

    constructor(uint _width, uint _height) {
        require(_width > 0 && _height > 0, "Width and height sizes must be greater than 0");
        width = _width;
        height = _height;
        grid = new bool[][](width);
        for (uint i = 0; i < width; i++) {
            grid[i] = new bool[](height);
        }
        emit GridInitialized(width, height);
    }
    
    function getGrid() public view returns (bool[][] memory) {
        return grid;
    }

    function activateCell(uint xCoord, uint yCoord) public {
        require(xCoord < width && yCoord < height, "Invalid coordinates");
        grid[xCoord][yCoord] = true;
        emit CellActivated(xCoord, yCoord);
    }

    function activateCells(uint[] memory xCoords, uint[] memory yCoords) public {
        require(xCoords.length == yCoords.length, "Coordinate arrays must have the same length");

        for (uint i = 0; i < xCoords.length; i++) {
            activateCell(xCoords[i], yCoords[i]);
        }
    }

    function nextIteration() public {
        bool[][] memory newGrid = new bool[][](width);
        for (uint i = 0; i < width; i++) {
            newGrid[i] = new bool[](height);
        }

        for (uint xCoord = 0; xCoord < width; xCoord++) {
            for (uint yCoord = 0; yCoord < height; yCoord++) {
                uint8 neighbors = countNeighbors(xCoord, yCoord);

                if (grid[xCoord][yCoord]) {
                    newGrid[xCoord][yCoord] = neighbors == 2 || neighbors == 3;
                } else {
                    newGrid[xCoord][yCoord] = neighbors == 3;
                }
            }
        }

        grid = newGrid;
        emit NextIterationCompleted(grid);
    }

    function countNeighbors(uint xCoord, uint yCoord) private view returns (uint8) {
        uint8 count = 0;
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                // Skip the current cell itself
                if (i == 0 && j == 0) continue;

                int newX = int(xCoord) + i;
                int newY = int(yCoord) + j;

                if (newX >= 0 && newY >= 0 && uint(newX) < width && uint(newY) < height && grid[uint(newX)][uint(newY)]) {
                    count++;
                }
            }
        }

        return count;
    }
}