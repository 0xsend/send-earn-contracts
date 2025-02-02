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

        _setSendFee(SEND_FEE);
    }

    // TODO: fix tests
    // TODO: add deposit/withdraw tests
    // TODO: add tests for referrals
    function testSetFee(uint256 fee) public {
        fee = bound(fee, 0, ConstantsLib.MAX_FEE);
        vm.assume(fee != seVault.fee());
        vm.expectEmit(address(seVault));
        emit EventsLib.SetFee(SEND_OWNER, fee);
        vm.prank(SEND_OWNER);
        seVault.setFee(fee);
        assertEq(seVault.fee(), fee, "fee");
    }
    function testSetFeeRecipient(address feeRecipient) public {
        feeRecipient = _boundAddressNotZero(feeRecipient);
        vm.assume(feeRecipient != seVault.feeRecipient());
        vm.expectEmit(address(seVault));
        emit Events.SetFeeRecipient(feeRecipient);
        vm.prank(SEND_OWNER);
        seVault.setFeeRecipient(feeRecipient);
        assertEq(seVault.feeRecipient(), feeRecipient, "feeRecipient");
    }
    function testSetFeeReferral(uint256 feeReferral) public {
        feeReferral = bound(feeReferral, 0, ConstantsLib.MAX_FEE);
        vm.assume(feeReferral != seVault.feeReferral());
        vm.expectEmit(address(seVault));
        emit Events.SetFeeReferral(SEND_OWNER, feeReferral);
        vm.prank(SEND_OWNER);
        seVault.setFeeReferral(feeReferral);
        uint256 newFeeReferral = uint256(seVault.feeReferral());
        assertEq(newFeeReferral, feeReferral, "feeReferral");
    }
}
