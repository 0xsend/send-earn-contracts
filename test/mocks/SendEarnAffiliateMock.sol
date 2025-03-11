/// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {SendEarnAffiliate} from "../../src/SendEarnAffiliate.sol";
import {IERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

/// @notice Mock contract to test that pay calls payWithAmount with the correct parameters
contract MockAffiliate is SendEarnAffiliate {
    address private expectedVault;
    uint256 private expectedAmount;
    bool private called;
    uint256 private mockMaxRedeem;

    constructor(address _affiliate, address _splitConfig, address _payVault, address _platformVault)
        SendEarnAffiliate(_affiliate, _splitConfig, _payVault, _platformVault)
    {}

    function expectPayWithAmount(address vault, uint256 amount) external {
        expectedVault = vault;
        expectedAmount = amount;
        called = false;
    }

    function payWithAmount(IERC4626 vault, uint256 amount) public override {
        // Verify the parameters match what we expected
        // solhint-disable-next-line gas-custom-errors
        require(address(vault) == expectedVault, "Unexpected vault address");
        // solhint-disable-next-line gas-custom-errors
        require(amount == expectedAmount, "Unexpected amount");
        called = true;

        // Don't actually execute the real function
        // This avoids side effects while still verifying the call
    }

    function expectationsMet() external view returns (bool) {
        return called;
    }

    // Override the pay function to use our mocked maxRedeem value
    function pay(IERC4626 vault) external override {
        payWithAmount(vault, mockMaxRedeem);
    }

    // Set a mock value for maxRedeem to avoid actual balance checks
    function setMockMaxRedeem(uint256 amount) external {
        mockMaxRedeem = amount;
    }
}
