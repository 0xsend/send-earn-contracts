// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "metamorpho-test/helpers/IntegrationTest.sol";

import {SendEarn} from "../../src/SendEarn.sol";

contract SendEarnTest is IntegrationTest {
    /// @dev The Send Earn Vault under test
    SendEarn internal sevault;

    address internal SEND_OWNER = makeAddr("SendOwner");
    address internal SEND_FEE_RECIPIENT = makeAddr("SendFeeRecipient");
    address internal SEND_COLLECTIONS = makeAddr("SendCollections");
    address internal SEND_PLATFORM = makeAddr("SendPlatform");

    function setUp() public virtual override {
        super.setUp();
        sevault = new SendEarn(
            SEND_OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol()),
            SEND_FEE_RECIPIENT,
            SEND_COLLECTIONS,
            0
        );

        loanToken.approve(address(sevault), type(uint256).max);
        collateralToken.approve(address(sevault), type(uint256).max);

        vm.startPrank(SUPPLIER);
        loanToken.approve(address(sevault), type(uint256).max);
        collateralToken.approve(address(sevault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(ONBEHALF);
        loanToken.approve(address(sevault), type(uint256).max);
        collateralToken.approve(address(sevault), type(uint256).max);
        vm.stopPrank();
    }

    function _setSendEarnFee(uint256 newFee) internal {
        uint256 fee = sevault.fee();
        if (newFee == fee) return;

        vm.prank(SEND_OWNER);
        sevault.setFee(newFee);

        assertEq(sevault.fee(), newFee, "_setSendEarnFee");
    }
}
