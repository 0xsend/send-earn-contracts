// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address) external;
    function renounceOwnership() external;
    function acceptOwnership() external;
    function pendingOwner() external view returns (address);
}
