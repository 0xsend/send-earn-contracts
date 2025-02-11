// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {IMetaMorpho} from "metamorpho/interfaces/IMetaMorpho.sol";

import {ISendEarn} from "./interfaces/ISendEarn.sol";
import {ISendEarnFactory} from "./interfaces/ISendEarnFactory.sol";
import {ISplitConfig} from "./interfaces/ISendEarnAffiliate.sol";

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {SendEarn} from "./SendEarn.sol";
import {SendEarnAffiliate} from "./SendEarnAffiliate.sol";

/// @title SendEarnFactory
/// @author Send Squad
/// @custom:contact security@send.it
/// @notice This contract allows to create SendEarn vaults with a referrer and to index them easily.
contract SendEarnFactory is ISendEarnFactory, Ownable2Step {
    /* IMMUTABLES */

    IMetaMorpho private immutable _META_MORPHO;

    ISendEarn private immutable defaultSendEarn;

    /* STORAGE */

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public isSendEarn;

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public affiliates;

    /// @inheritdoc ISplitConfig
    address public platform;

    /// @inheritdoc ISplitConfig
    uint256 public split;

    /* CONSTRUCTOR */

    /// @dev Initializes the contract.
    /// @param metaMorpho The address of the MetaMorpho contract.
    constructor(address owner, address metaMorpho, bytes32 salt) Ownable(owner) {
        if (metaMorpho == address(0)) revert Errors.ZeroAddress();

        _META_MORPHO = IMetaMorpho(metaMorpho);
        // create the default(no affiliate) send earn contract
        ISendEarn sendEarn = createSendEarn(platform, salt);
        isSendEarn[address(sendEarn)] = true;
        defaultSendEarn = sendEarn;
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

    /// @inheritdoc ISendEarnFactory
    function META_MORPHO() public view returns (address) {
        return address(_META_MORPHO);
    }

    /* EXTERNAL */

    /// @inheritdoc ISendEarnFactory
    function createSendEarn(address feeRecipient, bytes32 salt) public returns (ISendEarn sendEarn) {
        sendEarn = ISendEarn(
            address(
                new SendEarn{salt: salt}(
                    owner(),
                    META_MORPHO(),
                    _META_MORPHO.asset(),
                    string.concat("Send Earn: ", _META_MORPHO.name()),
                    string.concat("se", _META_MORPHO.symbol()),
                    feeRecipient,
                    platform
                )
            )
        );

        isSendEarn[address(sendEarn)] = true;

        emit Events.CreateSendEarn(
            address(sendEarn),
            msg.sender,
            owner(),
            META_MORPHO(),
            _META_MORPHO.asset(),
            string.concat("Send Earn: ", _META_MORPHO.name()),
            string.concat("se", _META_MORPHO.symbol()),
            feeRecipient,
            platform,
            salt
        );
    }

    /// @inheritdoc ISendEarnFactory
    function createSendEarnWithReferrer(address referrer, bytes32 salt) external returns (ISendEarn sendEarn) {
        address feeRecipient = platform;
        if (!affiliates[referrer]) {
            SendEarnAffiliate affiliate = new SendEarnAffiliate(referrer, address(this), address(defaultSendEarn));
            affiliates[referrer] = true;
            emit Events.NewAffiliate(referrer, address(affiliate));
        }
        // create the send earn contract
        sendEarn = createSendEarn(feeRecipient, salt);
    }
}
