// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";

import {ISendEarn} from "./interfaces/ISendEarn.sol";
import {ISendEarnFactory} from "./interfaces/ISendEarnFactory.sol";
import {ISplitConfig} from "./interfaces/ISendEarnAffiliate.sol";

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {SendEarn} from "./SendEarn.sol";

/// @title SendEarnFactory
/// @author Send Squad
/// @custom:contact security@send.it
/// @notice This contract allows to create SendEarn vaults with a referrer and to index them easily.
contract SendEarnFactory is ISendEarnFactory, Ownable2Step {
    /* IMMUTABLES */

    /// @inheritdoc ISendEarnFactory
    address public immutable META_MORPHO;

    /* STORAGE */

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public isSendEarn;

    /// @inheritdoc ISendEarnFactory
    mapping(address => address) public affiliates;

    /// @inheritdoc ISplitConfig
    address public platform;

    /// @inheritdoc ISplitConfig
    uint256 public split;

    /* CONSTRUCTOR */

    /// @dev Initializes the contract.
    /// @param metaMorpho The address of the MetaMorpho contract.
    constructor(address owner, address metaMorpho) Ownable(owner) {
        if (metaMorpho == address(0)) revert Errors.ZeroAddress();

        META_MORPHO = metaMorpho;
    }

    /* OWNER ONLY */

    /// @inheritdoc ISendEarnFactory
    function setPlatform(address newPlatform) external onlyOwner {
        if (newPlatform == platform) revert Errors.AlreadySet();
        if (newPlatform == address(0)) revert Errors.ZeroAddress();

        platform = newPlatform;

        emit Events.SetPlatform(newPlatform);
    }

    /// @inheritdoc ISendEarnFactory
    function setSplit(uint256 newSplit) external onlyOwner {
        if (newSplit == split) revert Errors.AlreadySet();
        if (newSplit > Constants.SPLIT_TOTAL) revert Errors.MaxSplitExceeded();

        split = newSplit;

        emit Events.SetSplit(newSplit);
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
    ) public returns (ISendEarn sendEarn) {
        sendEarn = ISendEarn(
            address(new SendEarn{salt: salt}(initialOwner, META_MORPHO, asset, name, symbol, feeRecipient, collections))
        );

        isSendEarn[address(sendEarn)] = true;

        emit Events.CreateSendEarn(
            address(sendEarn), msg.sender, initialOwner, asset, name, symbol, feeRecipient, collections, salt
        );
    }

    /// @inheritdoc ISendEarnFactory
    function createSendEarnWithReferrer(
        address asset,
        string memory name,
        string memory symbol,
        address referrer,
        bytes32 salt
    ) external returns (ISendEarn sendEarn) {
        if (referrer != address(0) && affiliates[referrer] == address(0)) {
            // TODO: create an affiliate contract and set the affiliate address
            // to the new contract
        }
        address feeRecipient = platform;
        address collections = platform;
        // create the send earn contract
        sendEarn = createSendEarn(owner(), asset, name, symbol, feeRecipient, collections, salt);
    }
}
