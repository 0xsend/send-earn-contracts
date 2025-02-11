// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./ISendEarn.sol";
import {ISplitConfig} from "./ISplitConfig.sol";
import {IMetaMorpho} from "metamorpho/interfaces/IMetaMorpho.sol";

interface ISendEarnFactory is ISplitConfig {
    /// @notice The MetaMorpho contract that SendEarn vaults uses.
    function META_MORPHO() external view returns (address);

    /// @notice The default SendEarn vault created with the factory. This vault does not have a referrer.
    function SEND_EARN() external view returns (address);

    /// @notice Tracks existing SendEarn contracts where the affiliate is sharing the fees.
    function affiliates(address) external view returns (address);

    /// @notice Sets the address of the platform that receives Send Earn fees
    function setPlatform(address newPlatform) external;

    /// @notice Sets the split to the referrer.
    function setSplit(uint256 newSplit) external;

    /// @notice Whether a SendEarn vault was created with the factory.
    function isSendEarn(address target) external view returns (bool);

    /// @notice Creates a new SendEarn vault with a referrer.
    /// @param referrer The address of the referrer. Passing address(0) will use the default SendEarn vault.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarn(address referrer, bytes32 salt) external returns (ISendEarn sendEarn);
}
