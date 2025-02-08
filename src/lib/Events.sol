// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

library Events {
    event SetFee(address indexed caller, uint256 fee);
    event SetFeeRecipient(address indexed feeRecipient);
    event SetCollections(address indexed collections);
    event Collect(address indexed caller, address indexed token, uint256 amount);
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
