// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ResponseTrap.sol";

contract DeployResponseTrap is Script {
    function run() external {
        vm.startBroadcast();

        ResponseTrap responseTrap = new ResponseTrap(msg.sender);

        console.log("ResponseTrap deployed at:", address(responseTrap));

        vm.stopBroadcast();
    }
}
