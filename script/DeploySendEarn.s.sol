// SPDX-License-Identifier: GPL-2.0-or-later
// solhint-disable one-contract-per-file
// solhint-disable no-console
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {SendEarnFactory} from "../src/SendEarnFactory.sol";

import "forge-std/Script.sol";
import "forge-std/console2.sol";

library Errors {
    error InvalidInitialBurn();
    error InvalidAssetAddress();
    error FactoryAddressMismatch();
    error FailedToBurn();
}

contract DeploySendEarnScript is Script {
    using SafeERC20 for IERC20;

    function run() external returns (address factoryAddress, address sendEarnAddress) {
        // --- Load Environment Variables ---
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        address platform = vm.envAddress("PLATFORM");
        uint96 fee = uint96(vm.envUint("FEE"));
        uint256 split = vm.envUint("SPLIT");
        bytes32 salt = vm.envBytes32("SALT");
        uint256 initialBurn = vm.envUint("INITIAL_BURN");
        uint256 initialBurnPrefund = vm.envUint("INITIAL_BURN_PREFUND");
        address assetAddress = vm.envAddress("ASSET");

        console2.log("--- Deployment Configuration ---");
        console2.log("Owner:", owner);
        console2.log("Vault:", vault);
        console2.log("Platform:", platform);
        console2.log("Fee:", fee);
        console2.log("Split:", split);
        console2.log("Salt:");
        console2.logBytes32(salt);
        console2.log("Initial Burn Amount:", initialBurn);
        console2.log("Initial Burn Prefund:", initialBurnPrefund);
        console2.log("Asset:", assetAddress);
        console2.log("-----------------------------");

        // --- Predict Factory Address (CREATE2) ---
        bytes memory creationBytecode = abi.encodePacked(
            type(SendEarnFactory).creationCode, abi.encode(owner, vault, platform, fee, split, salt, initialBurn)
        );
        address predictedFactoryAddress = vm.computeCreate2Address(salt, keccak256(creationBytecode));
        console2.log("Predicted Factory Address:", predictedFactoryAddress);

        vm.startBroadcast();
        (factoryAddress, sendEarnAddress) = deploySendEarn(
            predictedFactoryAddress,
            owner,
            vault,
            platform,
            fee,
            split,
            salt,
            initialBurn,
            assetAddress,
            initialBurnPrefund
        );
        vm.stopBroadcast();
    }

    function deploySendEarn(
        address predictedFactoryAddress,
        address owner,
        address vault,
        address platform,
        uint96 fee,
        uint256 split,
        bytes32 salt,
        uint256 initialBurn,
        address assetAddress,
        uint256 initialBurnPrefund
    ) public returns (address factoryAddress, address sendEarnAddress) {
        if (initialBurn == 0) {
            console2.log("Error: INITIAL_BURN must be set if > 0");
            revert Errors.InvalidInitialBurn();
        }

        if (assetAddress == address(0)) {
            console2.log("Error: ASSET must be set if INITIAL_BURN > 0");
            revert Errors.InvalidAssetAddress();
        }

        // -- Transfer Initial Burn Amount to Predicted Factory Address --
        IERC20 assetToken = IERC20(assetAddress);
        _preFundFactory(predictedFactoryAddress, initialBurnPrefund, assetToken);

        // --- Deploy Factory ---
        SendEarnFactory factory = new SendEarnFactory{salt: salt}(owner, vault, platform, fee, split, salt, initialBurn);

        // --- Verify Deployment ---
        if (address(factory) != predictedFactoryAddress) {
            console2.log("Error: Deployed factory address does not match predicted address!");
            revert Errors.FactoryAddressMismatch();
        }
        // --- Verify Initial Burn State ---
        if (IERC20(factory.SEND_EARN()).balanceOf(address(factory)) == 0) {
            console2.log("Error: Factory balance should not be 0 after burn.");
            revert Errors.FailedToBurn();
        }
        console2.log("SendEarnFactory deployed successfully to:", address(factory));
        console2.log("Platform SendEarn deployed to:", factory.SEND_EARN());

        factoryAddress = address(factory);
        sendEarnAddress = factory.SEND_EARN();
    }

    function _preFundFactory(address predictedFactoryAddress, uint256 initialBurn, IERC20 assetToken) internal {
        console2.log("Transferring initial burn amount to predicted factory address...");
        assetToken.safeTransfer(predictedFactoryAddress, initialBurn);
    }
}
