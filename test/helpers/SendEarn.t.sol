// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "metamorpho-test/helpers/IntegrationTest.sol";

import {SendEarn} from "../../src/SendEarn.sol";

contract SendEarnTest is IntegrationTest {
    SendEarn internal seVault;

    function setUp() public override {
        super.setUp();
        seVault = new SendEarn(
            OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol())
        );

        loanToken.approve(address(seVault), type(uint256).max);
        collateralToken.approve(address(seVault), type(uint256).max);

        vm.startPrank(SUPPLIER);
        loanToken.approve(address(seVault), type(uint256).max);
        collateralToken.approve(address(seVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(ONBEHALF);
        loanToken.approve(address(seVault), type(uint256).max);
        collateralToken.approve(address(seVault), type(uint256).max);
        vm.stopPrank();
    }
}
