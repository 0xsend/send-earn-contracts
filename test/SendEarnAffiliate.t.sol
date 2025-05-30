// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "../src/lib/Events.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Constants} from "../src/lib/Constants.sol";
import {SendEarnAffiliate} from "../src/SendEarnAffiliate.sol";
import {IPartnerSplitConfig} from "../src/interfaces/ISendEarnAffiliate.sol";
import {ERC4626Mock} from "./mocks/ERC4626Mock.sol";

import {SendEarnTest, Math, MIN_TEST_ASSETS, MAX_TEST_ASSETS} from "./helpers/SendEarn.t.sol";
import {IERC4626, IERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20Mock} from "metamorpho/mocks/ERC20Mock.sol";
import {MockAffiliate} from "./mocks/SendEarnAffiliateMock.sol";

contract SendEarnAffiliateTest is SendEarnTest, IPartnerSplitConfig {
    using Math for uint256;

    address internal PLATFORM = makeAddr("Platform");
    address internal AFFILIATE = makeAddr("Affiliate");

    IERC4626 internal affiliateVault = new ERC4626Mock(IERC20(address(loanToken)), "affiliate", "vA");

    SendEarnAffiliate internal affiliate;

    uint256 internal _split;

    function setUp() public override {
        super.setUp();
        affiliate = new SendEarnAffiliate(AFFILIATE, address(this), address(sevault), address(sevault));
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
        depositFromAddress(address(affiliate), amount);
    }

    function depositFromAddress(address from, uint256 amount) internal {
        loanToken.setBalance(address(from), amount);
        vm.startPrank(address(from));
        loanToken.approve(address(affiliateVault), amount);
        affiliateVault.deposit(amount, address(from));
        vm.stopPrank();
    }

    /* Tests */

    function testSetup() public {
        assertEq(address(affiliate.payVault()), address(sevault), "payVault");
        assertEq(affiliate.affiliate(), AFFILIATE, "affiliate");
        assertEq(address(affiliate.splitConfig()), address(this), "splitConfig");
    }

    function testNoAffiliate() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(address(0), address(this), address(sevault), address(sevault));
    }

    function testNoSplitConfig() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnAffiliate(AFFILIATE, address(0), address(sevault), address(sevault));
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

    function testSetPayVault() public {
        IERC4626 newVault = new ERC4626Mock(IERC20(address(loanToken)), "new vault", "vN");

        vm.prank(AFFILIATE);
        affiliate.setPayVault(address(newVault));

        assertEq(address(affiliate.payVault()), address(newVault));
    }

    function testSetPayVaultUnauthorized() public {
        IERC4626 newVault = new ERC4626Mock(IERC20(address(loanToken)), "new vault", "vN");

        vm.expectRevert(Errors.UnauthorizedAffiliate.selector);
        affiliate.setPayVault(address(newVault));
    }

    function testSetPayVaultZeroAddress() public {
        vm.prank(AFFILIATE);
        vm.expectRevert(Errors.ZeroAddress.selector);
        affiliate.setPayVault(address(0));
    }

    function testSetPayVaultSameAddress() public {
        vm.prank(AFFILIATE);
        vm.expectRevert(Errors.AlreadySet.selector);
        affiliate.setPayVault(address(sevault));
    }

    function testSetPayVaultAssetMismatch() public {
        // Create a vault with different underlying asset
        ERC20Mock differentAsset = new ERC20Mock("Different", "DIFF");
        IERC4626 newVault = new ERC4626Mock(IERC20(address(differentAsset)), "new vault", "vN");

        vm.prank(AFFILIATE);
        vm.expectRevert(Errors.AssetMismatch.selector);
        affiliate.setPayVault(address(newVault));
    }

    function testPayWrongAsset() public {
        // Create a vault with different underlying asset
        ERC20Mock differentAsset = new ERC20Mock("Different", "DIFF");
        IERC4626 wrongVault = new ERC4626Mock(IERC20(address(differentAsset)), "wrong", "vW");

        vm.expectRevert(Errors.AssetMismatch.selector);
        affiliate.pay(wrongVault);
    }

    function testPayWithAmount(uint256 amount, uint256 __split, uint256 redeemAmount) public {
        amount = bound(amount, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        _split = bound(__split, 0, Constants.SPLIT_TOTAL);
        // Ensure redeemAmount is between 1 and the full amount
        redeemAmount = bound(redeemAmount, 1, amount);

        deposit(amount);

        uint256 platformSplit = redeemAmount.mulDiv(_split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = redeemAmount.mulDiv(Constants.SPLIT_TOTAL - _split, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this), address(affiliateVault), address(loanToken), redeemAmount, platformSplit, affiliateSplit
        );
        affiliate.payWithAmount(affiliateVault, redeemAmount);

        assertEq(sevault.balanceOf(PLATFORM), platformSplit, "balanceOf(PLATFORM)");
        assertEq(sevault.balanceOf(AFFILIATE), affiliateSplit, "balanceOf(AFFILIATE)");

        // Verify total transferred equals redeemAmount minus dust
        assertLe(
            sevault.balanceOf(PLATFORM) + sevault.balanceOf(AFFILIATE),
            redeemAmount,
            "Total transferred should not exceed redeemAmount"
        );
    }

    function testPayWithAmountZeroAmount() public {
        deposit(100 ether);

        vm.expectRevert(Errors.ZeroAmount.selector);
        affiliate.payWithAmount(affiliateVault, 0);
    }

    function testPayWithAmountWrongAsset() public {
        // Create a vault with different underlying asset
        ERC20Mock differentAsset = new ERC20Mock("Different", "DIFF");
        IERC4626 wrongVault = new ERC4626Mock(IERC20(address(differentAsset)), "wrong", "vW");

        vm.expectRevert(Errors.AssetMismatch.selector);
        affiliate.payWithAmount(wrongVault, 100 ether);
    }

    function testPayWithAmountExceedingBalance(uint256 amount) public {
        amount = bound(amount, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        deposit(amount);

        // Try to redeem more than available
        uint256 excessAmount = affiliateVault.balanceOf(address(affiliate)) + 1;

        // This should revert with an error from the ERC4626 implementation
        // The exact error message depends on the implementation
        vm.expectRevert();
        affiliate.payWithAmount(affiliateVault, excessAmount);
    }

    function testPayWithAmountPartial() public {
        uint256 amount = 100 ether;
        _split = 0.5 ether; // 50%

        deposit(amount);

        // Redeem half the amount
        uint256 redeemAmount = amount / 2;

        uint256 expectedPlatform = redeemAmount.mulDiv(0.5 ether, Constants.SPLIT_TOTAL);
        uint256 expectedAffiliate = redeemAmount.mulDiv(0.5 ether, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this),
            address(affiliateVault),
            address(loanToken),
            redeemAmount,
            expectedPlatform,
            expectedAffiliate
        );
        affiliate.payWithAmount(affiliateVault, redeemAmount);

        assertEq(sevault.balanceOf(PLATFORM), expectedPlatform, "Platform should receive 50% of half");
        assertEq(sevault.balanceOf(AFFILIATE), expectedAffiliate, "Affiliate should receive 50% of half");

        // Redeem the remaining amount
        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this),
            address(affiliateVault),
            address(loanToken),
            redeemAmount,
            expectedPlatform,
            expectedAffiliate
        );
        affiliate.payWithAmount(affiliateVault, redeemAmount);

        assertEq(sevault.balanceOf(PLATFORM), expectedPlatform * 2, "Platform should receive 50% of total");
        assertEq(sevault.balanceOf(AFFILIATE), expectedAffiliate * 2, "Affiliate should receive 50% of total");
    }

    function testCanSetPayVaultAndPay(uint256 amount, uint256 __split) public {
        amount = bound(amount, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        _split = bound(__split, 0, Constants.SPLIT_TOTAL);

        IERC4626 newVault = new ERC4626Mock(IERC20(address(loanToken)), "new vault", "vN");

        vm.prank(AFFILIATE);
        affiliate.setPayVault(address(newVault));

        deposit(amount);

        uint256 platformSplit = amount.mulDiv(_split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = amount.mulDiv(Constants.SPLIT_TOTAL - _split, Constants.SPLIT_TOTAL);

        vm.expectEmit(address(affiliate));
        emit Events.AffiliatePay(
            address(this), address(affiliateVault), address(loanToken), amount, platformSplit, affiliateSplit
        );
        affiliate.pay(affiliateVault);

        // platform split is sent to platform vault
        assertEq(sevault.balanceOf(PLATFORM), platformSplit, "sevault.balanceOf(PLATFORM)");
        assertEq(sevault.balanceOf(AFFILIATE), 0, "sevault.balanceOf(address(affiliate))");
        // affiliate split is sent to affiliate vault
        assertEq(newVault.balanceOf(PLATFORM), 0, "newVault.balanceOf(PLATFORM)");
        assertEq(newVault.balanceOf(AFFILIATE), affiliateSplit, "newVault.balanceOf(AFFILIATE)");

        // all balances are sent to the vaults
        assertApproxEqAbs(
            affiliateVault.balanceOf(address(affiliate)),
            amount - platformSplit - affiliateSplit,
            1,
            "affiliateVault.balanceOf(address(affiliate))"
        );
    }

    function test_payInDos(uint256 amount, uint256 __split, uint256 attackingAmount) public {
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

        address attacker = makeAddr("Attacker");
        attackingAmount = bound(attackingAmount, 1, amount);
        depositFromAddress(attacker, attackingAmount);
        vm.startPrank(attacker);
        affiliateVault.transfer(address(affiliate), attackingAmount);
        vm.stopPrank();

        // does not revert, and attacker donated to platform & affiliate
        affiliate.pay(affiliateVault);
    }

    function testPayCallsPayWithAmount() public {
        // Create a mock to verify the call to payWithAmount
        MockAffiliate mockAffiliate = new MockAffiliate(AFFILIATE, address(this), address(sevault), address(sevault));

        // Create a mock vault for testing
        ERC4626Mock mockVault = new ERC4626Mock(IERC20(address(loanToken)), "mock vault", "mV");

        // Set a fixed maxRedeem value for our test
        uint256 mockMaxRedeem = 100 ether;
        mockAffiliate.setMockMaxRedeem(mockMaxRedeem);

        // Set up the mock to expect a call with the mocked maxRedeem amount
        mockAffiliate.expectPayWithAmount(address(mockVault), mockMaxRedeem);

        // Call pay and verify it calls payWithAmount with the correct parameters
        mockAffiliate.pay(mockVault);

        // Verify the mock expectations were met
        assertTrue(mockAffiliate.expectationsMet(), "pay should call payWithAmount with the correct parameters");
    }
}
