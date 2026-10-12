// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import "forge-std/Script.sol";
import "../src/QuantumSafeVaultShowcase.sol";

contract DeployVaultShowcase is Script {
    function run() external {
        vm.startBroadcast();
        // lockLevel 1 = locks at first armed rung break (most conservative)
        QuantumSafeVaultShowcase vault = new QuantumSafeVaultShowcase(
            0x95E294817114673d33B7ba6463Eb245ca7cc8930,
            1
        );
        console2.log("QuantumSafeVaultShowcase:", address(vault));
        vm.stopBroadcast();
    }
}
