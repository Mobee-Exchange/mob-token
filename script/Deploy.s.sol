// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MobToken.sol";

contract DeployScript is Script {
    function run() external {
        // Retrieve private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        MobToken token = new MobToken(
            "Mobee Token", // name
            "MOB", // symbol
            500_000_000 // total supply
        );

        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("Token deployed to:", address(token));
    }
}
