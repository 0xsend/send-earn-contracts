// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "metamorpho-test/helpers/IntegrationTest.sol";

import {SendEarn} from "../../src/SendEarn.sol";

contract SendEarnTest is IntegrationTest {
    SendEarn internal seVault;

    address internal SEND_OWNER = makeAddr("SendOwner");
    address internal SEND_FEE_RECIPIENT = makeAddr("SendFeeRecipient");
    address internal SEND_SKIM_RECIPIENT = makeAddr("SendSkimRecipient");

    function setUp() public virtual override {
        super.setUp();
        seVault = new SendEarn(
            SEND_OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol())
        );

        vm.startPrank(SEND_OWNER);
        seVault.setFeeRecipient(SEND_FEE_RECIPIENT);
        // TODO: add skim recipient
        // seVault.setSkimRecipient(SEND_SKIM_RECIPIENT);
        vm.stopPrank();

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

    function _setSendFee(uint256 newFee) internal {
        uint256 fee = seVault.fee();
        if (newFee == fee) return;

        vm.prank(SEND_OWNER);
        seVault.setFee(newFee);

        assertEq(seVault.fee(), newFee, "_setSendFee");
    }
}
