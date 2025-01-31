// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {SendEarn} from "../src/SendEarn.sol";
import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IERC4626, ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract SendEarnTest is Test {
    // Constants
    uint256 constant INITIAL_BALANCE = 1000000e6; // 1M USDC
    uint256 constant DEPOSIT_AMOUNT = 10000e6; // 10k USDC

    // Contracts
    SendEarn public vault;
    MockERC20 public usdc;
    // MockMoonwellVault public moonwellVault;

    // Users
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");

    function setUp() public {
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy mock Moonwell vault
        // moonwellVault = new MockMoonwellVault(
        //     address(usdc),
        //     "Moonwell USDC",
        //     "mwUSDC"
        // );

        // Deploy SendEarn
        vault = new SendEarn(
            admin,
            address(0x0), // TODO: Replace with Moonwell address
            address(usdc),
            "Send Earn USDC",
            "seUSDC"
        );

        // Setup initial balances
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(carol, INITIAL_BALANCE);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(carol);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    function test_initialization() public view {
        assertEq(vault.name(), "Send Earn USDC");
        assertEq(vault.symbol(), "seUSDC");
        assertEq(address(vault.MOONWELL_VAULT()), address(0x0)); // TODO: Replace with Moonwell address
        assertEq(address(vault.asset()), address(usdc));
    }

    function test_deposit() public {
        vm.startPrank(alice);
        // TODO: Test basic deposit
        vm.stopPrank();
    }

    function test_depositWithReferral() public {
        vm.startPrank(alice);
        // TODO: Test deposit with referral
        vm.stopPrank();
    }

    function test_withdraw() public {
        // TODO: Test basic withdrawal
    }

    function test_accrueYield() public {
        // TODO: Test yield accrual
    }

    function test_feeCollection() public {
        // TODO: Test fee collection
    }

    function test_referralFeeDistribution() public {
        // TODO: Test referral fee distribution
    }

    // Access Control Tests
    function test_onlyOwner() public {
        // TODO: Test owner-only functions
    }

    // Failure Cases
    function testFail_depositZero() public {
        // TODO: Test deposit of 0 assets
    }

    function testFail_withdrawMoreThanBalance() public {
        // TODO: Test withdrawal exceeding balance
    }

    // Fuzz Tests
    function testFuzz_deposit(uint256 amount) public {
        // TODO: Implement deposit fuzz test
    }

    function testFuzz_withdraw(uint256 amount) public {
        // TODO: Implement withdraw fuzz test
    }

    // TODO: Add invariant tests
}
