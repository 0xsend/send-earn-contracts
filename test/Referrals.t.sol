// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {Events} from "../src/lib/Events.sol";
contract ReferralsTest is SendEarnTest {
    function testSetFeeReferrer(address referrer) public {
        referrer = _boundAddressNotZero(referrer);

        vm.expectEmit(address(sevault));
        emit Events.SetReferrer(SUPPLIER, referrer);
        vm.prank(SUPPLIER);
        sevault.setReferrer(referrer);

        assertEq(sevault.referrers(SUPPLIER), referrer, "referrer");
    }
}
