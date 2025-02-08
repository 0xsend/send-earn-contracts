// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";

contract SetupTest is SendEarnTest {
    function testSetup() public {
        assertEq(vault.name(), "MetaMorpho Vault");
        assertEq(vault.symbol(), "MMV");
        assertEq(address(vault.asset()), address(loanToken));
        assertEq(sevault.asset(), address(loanToken));
        assertEq(sevault.name(), "Send Earn: MetaMorpho Vault");
        assertEq(sevault.symbol(), "seMMV");
        assertEq(sevault.decimals(), 18);
        assertEq(sevault.totalAssets(), 0);
        assertEq(sevault.balanceOf(address(this)), 0);
        assertEq(sevault.feeRecipient(), SEND_FEE_RECIPIENT);
        assertEq(sevault.fee(), 0);
        assertEq(sevault.lastTotalAssets(), 0);
        assertEq(sevault.collections(), SEND_COLLECTIONS);
        assertEq(sevault.convertToShares(1e18), 1e18);
        assertEq(sevault.convertToAssets(1e18), 1e18);
    }
}
