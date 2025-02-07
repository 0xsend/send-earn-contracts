// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {Events} from "../src/lib/Events.sol";

uint256 constant MORPHO_FEE = 0.2 ether; // 20%
uint256 constant SEND_FEE = 0.1 ether; // 10%

contract FeesTest is SendEarnTest {
    using Math for uint256;
    using MathLib for uint256;
    using MarketParamsLib for MarketParams;

    function setUp() public override {
        super.setUp();
        _setFee(MORPHO_FEE);
        _setSendEarnFee(SEND_FEE);

        for (uint256 i; i < NB_MARKETS; ++i) {
            MarketParams memory marketParams = allMarkets[i];

            // Create some debt on the market to accrue interest.

            loanToken.setBalance(SUPPLIER, MAX_TEST_ASSETS);

            vm.prank(SUPPLIER);
            morpho.supply(marketParams, MAX_TEST_ASSETS, 0, ONBEHALF, hex"");

            uint256 collateral = uint256(MAX_TEST_ASSETS).wDivUp(
                marketParams.lltv
            );
            collateralToken.setBalance(BORROWER, collateral);

            vm.startPrank(BORROWER);
            morpho.supplyCollateral(marketParams, collateral, BORROWER, hex"");
            morpho.borrow(marketParams, MAX_TEST_ASSETS, 0, BORROWER, BORROWER);
            vm.stopPrank();
        }

        _setCap(allMarkets[0], CAP);
        _sortSupplyQueueIdleLast();
    }

    function testSetFee(uint256 fee) public {
        fee = bound(fee, 0, ConstantsLib.MAX_FEE);
        vm.assume(fee != sevault.fee());
        vm.expectEmit(address(sevault));
        emit EventsLib.SetFee(SEND_OWNER, fee);
        vm.prank(SEND_OWNER);
        sevault.setFee(fee);
        assertEq(sevault.fee(), fee, "fee");
    }

    function testSetFeeRecipient(address feeRecipient) public {
        feeRecipient = _boundAddressNotZero(feeRecipient);
        vm.assume(feeRecipient != sevault.feeRecipient());
        vm.expectEmit(address(sevault));
        emit Events.SetFeeRecipient(feeRecipient);
        vm.prank(SEND_OWNER);
        sevault.setFeeRecipient(feeRecipient);
        assertEq(sevault.feeRecipient(), feeRecipient, "feeRecipient");
    }
    function testSetFeeReferral(uint256 feeReferral) public {
        feeReferral = bound(feeReferral, 0, ConstantsLib.MAX_FEE);
        vm.assume(feeReferral != sevault.feeReferral());
        vm.expectEmit(address(sevault));
        emit Events.SetFeeReferral(SEND_OWNER, feeReferral);
        vm.prank(SEND_OWNER);
        sevault.setFeeReferral(feeReferral);
        uint256 newFeeReferral = uint256(sevault.feeReferral());
        assertEq(newFeeReferral, feeReferral, "feeReferral");
    }

    function _feeShares() internal view returns (uint256) {
        // this is exactly what maxWithdraw does that works for getting
        // accurate interest generated for fee calculation
        uint256 mmBalance = vault.balanceOf(address(sevault));
        uint256 mmAssets = vault.convertToAssets(mmBalance);
        uint256 totalAssetsAfter = mmAssets;
        // this was the old way of getting the max withdraw
        // uint256 totalAssetsAfter = sevault.totalAssets();
        uint256 interest = totalAssetsAfter - sevault.lastTotalAssets();
        uint256 sendFeeAssets = interest.mulDiv(SEND_FEE, WAD);
        uint256 feeShares = sendFeeAssets.mulDiv(
            sevault.totalSupply() + 1,
            totalAssetsAfter - sendFeeAssets + 1,
            Math.Rounding.Floor
        );
        return feeShares;
    }

    function _metaMorphoFeeShares() internal view returns (uint256) {
        uint256 totalAssetsAfter = vault.totalAssets();
        uint256 interest = totalAssetsAfter - vault.lastTotalAssets();
        uint256 feeAssets = interest.mulDiv(MORPHO_FEE, WAD);

        return
            feeAssets.mulDiv(
                vault.totalSupply() + 1,
                totalAssetsAfter - feeAssets + 1,
                Math.Rounding.Floor
            );
    }

    function testAccrueFeeWithinABlock(
        uint256 deposited,
        uint256 withdrawn
    ) public {
        deposited = bound(deposited, MIN_TEST_ASSETS + 1, MAX_TEST_ASSETS);
        // The deposited amount is rounded down on Morpho and thus cannot be withdrawn in a block in most cases
        withdrawn = bound(withdrawn, MIN_TEST_ASSETS, deposited - 1);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);

        assertEqLastTotalAssets("lastTotalAssets1");

        vm.prank(ONBEHALF);
        sevault.withdraw(withdrawn, RECEIVER, ONBEHALF);

        assertEqLastTotalAssets("lastTotalAssets2");
        assertApproxEqAbs(
            sevault.balanceOf(SEND_FEE_RECIPIENT),
            0,
            1,
            "sevault.balanceOf(SEND_FEE_RECIPIENT)"
        );
    }

    function testDepositeAccrueFee(
        uint256 deposited,
        uint256 newDeposit,
        uint256 blocks
    ) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        newDeposit = bound(newDeposit, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        blocks = _boundBlocks(blocks);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);

        assertEqLastTotalAssets("lastTotalAssets1");

        _forward(blocks);

        uint256 feeShares = _feeShares();
        _metaMorphoFeeShares();
        vm.assume(feeShares != 0);

        loanToken.setBalance(SUPPLIER, newDeposit);

        vm.expectEmit(address(sevault));
        emit Events.AccrueInterest(sevault.totalAssets(), feeShares);

        vm.prank(SUPPLIER);
        sevault.deposit(newDeposit, ONBEHALF);

        assertEqLastTotalAssets("lastTotalAssets2");
        assertEq(
            sevault.balanceOf(SEND_FEE_RECIPIENT),
            feeShares,
            "sevault.balanceOf(SEND_FEE_RECIPIENT)"
        );
    }

    function assertEqLastTotalAssets(string memory err) internal {
        assertApproxEqAbs(
            sevault.lastTotalAssets(),
            sevault.totalAssets(),
            1,
            string.concat("sevault.", err)
        );
        assertApproxEqAbs(
            vault.lastTotalAssets(),
            vault.totalAssets(),
            1,
            string.concat("vault.", err)
        );
        // after a fee update, there will be a difference in total assets
        // after meta morpho takes their cut.
        // likely there is a way to still make this comparison with
        // more tolerance that allows for upto the fee %
        // assertApproxEqAbs(
        //     sevault.lastTotalAssets(),
        //     vault.totalAssets(),
        //     1,
        //     string.concat("sevault == vault ", err)
        // );
    }
}
