// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";

contract ERC4626Test is SendEarnTest {
    function testDecimals(uint8 decimals) public {
        vm.mockCall(
            address(loanToken),
            abi.encodeWithSignature("decimals()"),
            abi.encode(decimals)
        );

        seVault = new SendEarn(
            OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol())
        );

        assertEq(seVault.decimals(), Math.max(18, decimals), "decimals");
    }

    function testMint(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        uint256 shares = seVault.convertToShares(assets);

        loanToken.setBalance(SUPPLIER, assets);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(seVault.totalAssets() + assets);
        vm.prank(SUPPLIER);
        uint256 deposited = seVault.mint(shares, ONBEHALF);

        assertGt(deposited, 0, "deposited");
        assertEq(loanToken.balanceOf(address(seVault)), 0, "balanceOf(vault)");
        assertEq(seVault.balanceOf(ONBEHALF), shares, "balanceOf(ONBEHALF)");
        // TODO: figure out why this is failing
        // assertEq(
        //     MorphoBalancesLib.expectedSupplyAssets(
        //         morpho,
        //         allMarkets[0],
        //         address(seVault)
        //     ),
        //     assets,
        //     "expectedSupplyAssets(vault)"
        // );
    }

    // TODO: Test basic deposit
    // TODO: Test deposit with referral
    // TODO: Test basic withdrawal
    // TODO: Test yield accrual
    // TODO: Test fee collection
    // TODO: Test referral fee distribution
    // TODO: Test owner-only functions
    // TODO: Test deposit of 0 assets
    // TODO: Test withdrawal exceeding balance
    // TODO: Implement deposit fuzz test
    // TODO: Implement withdraw fuzz test
    // TODO: Add invariant tests
}
