// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {DeploySendEarnScript, Errors} from "../script/DeploySendEarn.s.sol";
import {SendEarnFactory} from "../src/SendEarnFactory.sol";
import {SendEarnTest} from "./helpers/SendEarn.t.sol";
import {IERC20Errors} from "openzeppelin-contracts/interfaces/draft-IERC6093.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract DeploySendEarnTest is SendEarnTest {
    DeploySendEarnScript internal deployScript;

    uint96 internal constant TEST_FEE = 0.08 ether; // 8%
    uint256 internal constant TEST_SPLIT = 0.75 ether; // 75%
    bytes32 internal constant TEST_SALT = bytes32(uint256(12345));
    uint256 internal constant TEST_INITIAL_BURN = 1e6; // 1 USDC (using loanToken decimals)
    uint256 internal constant TEST_INITIAL_BURN_PREFUND = 100e6; // 100 USDC (using loanToken decimals)

    function setUp() public override {
        super.setUp();

        deployScript = new DeploySendEarnScript();
    }

    function test_Revert_Deploy_InvalidAssetForBurn() public {
        // Use an invalid asset address (address(0))
        address invalidAssetAddress = address(0);

        // --- Predict Factory Address (CREATE2) ---
        bytes memory creationBytecode = abi.encodePacked(
            type(SendEarnFactory).creationCode,
            abi.encode(SEND_OWNER, address(vault), SEND_PLATFORM, TEST_FEE, TEST_SPLIT, TEST_SALT, TEST_INITIAL_BURN)
        );
        address predictedFactoryAddress = computeCreate2Address(TEST_SALT, keccak256(creationBytecode));

        vm.expectRevert(Errors.InvalidAssetAddress.selector);
        deployScript.deploySendEarn(
            predictedFactoryAddress,
            SEND_OWNER, // Use inherited owner
            address(vault), // Use inherited vault address
            SEND_PLATFORM, // Use inherited platform
            TEST_FEE,
            TEST_SPLIT,
            TEST_SALT,
            TEST_INITIAL_BURN, // Use a non-zero burn amount
            invalidAssetAddress, // Pass the invalid asset address
            TEST_INITIAL_BURN_PREFUND
        );
    }

    function test_Deploy_NoInitialBurn() public {
        uint256 noBurnAmount = 0;

        // --- Predict Factory Address (CREATE2) ---
        bytes memory creationBytecode = abi.encodePacked(
            type(SendEarnFactory).creationCode,
            abi.encode(SEND_OWNER, address(vault), SEND_PLATFORM, TEST_FEE, TEST_SPLIT, TEST_SALT, noBurnAmount)
        );
        address predictedFactoryAddress = computeCreate2Address(TEST_SALT, keccak256(creationBytecode));

        vm.expectRevert(); // reverts with "AlreadySet()" since initialBurn is already set to 0 by default
        deployScript.deploySendEarn(
            predictedFactoryAddress,
            SEND_OWNER,
            address(vault),
            SEND_PLATFORM,
            TEST_FEE,
            TEST_SPLIT,
            TEST_SALT,
            noBurnAmount, // Pass 0 for initial burn
            address(loanToken),
            TEST_INITIAL_BURN_PREFUND
        );
    }

    function test_Deploy_WithInitialBurn() public {
        // --- Predict Factory Address (CREATE2) ---
        bytes memory creationBytecode = abi.encodePacked(
            type(SendEarnFactory).creationCode,
            abi.encode(SEND_OWNER, address(vault), SEND_PLATFORM, TEST_FEE, TEST_SPLIT, TEST_SALT, TEST_INITIAL_BURN)
        );
        address predictedFactoryAddress =
            computeCreate2Address(TEST_SALT, keccak256(creationBytecode), address(deployScript));

        // --- Fund the deployer (the deploy script) using the inherited loanToken ---
        loanToken.mint(address(deployScript), TEST_INITIAL_BURN_PREFUND);
        vm.prank(address(deployScript));
        loanToken.approve(address(predictedFactoryAddress), TEST_INITIAL_BURN_PREFUND); // required for testing
        assertEq(loanToken.balanceOf(address(deployScript)), TEST_INITIAL_BURN_PREFUND, "Deployer funding failed");

        // --- Execute Deployment ---
        // The deploySendEarn function handles the pre-funding transfer internally
        (address factoryAddress, address sendEarnAddress) = deployScript.deploySendEarn(
            predictedFactoryAddress,
            SEND_OWNER,
            address(vault),
            SEND_PLATFORM,
            TEST_FEE,
            TEST_SPLIT,
            TEST_SALT,
            TEST_INITIAL_BURN,
            address(loanToken),
            TEST_INITIAL_BURN_PREFUND
        );

        assertEq(factoryAddress, predictedFactoryAddress, "Deployed address mismatch prediction");
        assertTrue(factoryAddress != address(0), "Factory address should not be zero");
        assertTrue(sendEarnAddress != address(0), "SendEarn address should not be zero");

        // Verify factory state
        SendEarnFactory factory = SendEarnFactory(factoryAddress);
        assertEq(factory.owner(), SEND_OWNER, "Factory owner mismatch");
        assertEq(factory.VAULT(), address(vault), "Factory vault mismatch");
        assertEq(factory.platform(), SEND_PLATFORM, "Factory platform mismatch");
        assertEq(factory.fee(), TEST_FEE, "Factory fee mismatch");
        assertEq(factory.split(), TEST_SPLIT, "Factory split mismatch");
        assertEq(factory.initialBurn(), TEST_INITIAL_BURN, "Factory initial burn amount mismatch");
        assertEq(factory.SEND_EARN(), sendEarnAddress, "Factory SEND_EARN address mismatch");

        // Verify burn occurred (factory balance should be 0) using inherited loanToken
        assertEq(
            loanToken.balanceOf(factoryAddress),
            TEST_INITIAL_BURN_PREFUND - TEST_INITIAL_BURN,
            "Factory balance should be 0 after burn"
        );
        assertGt(
            IERC20(sendEarnAddress).balanceOf(factoryAddress), 0, "Factory shares balance should be > 0 after burn"
        );
        // Verify deployer balance is also 0 (it transferred the funds)
        assertEq(loanToken.balanceOf(address(this)), 0, "Deployer balance should be 0 after transfer");
    }

    function test_Revert_Deploy_InsufficientBalanceForBurn() public {
        uint256 insufficientFundAmount = TEST_INITIAL_BURN_PREFUND / 2; // Less than required burn

        // --- Predict Factory Address (CREATE2) ---
        bytes memory creationBytecode = abi.encodePacked(
            type(SendEarnFactory).creationCode,
            abi.encode(SEND_OWNER, address(vault), SEND_PLATFORM, TEST_FEE, TEST_SPLIT, TEST_SALT, TEST_INITIAL_BURN)
        );
        address predictedFactoryAddress =
            computeCreate2Address(TEST_SALT, keccak256(creationBytecode), address(deployScript));

        // --- Fund the deployer (the deploy script) using the inherited loanToken ---
        loanToken.mint(address(deployScript), insufficientFundAmount);
        vm.prank(address(deployScript));
        loanToken.approve(address(predictedFactoryAddress), insufficientFundAmount); // require for testing
        assertEq(loanToken.balanceOf(address(deployScript)), insufficientFundAmount, "Deployer funding failed");

        // --- Expect Revert ---
        // The revert happens inside deploySendEarn when checking deployer balance
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                address(deployScript),
                insufficientFundAmount,
                TEST_INITIAL_BURN_PREFUND
            )
        );

        deployScript.deploySendEarn(
            predictedFactoryAddress,
            SEND_OWNER,
            address(vault),
            SEND_PLATFORM,
            TEST_FEE,
            TEST_SPLIT,
            TEST_SALT,
            TEST_INITIAL_BURN, // Attempting to burn more than funded
            address(loanToken),
            TEST_INITIAL_BURN_PREFUND
        );
    }
}
