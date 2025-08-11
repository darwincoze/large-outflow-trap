// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LargeOutflowTrap.sol";

contract DeployLargeOutflowTrap is Script {
    function run() external {
        vm.startBroadcast();

        LargeOutflowTrap trap = new LargeOutflowTrap();

        console.log("Trap deployed at:", address(trap));

        vm.stopBroadcast();
    }
}
