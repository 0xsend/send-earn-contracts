// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import {Errors} from "../src/lib/Errors.sol";
import {Events} from "../src/lib/Events.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {PlatformMock} from "./mocks/PlatformMock.sol";

contract PlatformTest is Test {
    address internal PLATFORM = makeAddr("Platform");
    address internal OWNER = makeAddr("Owner");
    address internal OTHER = makeAddr("Other");

    PlatformMock internal platform;

    function setUp() public {
        platform = new PlatformMock(PLATFORM, OWNER);
    }

    function testSetup() public view {
        assertEq(platform.platform(), PLATFORM, "platform");
        assertEq(platform.owner(), OWNER, "owner");
        assertEq(platform.pendingOwner(), address(0), "pendingOwner");
    }

    function testSetPlatform(address newPlatform) public {
        vm.assume(newPlatform != address(0));
        vm.assume(newPlatform != PLATFORM);

        vm.expectEmit(address(platform));
        emit Events.SetPlatform(newPlatform);
        vm.prank(PLATFORM);
        platform.setPlatform(newPlatform);

        assertEq(platform.platform(), newPlatform, "platform");
    }

    function testSetPlatformZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(PLATFORM);
        platform.setPlatform(address(0));
    }

    function testSetPlatformUnauthorized() public {
        vm.expectRevert(Errors.UnauthorizedPlatform.selector);
        platform.setPlatform(OTHER);
    }

    function testTransferOwnership(address newOwner) public {
        vm.assume(newOwner != address(0));
        vm.assume(newOwner != OWNER);

        vm.startPrank(PLATFORM);
        vm.expectEmit(address(platform));
        emit Events.OwnershipTransferStarted(OWNER, newOwner);
        platform.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(platform.pendingOwner(), newOwner, "pendingOwner");

        vm.startPrank(newOwner);
        platform.acceptOwnership();

        assertEq(platform.owner(), newOwner, "owner");
        assertEq(platform.pendingOwner(), address(0), "pendingOwner");
    }

    function testTransferOwnershipUnauthorized() public {
        vm.expectRevert(Errors.UnauthorizedPlatform.selector);
        platform.transferOwnership(OTHER);
    }

    function testOnlyPlatformModifier() public {
        vm.expectRevert(Errors.UnauthorizedPlatform.selector);
        platform.platformFunction();
        vm.prank(PLATFORM);
        platform.platformFunction();
    }

    function testOnlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        platform.ownerFunction();

        vm.prank(OWNER);
        platform.ownerFunction();
    }
}
