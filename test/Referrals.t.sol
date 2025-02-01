// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "metamorpho-test/helpers/IntegrationTest.sol";
import {SendEarn} from "../src/SendEarn.sol";

contract ReferralsTest is IntegrationTest {
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

    function testReferral() public {
        assertEq(seVault.referrers(address(this)), address(0));
        seVault.setReferrer(address(this));
        assertEq(seVault.referrers(address(this)), address(this));
        seVault.setReferrer(address(0));
        assertEq(seVault.referrers(address(this)), address(0));
    }
}
