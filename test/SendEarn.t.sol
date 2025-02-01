// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {SendEarn} from "../src/SendEarn.sol";
import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IERC4626, ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {IntegrationTest} from "metamorpho-test/helpers/IntegrationTest.sol";

contract SendEarnTest is IntegrationTest {
    // Contracts
    SendEarn public seVault;

    function setUp() public override {
        super.setUp();
        seVault = new SendEarn(
            OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol())
        );
    }

    function testSetup() public {
        assertEq(vault.name(), "MetaMorpho Vault");
        assertEq(vault.symbol(), "MMV");
        assertEq(address(vault.asset()), address(loanToken));
        assertEq(seVault.asset(), address(loanToken));
        assertEq(seVault.name(), "Send Earn: MetaMorpho Vault");
        assertEq(seVault.symbol(), "seMMV");
        assertEq(seVault.decimals(), 18);
        assertEq(seVault.totalAssets(), 0);
        assertEq(seVault.balanceOf(address(this)), 0);
        assertEq(seVault.convertToShares(1e18), 1e18);
        assertEq(seVault.convertToAssets(1e18), 1e18);
    }
    // TODO: Test basic deposit
    // TODO: Test deposit with referral
    // TODO: Test basic withdrawal
    // TODO: Test yield accrual
    // TODO: Test fee collection
    // TODO: Test referral fee distribution
    // TODO: Test owner-only functions
    // TODO: Test deposit of 0 assets
    // TODO: Test withdrawal exceeding balance
    // TODO: Implement deposit fuzz test
    // TODO: Implement withdraw fuzz test
    // TODO: Add invariant tests
}
