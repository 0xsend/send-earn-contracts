// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface ISplitConfig {
    /// @notice The current split for the platform
    function split() external view returns (uint256);
}

interface IPartnerSplitConfig is ISplitConfig {
    /// @notice The address of the platform
    function platform() external view returns (address);
}
