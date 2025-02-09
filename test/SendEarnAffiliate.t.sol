// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "../src/lib/Events.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Constants} from "../src/lib/Constants.sol";

import "./helpers/SendEarn.t.sol";
import {SendEarnAffiliate} from "../src/SendEarnAffiliate.sol";
import {ISplitConfig} from "../src/interfaces/ISendEarnAffiliate.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";

contract SendEarnAffiliateTest is SendEarnTest, ISplitConfig {
    using Math for uint256;
    using UtilsLib for uint256;

    address internal AFFILIATE = makeAddr("Affiliate");

    ERC20Mock internal token = new ERC20Mock("affiliate", "A");

    SendEarnAffiliate internal affiliate;

    uint256 internal _split;

    function setUp() public override {
        super.setUp();

        affiliate = new SendEarnAffiliate(AFFILIATE, address(this), address(token));
    }

    function platform() external view returns (address) {
        return SEND_PLATFORM;
    }

    function split() external view returns (uint256) {
        return _split;
    }

    function testNoToken() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(AFFILIATE, address(this), address(0));
    }

    function testNoAffiliate() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(address(0), address(this), address(token));
    }

    function testNoSplitConfig() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(AFFILIATE, address(0), address(token));
    }

    function testPay(uint256 amount, uint256 __split) public {
        amount = bound(amount, 1, type(uint256).max);
        _split = bound(__split, 0, Constants.SPLIT_TOTAL);

        token.setBalance(address(affiliate), amount);

        uint256 platformSplit = amount.mulDiv(_split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = amount.mulDiv(Constants.SPLIT_TOTAL - _split, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(address(this), amount, platformSplit, affiliateSplit);
        affiliate.pay();

        assertEq(token.balanceOf(SEND_PLATFORM), platformSplit, "balanceOf(SEND_PLATFORM)");
        assertEq(token.balanceOf(AFFILIATE), affiliateSplit, "balanceOf(AFFILIATE)");
        assertEq(
            token.balanceOf(address(affiliate)),
            amount - platformSplit - affiliateSplit,
            "balanceOf(address(affiliate))"
        );
    }

    function testPayExpected() public {
        uint256 amount = 100 ether;
        _split = 0.8 ether; // 80%

        testPay(amount, _split);

        assertEq(token.balanceOf(SEND_PLATFORM), 80 ether, "balanceOf(SEND_PLATFORM)");
        assertEq(token.balanceOf(AFFILIATE), 20 ether, "balanceOf(AFFILIATE)");
    }

    function testPayZeroAmount() public {
        token.setBalance(address(affiliate), 0);

        vm.expectRevert(Errors.ZeroAmount.selector);
        affiliate.pay();
    }

    function testPayMaximumSplit() public {
        uint256 amount = 100 ether;
        _split = Constants.SPLIT_TOTAL; // 100% to platform

        testPay(amount, _split);

        assertEq(token.balanceOf(SEND_PLATFORM), amount, "Platform should receive all");
        assertEq(token.balanceOf(AFFILIATE), 0, "Affiliate should receive nothing");
    }

    function testPayMinimumSplit() public {
        uint256 amount = 100 ether;
        _split = 0; // 0% to platform

        testPay(amount, _split);

        assertEq(token.balanceOf(SEND_PLATFORM), 0, "Platform should receive nothing");
        assertEq(token.balanceOf(AFFILIATE), amount, "Affiliate should receive all");
    }

    function testPayRounding() public {
        uint256 amount = 100; // Small amount to force rounding
        _split = 3333; // Non-even split that will cause rounding

        testPay(amount, _split);

        // Verify total transferred equals original amount minus dust
        assertLe(
            token.balanceOf(SEND_PLATFORM) + token.balanceOf(AFFILIATE),
            amount,
            "Total transferred should not exceed original amount"
        );
    }

    function testPayWithChangingSplit() public {
        uint256 amount = 100 ether;
        _split = 0.5 ether; // Start with 50/50

        token.setBalance(address(affiliate), amount);
        affiliate.pay();

        _forward(100);

        // Change split and verify new split is respected
        _split = 0.7 ether; // Change to 70/30
        token.setBalance(address(affiliate), amount);

        uint256 expectedPlatform = amount.mulDiv(0.7 ether, Constants.SPLIT_TOTAL);
        uint256 expectedAffiliate = amount.mulDiv(0.3 ether, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(address(this), amount, expectedPlatform, expectedAffiliate);
        affiliate.pay();
    }
}
