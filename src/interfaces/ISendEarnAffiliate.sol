// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {IPartnerSplitConfig} from "./ISplitConfig.sol";

interface ISendEarnAffiliate {
    /// @notice The address of the affiliate split config.
    function splitConfig() external view returns (IPartnerSplitConfig);
    /// @notice The address of the affiliate receiving the earnings.
    function affiliate() external view returns (address);
    /// @notice The address of the vault that earnings are paid to on behalf of the platform.
    function platformVault() external view returns (IERC4626);
    /// @notice The address of the vault that earnings are paid to on behalf of the affiliate.
    function payVault() external view returns (IERC4626);
    /// @notice Pays out the earnings to the platform and affiliate.
    /// @dev Callable by anyone to trigger payout of earnings for ease-of-operations.
    function pay(IERC4626 vault) external;
    /// @notice Pays out an amount of earnings to the platform and affiliate for a given vault.
    /// @dev Callable by anyone to trigger payout of earnings for ease-of-operations.
    function payWithAmount(IERC4626 vault, uint256 amount) external;
    /// @notice Sets the pay vault.
    function setPayVault(address vault) external;
}
