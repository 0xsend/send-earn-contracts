// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {IERC4626, IERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ISendEarn} from "./interfaces/ISendEarn.sol";
import {ISendEarnFactory} from "./interfaces/ISendEarnFactory.sol";
import {ISplitConfig} from "./interfaces/ISplitConfig.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {SendEarn} from "./SendEarn.sol";
import {Platform} from "./Platform.sol";
import {SendEarnAffiliate} from "./SendEarnAffiliate.sol";

/// @title SendEarnFactory
/// @author Send Squad
/// @custom:contact security@send.it
/// @notice This contract allows to create SendEarn vaults with a referrer and to index them easily.
contract SendEarnFactory is ISendEarnFactory, Platform {
    /* IMMUTABLES */

    IERC4626 private immutable _vault;

    ISendEarn private immutable _defaultSendEarn;

    /* STORAGE */

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public isSendEarn;

    /// @inheritdoc ISendEarnFactory
    mapping(address => address) public affiliates;

    /// @inheritdoc ISendEarnFactory
    mapping(address => address) public deposits;

    /// @inheritdoc IFeeConfig
    uint96 public override fee;

    /// @inheritdoc ISplitConfig
    uint256 public split;

    /* CONSTRUCTOR */

    /// @dev Initializes the contract.
    /// @param vault The address of the underlying vault contract.
    constructor(address owner, address vault, address _platform, uint96 _fee, uint256 _split, bytes32 salt)
        Platform(_platform)
        Ownable(owner)
    {
        if (vault == address(0)) revert Errors.ZeroAddress();
        if (_platform == address(0)) revert Errors.ZeroAddress();
        if (owner == address(0)) revert Errors.ZeroAddress();

        _vault = IERC4626(vault);
        _setFee(_fee);
        _setSplit(_split);

        // create the default(no affiliate) send earn contract
        ISendEarn sendEarn = _createSendEarn(platform(), salt);
        affiliates[address(0)] = address(sendEarn);
        _defaultSendEarn = sendEarn;
    }

    /* OWNER ONLY */

    /// @inheritdoc IFeeConfig
    function setFee(uint256 newFee) public onlyOwner {
        _setFee(newFee);
    }

    /// @inheritdoc ISendEarnFactory
    function setSplit(uint256 newSplit) public onlyOwner {
        _setSplit(newSplit);
    }

    /* EXTERNAL */

    /// @inheritdoc ISendEarnFactory
    function VAULT() public view returns (address) {
        return address(_vault);
    }

    /// @inheritdoc ISendEarnFactory
    function SEND_EARN() external view returns (address) {
        return address(_defaultSendEarn);
    }

    /// @inheritdoc ISendEarnFactory
    function createSendEarn(address referrer, bytes32 salt) public returns (ISendEarn sendEarn) {
        if (affiliates[referrer] == address(0)) {
            // Use deposit vault of referrer as the pay vault if it exists
            // otherwise affiliate will receive the default vault shares
            address payVault = deposits[referrer] != address(0) ? deposits[referrer] : address(_defaultSendEarn);

            // Create new affiliate vault
            SendEarnAffiliate affiliate =
                new SendEarnAffiliate{salt: salt}(referrer, address(this), payVault, address(_defaultSendEarn));
            emit Events.NewAffiliate(referrer, address(affiliate));
            sendEarn = _createSendEarn(address(affiliate), salt);
            affiliates[referrer] = address(sendEarn);
        } else {
            // Use existing affiliate vault
            sendEarn = ISendEarn(affiliates[referrer]);
        }
    }

    /// @inheritdoc ISendEarnFactory
    function setDeposit(address vault) public {
        _setDeposit(msg.sender, vault);
    }

    /// @inheritdoc ISendEarnFactory
    function createAndDeposit(address referrer, bytes32 salt, uint256 assets)
        external
        returns (ISendEarn sendEarn, uint256 shares)
    {
        sendEarn = createSendEarn(referrer, salt);

        // Transfer assets from user to this contract
        address asset = sendEarn.asset();
        IERC20(asset).transferFrom(msg.sender, address(this), assets);
        IERC20(asset).approve(address(sendEarn), assets);

        // Deposit assets into SendEarn on behalf of the user
        shares = sendEarn.deposit(assets, msg.sender);

        // Track deposit for user
        _setDeposit(msg.sender, address(sendEarn));
    }

    /* INTERNAL */

    function _createSendEarn(address feeRecipient, bytes32 salt) internal returns (ISendEarn sendEarn) {
        sendEarn = ISendEarn(
            address(
                new SendEarn{salt: salt}(
                    platform(),
                    owner(),
                    VAULT(),
                    _vault.asset(),
                    string.concat("Send Earn: ", _vault.name()),
                    string.concat("se", _vault.symbol()),
                    feeRecipient,
                    platform(),
                    fee
                )
            )
        );

        isSendEarn[address(sendEarn)] = true;

        emit Events.CreateSendEarn(address(sendEarn), msg.sender, owner(), VAULT(), feeRecipient, platform(), fee, salt);
    }

    function _setFee(uint256 newFee) internal {
        if (newFee == fee) revert Errors.AlreadySet();
        if (newFee > Constants.MAX_FEE) revert Errors.MaxFeeExceeded();
        if (newFee != 0 && platform() == address(0)) revert Errors.ZeroFeeRecipient();

        // Safe "unchecked" cast because newFee <= MAX_FEE.
        fee = uint96(newFee);

        emit Events.SetFee(_msgSender(), fee);
    }

    function _setSplit(uint256 newSplit) internal {
        if (newSplit == split) revert Errors.AlreadySet();
        if (newSplit > Constants.SPLIT_TOTAL) revert Errors.MaxSplitExceeded();

        split = newSplit;

        emit Events.SetSplit(newSplit);
    }

    function _setDeposit(address depositor, address vault) internal {
        if (!isSendEarn[vault]) revert Errors.NotSendEarnVault();
        if (deposits[depositor] == vault) revert Errors.AlreadySet();
        deposits[depositor] = vault;
        emit Events.SetDeposit(vault);
    }
}
