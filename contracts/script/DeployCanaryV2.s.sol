// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import "forge-std/Script.sol";
import "../src/QuanthoodCanaryV2.sol";

contract DeployCanaryV2 is Script {
    function run() external {
        string memory json = vm.readFile("deploy-args-canary.json");
        uint256[2][12] memory pubkeys;
        bool[12] memory armed;
        uint256[12] memory bits;
        for (uint256 i = 0; i < 12; i++) {
            pubkeys[i][0] = vm.parseJsonUint(json, string(abi.encodePacked(".pubkeys[", vm.toString(i), "][0]")));
            pubkeys[i][1] = vm.parseJsonUint(json, string(abi.encodePacked(".pubkeys[", vm.toString(i), "][1]")));
            armed[i] = vm.parseJsonBool(json, string(abi.encodePacked(".armed[", vm.toString(i), "]")));
            bits[i] = vm.parseJsonUint(json, string(abi.encodePacked(".bits[", vm.toString(i), "]")));
        }
        vm.startBroadcast();
        // 180-day refund lock per rung (from each rung's first funding)
        QuanthoodCanaryV2 canary = new QuanthoodCanaryV2(
            0x95E294817114673d33B7ba6463Eb245ca7cc8930,
            pubkeys,
            armed,
            bits,
            180 days
        );
        console2.log("QuanthoodCanaryV2:", address(canary));
        vm.stopBroadcast();
    }
}
