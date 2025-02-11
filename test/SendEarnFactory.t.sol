// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {ISendEarn} from "../src/interfaces/ISendEarn.sol";
import {SendEarnFactory} from "../src/SendEarnFactory.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Events} from "../src/lib/Events.sol";
import {Constants} from "../src/lib/Constants.sol";

bytes32 constant SALT = bytes32(uint256(1));

contract SendEarnFactoryTest is SendEarnTest {
    SendEarnFactory factory;

    function setUp() public override {
        super.setUp();
        factory = new SendEarnFactory(SEND_OWNER, address(vault), SALT);

        vm.startPrank(SEND_OWNER);
        factory.setPlatform(SEND_PLATFORM);
        vm.stopPrank();
    }

    function testDefaultSendEarnIsCreated() public {
        if (factory.affiliates(address(0)) == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (factory.SEND_EARN() == address(0)) {
            revert Errors.ZeroAddress();
        }
        assertEq(factory.isSendEarn(address(factory.SEND_EARN())), true, "isSendEarn");
        assertEq(factory.affiliates(address(0)), address(factory.SEND_EARN()), "affiliates");
        ISendEarn sendEarn = ISendEarn(factory.SEND_EARN());
        assertEq(sendEarn.owner(), SEND_OWNER, "SEND_EARN owner");
        assertEq(address(sendEarn.META_MORPHO()), address(vault), "SEND_EARN metamorpho");
        // TODO: share fee recipient with factory and send eanr vaults
        // assertEq(sendEarn.feeRecipient(), SEND_PLATFORM, "SEND_EARN feeRecipient");
    }

    function testFactoryAddressZero() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnFactory(SEND_OWNER, address(0), SALT);
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
        newSplit = bound(newSplit, 0, Constants.SPLIT_TOTAL);
        vm.assume(newSplit != factory.split());
        vm.startPrank(SEND_OWNER);
        vm.expectEmit(address(factory));
        emit Events.SetSplit(newSplit);
        factory.setSplit(newSplit);
        assertEq(factory.split(), newSplit, "split");
    }

    function testSetSplitMaxExceeded() public {
        vm.startPrank(SEND_OWNER);
        uint256 newSplit = Constants.SPLIT_TOTAL + 1;
        vm.expectRevert(Errors.MaxSplitExceeded.selector);
        factory.setSplit(newSplit);
    }
}
