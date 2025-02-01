// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {Events} from "../src/lib/Events.sol";

contract FeesTest is SendEarnTest {
    // TODO: fix tests
    // TODO: add deposit/withdraw tests
    // TODO: add tests for referrals
    // function testSetFee(uint256 fee) public {
    //     fee = bound(fee, 0, ConstantsLib.MAX_FEE);
    //     vm.assume(fee != seVault.fee());
    //     vm.expectEmit(address(seVault));
    //     emit EventsLib.SetFee(OWNER, fee);
    //     vm.prank(OWNER);
    //     seVault.setFee(fee);
    //     assertEq(seVault.fee(), fee, "fee");
    // }
    // function testSetFeeRecipient(address feeRecipient) public {
    //     feeRecipient = _boundAddressNotZero(feeRecipient);
    //     vm.assume(feeRecipient != seVault.feeRecipient());
    //     vm.expectEmit(address(seVault));
    //     emit Events.SetFeeRecipient(feeRecipient);
    //     vm.prank(OWNER);
    //     seVault.setFeeRecipient(feeRecipient);
    //     assertEq(seVault.feeRecipient(), feeRecipient, "feeRecipient");
    // }
    // function testSetFeeReferral(uint256 feeReferral) public {
    //     feeReferral = bound(feeReferral, 0, ConstantsLib.MAX_FEE);
    //     vm.assume(feeReferral != seVault.feeReferral());
    //     vm.expectEmit(address(seVault));
    //     emit Events.SetFeeReferral(OWNER, feeReferral);
    //     vm.prank(OWNER);
    //     seVault.setFeeReferral(feeReferral);
    //     uint256 newFeeReferral = uint256(seVault.feeReferral());
    //     assertEq(newFeeReferral, feeReferral, "feeReferral");
    // }
}
