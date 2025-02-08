// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./interfaces/ISendEarn.sol";
import {ISendEarnFactory} from "./interfaces/ISendEarnFactory.sol";

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";

import {SendEarn} from "./SendEarn.sol";

// TODO: add a way to set the referrer
// TODO: add state variables for tracking affiliates

/// @title SendEarnFactory
/// @author Send Squad
/// @custom:contact security@send.it
/// @notice This contract allows to create SendEarn vaults with a referrer and to index them easily.
contract SendEarnFactory is ISendEarnFactory {
    /* IMMUTABLES */

    /// @inheritdoc ISendEarnFactory
    address public immutable META_MORPHO;

    /* STORAGE */

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public isSendEarn;

    /* CONSTRUCTOR */

    /// @dev Initializes the contract.
    /// @param metaMorpho The address of the MetaMorpho contract.
    constructor(address metaMorpho) {
        if (metaMorpho == address(0)) revert Errors.ZeroAddress();

        META_MORPHO = metaMorpho;
    }

    /* EXTERNAL */

    /// @inheritdoc ISendEarnFactory
    function createSendEarn(
        address initialOwner,
        address asset,
        string memory name,
        string memory symbol,
        address feeRecipient,
        address collections,
        bytes32 salt
    ) external returns (ISendEarn sendEarn) {
        sendEarn = ISendEarn(
            address(new SendEarn{salt: salt}(initialOwner, META_MORPHO, asset, name, symbol, feeRecipient, collections))
        );

        isSendEarn[address(sendEarn)] = true;

        emit Events.CreateSendEarn(
            address(sendEarn), msg.sender, initialOwner, asset, name, symbol, feeRecipient, collections, salt
        );
    }
}
