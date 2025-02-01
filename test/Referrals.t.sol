// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {Events} from "../src/lib/Events.sol";
contract ReferralsTest is SendEarnTest {
    function testSetFeeReferrer(address referrer) public {
        referrer = _boundAddressNotZero(referrer);

        vm.expectEmit(address(seVault));
        emit Events.SetReferrer(SUPPLIER, referrer);
        vm.prank(SUPPLIER);
        seVault.setReferrer(referrer);

        assertEq(seVault.referrers(SUPPLIER), referrer, "referrer");
    }
}
