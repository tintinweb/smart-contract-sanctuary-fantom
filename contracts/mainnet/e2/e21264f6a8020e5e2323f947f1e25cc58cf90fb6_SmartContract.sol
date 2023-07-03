/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartContract {
    // Define a struct to represent a vehicle
    struct Vehicle {
        string id;
        uint256 speed;
        string[] route;
        string current_edge_id;
        uint256 route_index;
        string next_edge;
        string[] next_edge_vehicles;
    }

    // Define a mapping to store vehicle data by ID
    mapping (string => Vehicle) vehicles;

    // Function to retrieve vehicle data by ID
    function getVehicleSpeed(string memory id) public view returns (uint256) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.speed);
    }
    function getVehicleCurrentEdge(string memory id) public view returns (string memory) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.current_edge_id);
    }
    function getVehicleRoute(string memory id) public view returns (string[] memory) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.route);
    }
    function getVehicleRouteIndex(string memory id) public view returns (uint256) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.route_index);
    }
    function getVehicleNextEdge(string memory id) public view returns (string memory) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.next_edge);
    }
    function getVehicleNextEdgeVehicles(string memory id) public view returns (string[] memory) {
        Vehicle memory vehicle = vehicles[id];
        return (vehicle.next_edge_vehicles);
    }

    // Function to update vehicle data by ID
    function updateVehicleInfo(string memory id, uint256 speed,string[] memory route,string memory current_edge_id ,uint256 route_index,string memory next_edge,string[] memory next_edge_vehicles) public {
        Vehicle memory vehicle = Vehicle(id, speed,route,current_edge_id, route_index,next_edge,next_edge_vehicles);
        vehicles[id] = vehicle;
    }
}