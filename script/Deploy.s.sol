// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {CreatorTokenFactory} from "../src/CreatorTokenFactory.sol";

contract DeployProductSystem is Script {
    function run() external returns (address) {
        // 1. Fetch parameters dynamically from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mockUsd = vm.envAddress("MOCK_USD_ADDRESS");
        address treasury = vm.envAddress("PROTOCOL_TREASURY");

        // Guardrails to prevent null-address initialization
        require(mockUsd != address(0), "Invalid Mock USD configuration");
        require(treasury != address(0), "Invalid Treasury configuration");

        console.log("Initializing deployment utilizing deployer signature...");

        // 2. Open signature broadcasting window
        vm.startBroadcast(deployerPrivateKey);

        // 3. System execution
        CreatorTokenFactory factory = new CreatorTokenFactory(
            mockUsd,
            treasury
        );

        console.log(
            "CreatorTokenFactory successfully deployed to:",
            address(factory)
        );

        // 4. Terminate execution lifecycle
        vm.stopBroadcast();

        return address(factory);
    }
}
