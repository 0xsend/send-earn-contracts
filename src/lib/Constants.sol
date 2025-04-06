// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

uint256 constant WAD = 1e18;

library Constants {
    /// @dev The maximum fee that can be set. (50%)
    uint256 internal constant MAX_FEE = 0.5e18;

    /// @notice the total basis points of the fee split between platform and affiliate
    uint256 public constant SPLIT_TOTAL = WAD;
}
