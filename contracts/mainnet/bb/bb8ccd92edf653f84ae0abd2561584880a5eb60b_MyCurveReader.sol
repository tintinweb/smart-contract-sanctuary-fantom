/**
 *Submitted for verification at FtmScan.com on 2022-11-24
*/

pragma solidity ^0.8.12;
// SPDX-License-Identifier: NLPL

contract MyCurveReader {
    
    function sort(uint[] memory A0) public pure returns (uint[] memory A) {
        uint N_COINS = A0.length;
        
        A = A0;
        for (uint i = 1; i < N_COINS; i++) {
            uint x = A[i];
            uint cur = i;
            for (uint j = 0; j < N_COINS; j++) {
                uint y = A[cur-1];
                if (y > x) {
                    break;
                }
                A[cur] = y;
                cur -= 1;
                if (cur == 0) {
                    break;
                }                    
            }
            A[cur] = x;
        }
        return A;
    }

    function max(uint a, uint b) public pure returns (uint) {
        if (a > b) {
            return a;
        }
        return b;
    }
    
    uint constant A_MULTIPLIER = 10000;

    function newton_y(uint ANN, uint gamma, uint[] memory x, uint D, uint i) public pure returns (uint, uint[] memory) {

        uint[] memory results = new uint[](200);
        uint[] memory ALL_VARS = new uint[](200);

        uint RINDEX = 0;

        ALL_VARS[0] = x.length;
        ALL_VARS[2] = 10**18;
        ALL_VARS[3] = 0;

        ALL_VARS[31] = ANN;
        ALL_VARS[32] = gamma;
        ALL_VARS[33] = D;
        ALL_VARS[34] = i;

        ALL_VARS[99] = ALL_VARS[33] / ALL_VARS[0];

        uint[] memory x_sorted = x;
        x_sorted[i] = 0;
        x_sorted = sort(x_sorted);
        
        uint convergence_limit = max(max(x_sorted[0] / 10**14, ALL_VARS[33] / 10**14), 100);

        results[RINDEX++] = ALL_VARS[31]; // debugging
        results[RINDEX++] = ALL_VARS[32]; // debugging
        results[RINDEX++] = ALL_VARS[33]; // debugging
        results[RINDEX++] = ALL_VARS[34]; // debugging
        results[RINDEX++] = convergence_limit; // debugging

        for (uint j = 2; j < ALL_VARS[0]+1; j++)
        {
            uint _x = x_sorted[ALL_VARS[0]-j];
            ALL_VARS[99] = ALL_VARS[99] * D / (_x * ALL_VARS[0]);
            ALL_VARS[3] += _x;
            results[RINDEX++] = j; // debugging
            results[RINDEX++] = ALL_VARS[99]; // debugging
            results[RINDEX++] = ALL_VARS[3]; // debugging
        }

        for (uint j = 0; j < ALL_VARS[0]-1; j++)
        {
            ALL_VARS[2] = ALL_VARS[2] * x_sorted[j] * ALL_VARS[0] / ALL_VARS[33];
            results[RINDEX++] = j; // debugging
            results[RINDEX++] = ALL_VARS[2]; // debugging
        }
        
        for (uint j = 0; j < 255; j++)
        {

            ALL_VARS[4] = ALL_VARS[99];
            ALL_VARS[20] = ALL_VARS[2] * ALL_VARS[99] * ALL_VARS[0] / ALL_VARS[33];
            ALL_VARS[21] = ALL_VARS[3] + ALL_VARS[99];

            ALL_VARS[5] = ALL_VARS[32] + 10**18;
            if (ALL_VARS[5] > ALL_VARS[20]) {
                ALL_VARS[5] = ALL_VARS[5] - ALL_VARS[20] + 1;
            } else {
                ALL_VARS[5] = ALL_VARS[20] - ALL_VARS[5] + 1;
            }                

            results[RINDEX++] = j; // debugging
            results[RINDEX++] = ALL_VARS[4]; // debugging
            results[RINDEX++] = ALL_VARS[20]; // debugging
            results[RINDEX++] = ALL_VARS[21]; // debugging
            results[RINDEX++] = ALL_VARS[5]; // debugging

            ALL_VARS[6] = 10**18 * ALL_VARS[33] / ALL_VARS[32] * ALL_VARS[5] / ALL_VARS[32] * ALL_VARS[5] * A_MULTIPLIER / ALL_VARS[31];
            ALL_VARS[7] = 10**18 + (2 * 10**18) * ALL_VARS[20] / ALL_VARS[5];
            ALL_VARS[8] = 10**18 * ALL_VARS[99] + ALL_VARS[21] * ALL_VARS[7] + ALL_VARS[6];
            ALL_VARS[9] = ALL_VARS[33] * ALL_VARS[7];

            if (ALL_VARS[8] < ALL_VARS[9]) {
                ALL_VARS[99] = ALL_VARS[4] / 2;
                continue;
            } else {
                ALL_VARS[8] -= ALL_VARS[9];
            }
                
            results[RINDEX++] = ALL_VARS[6]; // debugging
            results[RINDEX++] = ALL_VARS[7]; // debugging
            results[RINDEX++] = ALL_VARS[8]; // debugging
            results[RINDEX++] = ALL_VARS[9]; // debugging

            ALL_VARS[23] = ALL_VARS[8] / ALL_VARS[99];
            ALL_VARS[24] = ALL_VARS[6] / ALL_VARS[23];
            ALL_VARS[25] = (ALL_VARS[8] + 10**18 * D) / ALL_VARS[23] + ALL_VARS[24] * 10**18 / ALL_VARS[20];
            ALL_VARS[24] += 10**18 * ALL_VARS[21] / ALL_VARS[23];

            if (ALL_VARS[25] < ALL_VARS[24]) {
                ALL_VARS[99] = ALL_VARS[4] / 2;
            } else {
                ALL_VARS[99] = ALL_VARS[25] - ALL_VARS[24];
            }                

            results[RINDEX++] = ALL_VARS[23]; // debugging
            results[RINDEX++] = ALL_VARS[24]; // debugging
            results[RINDEX++] = ALL_VARS[25]; // debugging
            results[RINDEX++] = ALL_VARS[99]; // debugging

            ALL_VARS[36] = 0;
            if (ALL_VARS[99] > ALL_VARS[4]) {
                ALL_VARS[36] = ALL_VARS[99] - ALL_VARS[4];
            } else {
                ALL_VARS[36] = ALL_VARS[4] - ALL_VARS[99];
            }

            if (ALL_VARS[36] < max(convergence_limit, ALL_VARS[99] / 10**14)) {
                results[RINDEX++] = ALL_VARS[99];
                return (ALL_VARS[99], results);
            }

        }
        revert("Did not converge");
    }
}