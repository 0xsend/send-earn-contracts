// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {IERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {ISendEarn} from "./interfaces/ISendEarn.sol";
import {ISendEarnFactory} from "./interfaces/ISendEarnFactory.sol";
import {ISplitConfig} from "./interfaces/ISplitConfig.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";

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

    IERC4626 private immutable _vault;

    ISendEarn private immutable _defaultSendEarn;

    /* STORAGE */

    /// @notice The new pending owner when transfering ownership
    address private _pendingOwner;

    /// @inheritdoc ISendEarnFactory
    mapping(address => bool) public isSendEarn;

    /// @inheritdoc ISendEarnFactory
    mapping(address => address) public affiliates;

    /// @inheritdoc IFeeConfig
    uint96 public override fee;

    /// @inheritdoc ISplitConfig
    address public platform;

    /// @inheritdoc ISplitConfig
    uint256 public split;

    /* CONSTRUCTOR */

    /// @dev Initializes the contract.
    /// @param vault The address of the underlying vault contract.
    constructor(address owner, address vault, address _platform, uint96 _fee, uint256 _split, bytes32 salt)
        Ownable(owner)
    {
        if (vault == address(0)) revert Errors.ZeroAddress();
        if (_platform == address(0)) revert Errors.ZeroAddress();

        _vault = IERC4626(vault);
        _setPlatform(_platform);
        _setFee(_fee);
        _setSplit(_split);

        // create the default(no affiliate) send earn contract
        ISendEarn sendEarn = _createSendEarn(platform, salt);
        isSendEarn[address(sendEarn)] = true;
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
    function createSendEarn(address referrer, bytes32 salt) external returns (ISendEarn sendEarn) {
        if (affiliates[referrer] == address(0)) {
            SendEarnAffiliate affiliate =
                new SendEarnAffiliate{salt: salt}(referrer, address(this), address(_defaultSendEarn));
            emit Events.NewAffiliate(referrer, address(affiliate));
            sendEarn = _createSendEarn(address(affiliate), salt);
            affiliates[referrer] = address(sendEarn);
        } else {
            sendEarn = ISendEarn(affiliates[referrer]);
        }
    }

    /* OWNABLE2 AND PLATFORM ONLY */

    /// @notice Only the platform can call this function
    /// @inheritdoc ISendEarnFactory
    function setPlatform(address newPlatform) external onlyPlatform {
        _setPlatform(newPlatform);
    }

    /// @notice Only the platform can call this function
    /// @inheritdoc Ownable2Step
    function transferOwnership(address newOwner) public virtual override onlyPlatform {
        _pendingOwner = newOwner;
        emit Events.OwnershipTransferStarted(owner(), newOwner);
    }

    /// @inheritdoc Ownable2Step
    function pendingOwner() public view virtual override returns (address) {
        return _pendingOwner;
    }

    /// @inheritdoc Ownable2Step
    function acceptOwnership() public virtual override {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        delete _pendingOwner;
        super._transferOwnership(sender);
    }

    /* INTERNAL */

    function _createSendEarn(address feeRecipient, bytes32 salt) internal returns (ISendEarn sendEarn) {
        sendEarn = ISendEarn(
            address(
                new SendEarn{salt: salt}(
                    owner(),
                    VAULT(),
                    _vault.asset(),
                    string.concat("Send Earn: ", _vault.name()),
                    string.concat("se", _vault.symbol()),
                    feeRecipient,
                    platform,
                    fee
                )
            )
        );

        isSendEarn[address(sendEarn)] = true;

        emit Events.CreateSendEarn(address(sendEarn), msg.sender, owner(), VAULT(), feeRecipient, platform, fee, salt);
    }

    function _setFee(uint256 newFee) internal {
        if (newFee == fee) revert Errors.AlreadySet();
        if (newFee > Constants.MAX_FEE) revert Errors.MaxFeeExceeded();
        if (newFee != 0 && platform == address(0)) {
            revert Errors.ZeroFeeRecipient();
        }

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

    function _setPlatform(address newPlatform) internal {
        if (newPlatform == platform) revert Errors.AlreadySet();
        if (newPlatform == address(0)) revert Errors.ZeroAddress();

        platform = newPlatform;

        emit Events.SetPlatform(newPlatform);
    }

    /* MODIFIERS */

    modifier onlyPlatform() {
        if (_msgSender() != platform) revert Errors.UnauthorizedPlatform();
        _;
    }
}
