// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IPlatform {
    /// @notice The platform address
    function platform() external view returns (address);

    /// @notice Sets the platform address
    function setPlatform(address newPlatform) external;
}
