// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

/// @title Errors
/// @author Send Squad
/// @notice Errors for SendEarn
library Errors {
    /// @notice Thrown when the zero address is passed
    error ZeroAddress();
    /// @notice Thrown when a value is already set
    error AlreadySet();
    /// @notice Thrown when max fee is exceeded
    error MaxFeeExceeded();
    /// @notice Thrown when zero fee recipient is set
    error ZeroFeeRecipient();
    /// @notice Thrown when max split is exceeded
    error MaxSplitExceeded();
    /// @notice Thrown when zero amount is passed
    error ZeroAmount();
    /// @notice Thrown when there is an asset mismatch
    error AssetMismatch();
    /// @notice Thrown when the sender is not the platform
    error UnauthorizedPlatform();
    /// @notice Thrown when the sender is not the affiliate
    error UnauthorizedAffiliate();
    /// @notice Thrown when the address is not a SendEarn vault
    error NotSendEarnVault();
}
