// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

interface IFeeConfig {
    /// @notice The current fee
    function fee() external view returns (uint96);

    /// @notice Sets the fee
    function setFee(uint256 newFee) external;
}
