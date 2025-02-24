// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IPlatform} from "./interfaces/IPlatform.sol";
import {Errors} from "./lib/Errors.sol";
import {Events} from "./lib/Events.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @title Platform is an abstract contract that adds a way for a platform to ensure some functionality is only called by the platform. Notably transferring ownership.
 * @author Send Squad
 * @notice Platform is used to ensure that there is two tiered ownership of the contract where owners can perform some actions but not others and especially not transferring ownership.
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Platform is IPlatform, Ownable {
    /* STORAGE */

    /// @notice The new pending owner when transfering ownership
    address private _pendingOwner;

    /// @notice The platform address
    address private _platform;

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialPlatform) {
        if (initialPlatform == address(0)) revert Errors.ZeroAddress();
        _setPlatform(initialPlatform);
    }

    /* OWNABLE2 AND PLATFORM ONLY */

    /// @notice Only the platform can call this function
    /// @inheritdoc IPlatform
    function setPlatform(address newPlatform) external onlyPlatform {
        if (newPlatform == platform()) revert Errors.AlreadySet();
        _setPlatform(newPlatform);
        emit Events.SetPlatform(newPlatform);
    }

    /**
     * @notice Only the platform can call this function
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     *
     * Setting `newOwner` to the zero address is allowed; this can be used to cancel an initiated ownership transfer.
     */
    function transferOwnership(address newOwner) public virtual override onlyPlatform {
        if (newOwner == owner()) revert Errors.AlreadySet();
        _pendingOwner = newOwner;
        emit Events.OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) revert OwnableUnauthorizedAccount(sender);
        delete _pendingOwner;
        super._transferOwnership(sender);
    }

    /* EXTERNAL */

    /**
     * @dev Returns the address of the platform.
     */
    function platform() public view virtual override returns (address) {
        return _platform;
    }

    /* INTERNAL */

    function _setPlatform(address newPlatform) internal {
        if (newPlatform == platform()) revert Errors.AlreadySet();
        if (newPlatform == address(0)) revert Errors.ZeroAddress();

        _platform = newPlatform;

        emit Events.SetPlatform(newPlatform);
    }

    /* MODIFIERS */

    modifier onlyPlatform() {
        if (_msgSender() != platform()) revert Errors.UnauthorizedPlatform();
        _;
    }
}
