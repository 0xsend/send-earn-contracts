// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

library Events {
    event SetReferrer(address indexed referred, address indexed referrer);
    event SetFee(address indexed caller, uint256 fee);
    event SetFeeRecipient(address indexed feeRecipient);
    event SetFeeReferral(address indexed caller, uint256 feeReferral);
    event AccrueInterest(uint256 newTotalAssets, uint256 feeShares);
    event UpdateLastTotalAssets(uint256 newTotalAssets);
    event CreateSendEarn(
        address indexed sendEarn,
        address indexed caller,
        address initialOwner,
        address indexed asset,
        string name,
        string symbol,
        bytes32 salt
    );
}
