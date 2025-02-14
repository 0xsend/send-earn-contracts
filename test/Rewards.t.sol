// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "../src/lib/Events.sol";
import "./helpers/SendEarn.t.sol";

contract RewardsTest is SendEarnTest {
    address internal COLLECTIONS = makeAddr("Collections");

    ERC20Mock internal rewards1Token = new ERC20Mock("rewards1", "R1");
    ERC20Mock internal rewards2Token = new ERC20Mock("rewards2", "R2");

    function setUp() public override {
        super.setUp();

        vm.prank(SEND_OWNER);
        sevault.setCollections(COLLECTIONS);
    }

    function testClaimRewards(uint256 amount) public {
        // this would be a call to Universal Rewards Distributor
        rewards1Token.setBalance(address(sevault), amount);

        vm.expectEmit(address(sevault));
        emit Events.Collect(address(this), address(rewards1Token), amount);
        sevault.collect(address(rewards1Token));

        assertEq(rewards1Token.balanceOf(address(sevault)), 0);
        assertEq(rewards1Token.balanceOf(COLLECTIONS), amount);
    }

    function testClaimRewards2(uint256 amount1, uint256 amount2) public {
        rewards1Token.setBalance(address(sevault), amount1);
        rewards2Token.setBalance(address(sevault), amount2);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(sevault.collect.selector, address(rewards1Token));
        calls[1] = abi.encodeWithSelector(sevault.collect.selector, address(rewards2Token));

        sevault.multicall(calls);

        assertEq(rewards1Token.balanceOf(address(sevault)), 0);
        assertEq(rewards1Token.balanceOf(COLLECTIONS), amount1);
        assertEq(rewards2Token.balanceOf(address(sevault)), 0);
        assertEq(rewards2Token.balanceOf(COLLECTIONS), amount2);
    }
}
