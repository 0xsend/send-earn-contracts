// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "../src/lib/Events.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SendEarnAffiliate} from "../src/SendEarnAffiliate.sol";
import {IPartnerSplitConfig} from "../src/interfaces/ISendEarnAffiliate.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";
import {ERC4626Mock} from "./mocks/ERC4626Mock.sol";

import {SendEarnTest, Math, ERC20Mock, BLOCK_TIME, MIN_TEST_ASSETS, MAX_TEST_ASSETS} from "./helpers/SendEarn.t.sol";
import {IERC4626, IERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract SendEarnAffiliateTest is SendEarnTest, IPartnerSplitConfig {
    using Math for uint256;
    using UtilsLib for uint256;

    address internal PLATFORM = makeAddr("Platform");
    address internal AFFILIATE = makeAddr("Affiliate");

    IERC4626 internal affiliateVault = new ERC4626Mock(IERC20(address(loanToken)), "affiliate", "vA");

    SendEarnAffiliate internal affiliate;

    uint256 internal _split;

    function setUp() public override {
        super.setUp();
        affiliate = new SendEarnAffiliate(AFFILIATE, address(this), address(sevault));
        vm.prank(address(affiliate));
        loanToken.approve(address(affiliateVault), type(uint256).max);
    }

    /* IPartnerSplitConfig */

    function platform() external view returns (address) {
        return PLATFORM;
    }

    function split() external view returns (uint256) {
        return _split;
    }

    /* Internal */

    function deposit(uint256 amount) internal {
        loanToken.setBalance(address(affiliate), amount);
        vm.prank(address(affiliate));
        affiliateVault.deposit(amount, address(affiliate));
    }

    /* Tests */

    function testNoAffiliate() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(address(0), address(this), address(sevault));
    }

    function testNoSplitConfig() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(AFFILIATE, address(0), address(sevault));
    }

    function testPay(uint256 amount, uint256 __split) public {
        amount = bound(amount, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        _split = bound(__split, 0, Constants.SPLIT_TOTAL);

        deposit(amount);

        uint256 platformSplit = amount.mulDiv(_split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = amount.mulDiv(Constants.SPLIT_TOTAL - _split, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this), address(affiliateVault), address(loanToken), amount, platformSplit, affiliateSplit
        );
        affiliate.pay(affiliateVault);

        assertEq(sevault.balanceOf(PLATFORM), platformSplit, "balanceOf(PLATFORM)");
        assertEq(sevault.balanceOf(AFFILIATE), affiliateSplit, "balanceOf(AFFILIATE)");
        assertApproxEqAbs(
            sevault.balanceOf(address(affiliate)),
            amount - platformSplit - affiliateSplit,
            1,
            "balanceOf(address(affiliate))"
        );
        // Verify total transferred equals original amount minus dust
        assertLe(
            sevault.balanceOf(PLATFORM) + sevault.balanceOf(AFFILIATE),
            amount,
            "Total transferred should not exceed original amount"
        );
    }

    function testPayExpected() public {
        uint256 amount = 100 ether;
        _split = 0.8 ether; // 80%

        testPay(amount, _split);

        assertEq(sevault.balanceOf(PLATFORM), 80 ether, "balanceOf(PLATFORM)");
        assertEq(sevault.balanceOf(AFFILIATE), 20 ether, "balanceOf(AFFILIATE)");
    }

    function testPayZeroAmount() public {
        deposit(0);

        vm.expectRevert(Errors.ZeroAmount.selector);
        affiliate.pay(affiliateVault);
    }

    function testPayMaximumSplit() public {
        uint256 amount = 100 ether;
        _split = Constants.SPLIT_TOTAL; // 100% to platform

        testPay(amount, _split);

        assertEq(sevault.balanceOf(PLATFORM), amount, "Platform should receive all");
        assertEq(sevault.balanceOf(AFFILIATE), 0, "Affiliate should receive nothing");
    }

    function testPayMinimumSplit() public {
        uint256 amount = 100 ether;
        _split = 0; // 0% to platform

        testPay(amount, _split);

        assertEq(sevault.balanceOf(PLATFORM), 0, "Platform should receive nothing");
        assertEq(sevault.balanceOf(AFFILIATE), amount, "Affiliate should receive all");
    }

    function testPayWithChangingSplit() public {
        uint256 amount = 100 ether;
        _split = 0.5 ether; // Start with 50/50

        deposit(amount);
        affiliate.pay(affiliateVault);

        _forward(100);

        // Change split and verify new split is respected
        _split = 0.7 ether; // Change to 70/30
        deposit(amount);

        uint256 expectedPlatform = amount.mulDiv(0.7 ether, Constants.SPLIT_TOTAL);
        uint256 expectedAffiliate = amount.mulDiv(0.3 ether, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this), address(affiliateVault), address(loanToken), amount, expectedPlatform, expectedAffiliate
        );
        affiliate.pay(affiliateVault);
    }
}
