// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IERC20Errors} from "openzeppelin-contracts/interfaces/draft-IERC6093.sol";
import "./helpers/SendEarn.t.sol";

contract ERC4626Test is SendEarnTest {
    using MorphoBalancesLib for IMorpho;

    function setUp() public override {
        super.setUp();

        _setCap(allMarkets[0], CAP);
        _sortSupplyQueueIdleLast();
    }

    function testDecimals(uint8 decimals) public {
        vm.mockCall(
            address(loanToken),
            abi.encodeWithSignature("decimals()"),
            abi.encode(decimals)
        );

        sevault = new SendEarn(
            SEND_OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol())
        );

        assertEq(sevault.decimals(), Math.max(18, decimals), "decimals");
    }

    function testMint(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        uint256 shares = sevault.convertToShares(assets);

        loanToken.setBalance(SUPPLIER, assets);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() + assets);
        vm.prank(SUPPLIER);
        uint256 deposited = sevault.mint(shares, ONBEHALF);

        assertGt(deposited, 0, "deposited");
        assertEq(
            loanToken.balanceOf(address(sevault)),
            0,
            "balanceOf(sevault)"
        );
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(sevault.balanceOf(ONBEHALF), shares, "balanceOf(ONBEHALF)");
        assertEq(
            morpho.expectedSupplyAssets(allMarkets[0], address(vault)),
            assets,
            "expectedSupplyAssets(vault)"
        );
    }

    function testDeposit(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        uint256 shares = sevault.convertToShares(assets);

        loanToken.setBalance(SUPPLIER, assets);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() + assets);
        vm.prank(SUPPLIER);
        uint256 deposited = sevault.deposit(assets, ONBEHALF);

        assertGt(deposited, 0, "deposited");
        assertEq(
            loanToken.balanceOf(address(sevault)),
            0,
            "balanceOf(sevault)"
        );
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(sevault.balanceOf(ONBEHALF), shares, "balanceOf(ONBEHALF)");
        assertEq(
            vault.balanceOf(address(sevault)),
            shares,
            "balanceOf(sevault)"
        );
        assertEq(
            morpho.expectedSupplyAssets(allMarkets[0], address(vault)),
            assets,
            "expectedSupplyAssets(vault)"
        );
    }

    function testRedeem(uint256 deposited, uint256 redeemed) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        redeemed = bound(redeemed, 0, shares);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(
            sevault.totalAssets() - sevault.convertToAssets(redeemed)
        );
        vm.prank(ONBEHALF);
        sevault.redeem(redeemed, RECEIVER, ONBEHALF);

        assertEq(
            loanToken.balanceOf(address(sevault)),
            0,
            "balanceOf(sevault)"
        );
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(
            vault.balanceOf(address(sevault)),
            shares - redeemed,
            "vault.balanceOf(address(sevault))"
        );
        assertEq(
            sevault.balanceOf(ONBEHALF),
            shares - redeemed,
            "balanceOf(ONBEHALF)"
        );
    }

    function testWithdraw(uint256 deposited, uint256 withdrawn) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        withdrawn = bound(withdrawn, 0, deposited);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() - withdrawn);
        vm.prank(ONBEHALF);
        uint256 redeemed = sevault.withdraw(withdrawn, RECEIVER, ONBEHALF);

        assertEq(
            loanToken.balanceOf(address(sevault)),
            0,
            "balanceOf(sevault)"
        );
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(
            vault.balanceOf(address(sevault)),
            shares - redeemed,
            "balanceOf(address(sevault))"
        );
        assertEq(
            sevault.balanceOf(ONBEHALF),
            shares - redeemed,
            "balanceOf(ONBEHALF)"
        );
    }

    function testWithdrawIdle(uint256 deposited, uint256 withdrawn) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        withdrawn = bound(withdrawn, 0, deposited);

        _setCap(allMarkets[0], 0);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() - withdrawn);
        vm.prank(ONBEHALF);
        uint256 redeemed = sevault.withdraw(withdrawn, RECEIVER, ONBEHALF);

        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(vault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(
            vault.balanceOf(address(sevault)),
            shares - redeemed,
            "vault.balanceOf(address(sevault))"
        );
        assertEq(
            sevault.balanceOf(ONBEHALF),
            shares - redeemed,
            "balanceOf(ONBEHALF)"
        );
        assertEq(_idle(), deposited - withdrawn, "idle");
    }

    function testRedeemTooMuch(uint256 deposited) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited * 2);

        vm.startPrank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);
        vm.stopPrank();

        vm.prank(SUPPLIER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                SUPPLIER,
                shares,
                shares + 1
            )
        );
        sevault.redeem(shares + 1, RECEIVER, SUPPLIER);
    }

    function testWithdrawAll(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, assets);

        vm.prank(SUPPLIER);
        uint256 minted = sevault.deposit(assets, ONBEHALF);

        assertEq(
            sevault.maxWithdraw(ONBEHALF),
            assets,
            "maxWithdraw(ONBEHALF)"
        );

        vm.prank(ONBEHALF);
        uint256 shares = sevault.withdraw(assets, RECEIVER, ONBEHALF);

        assertEq(shares, minted, "shares");
        assertEq(sevault.balanceOf(ONBEHALF), 0, "balanceOf(ONBEHALF)");
        assertEq(
            loanToken.balanceOf(RECEIVER),
            assets,
            "loanToken.balanceOf(RECEIVER)"
        );
        assertEq(
            vault.balanceOf(address(sevault)),
            0,
            "vault.balanceOf(address(sevault))"
        );
        assertEq(
            morpho.expectedSupplyAssets(allMarkets[0], address(vault)),
            0,
            "expectedSupplyAssets(vault)"
        );
    }

        assertEq(
            morpho.expectedSupplyAssets(allMarkets[0], address(vault)),
            0,
            "expectedSupplyAssets(vault)"
        );
    }
}
