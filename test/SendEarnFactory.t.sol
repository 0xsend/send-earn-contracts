// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {SendEarnFactory} from "../src/SendEarnFactory.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Events} from "../src/lib/Events.sol";

contract SendEarnFactoryTest is SendEarnTest {
    SendEarnFactory factory;

    function setUp() public override {
        super.setUp();

        factory = new SendEarnFactory(SEND_OWNER, address(vault));

        vm.startPrank(SEND_OWNER);
        factory.setPlatform(SEND_PLATFORM);
        vm.stopPrank();
    }

    function testFactoryAddressZero() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnFactory(SEND_OWNER, address(0));
    }

    function testSetPlatform(address newPlatform) public {
        vm.assume(newPlatform != address(0));
        vm.assume(newPlatform != SEND_PLATFORM);
        vm.startPrank(SEND_OWNER);
        vm.expectEmit(address(factory));
        emit Events.SetPlatform(newPlatform);
        factory.setPlatform(newPlatform);
        assertEq(factory.platform(), newPlatform, "platform");
    }

    function testSetPlatformZeroAddress() public {
        vm.startPrank(SEND_OWNER);
        vm.expectRevert(Errors.ZeroAddress.selector);
        factory.setPlatform(address(0));
    }

    function testSetSplit(uint256 newSplit) public {
        vm.assume(newSplit != factory.split());
        vm.startPrank(SEND_OWNER);
        newSplit = bound(newSplit, 0, factory.SPLIT_TOTAL());
        vm.expectEmit(address(factory));
        emit Events.SetSplit(newSplit);
        factory.setSplit(newSplit);
        assertEq(factory.split(), newSplit, "split");
    }

    function testSetSplitMaxExceeded() public {
        vm.startPrank(SEND_OWNER);
        uint256 newSplit = factory.SPLIT_TOTAL() + 1;
        vm.expectRevert(Errors.MaxSplitExceeded.selector);
        factory.setSplit(newSplit);
    }
}
