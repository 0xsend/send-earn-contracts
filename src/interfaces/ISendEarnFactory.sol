// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./ISendEarn.sol";
import {ISplitConfig} from "./ISplitConfig.sol";
import {IMetaMorpho} from "metamorpho/interfaces/IMetaMorpho.sol";

interface ISendEarnFactory is ISplitConfig {
    /// @notice The MetaMorpho contract that SendEarn vaults uses.
    function META_MORPHO() external view returns (address);

    /// @notice Tracks existing affiliates contracts.
    function affiliates(address) external view returns (bool);

    /// @notice Sets the address of the platform that receives Send Earn fees
    function setPlatform(address newPlatform) external;

    /// @notice Sets the split to the referrer.
    function setSplit(uint256 newSplit) external;

    /// @notice Whether a SendEarn vault was created with the factory.
    function isSendEarn(address target) external view returns (bool);

    /// @notice Creates a new SendEarn vault.
    /// @param feeRecipient The address of the fee recipient.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarn(address feeRecipient, bytes32 salt) external returns (ISendEarn sendEarn);

    /// @notice Creates a new SendEarn vault with a referrer.
    /// @param referrer The address of the referrer.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarnWithReferrer(address referrer, bytes32 salt) external returns (ISendEarn sendEarn);
}
