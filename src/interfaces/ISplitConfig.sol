// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface ISplitConfig {
    /// @notice The address of the platform
    function platform() external view returns (address);
    /// @notice The split for the platform
    function split() external view returns (uint256);
}
