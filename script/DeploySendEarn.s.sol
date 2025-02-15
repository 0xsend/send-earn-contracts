// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

// solhint-disable no-console

import "../src/SendEarnFactory.sol";

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract DeploySendEarnScript is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        address platform = vm.envAddress("PLATFORM");
        uint96 fee = uint96(vm.envUint("FEE"));
        uint256 split = vm.envUint("SPLIT");

        vm.startBroadcast();
        SendEarnFactory factory = new SendEarnFactory(owner, vault, platform, fee, split, keccak256("SEND IT"));
        vm.stopBroadcast();

        console2.log("SendEarnFactory deployed to:", address(factory));
    }
}
