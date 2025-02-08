// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

interface ISendEarn {
    function setFeeRecipient(address newFeeRecipient) external;
    /// @notice Sets the collections address, all ERC20 tokens on this contract will be sent to this address
    function setCollections(address newCollections) external;
    /// @notice Transfers ERC20 tokens to the collections address, used mainly for claimed rewards
    function collect(address token) external;
}
