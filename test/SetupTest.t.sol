// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";

contract SetupTest is SendEarnTest {
    function testSetup() public {
        assertEq(vault.name(), "MetaMorpho Vault");
        assertEq(vault.symbol(), "MMV");
        assertEq(address(vault.asset()), address(loanToken));
        assertEq(seVault.asset(), address(loanToken));
        assertEq(seVault.name(), "Send Earn: MetaMorpho Vault");
        assertEq(seVault.symbol(), "seMMV");
        assertEq(seVault.decimals(), 18);
        // assertEq(seVault.totalAssets(), 0);
        assertEq(seVault.balanceOf(address(this)), 0);
        // assertEq(seVault.convertToShares(1e18), 1e18);
        // assertEq(seVault.convertToAssets(1e18), 1e18);
    }
}
