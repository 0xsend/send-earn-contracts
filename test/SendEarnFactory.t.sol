// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./helpers/SendEarn.t.sol";
import {ISendEarn} from "../src/interfaces/ISendEarn.sol";
import {SendEarnFactory} from "../src/SendEarnFactory.sol";
import {SendEarnAffiliate} from "../src/SendEarnAffiliate.sol";
import {Errors} from "../src/lib/Errors.sol";
import {Events} from "../src/lib/Events.sol";
import {Constants} from "../src/lib/Constants.sol";

uint96 constant FEE = 0.08 ether; // 8%
uint256 constant SPLIT = 0.75 ether; // 75%
bytes32 constant SALT = bytes32(uint256(1));

contract SendEarnFactoryTest is SendEarnTest {
    SendEarnFactory internal factory;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    error OwnableUnauthorizedAccount(address account);

    function setUp() public override {
        super.setUp();
        factory = new SendEarnFactory(SEND_OWNER, address(vault), SEND_PLATFORM, FEE, SPLIT, SALT);
        sevault = SendEarn(factory.SEND_EARN());
    }

    function testDefaultSendEarnIsCreated() public {
        if (factory.affiliates(address(0)) == address(0)) revert Errors.ZeroAddress();
        if (factory.SEND_EARN() == address(0)) revert Errors.ZeroAddress();

        assertEq(factory.isSendEarn(address(factory.SEND_EARN())), true, "isSendEarn");
        assertEq(factory.affiliates(address(0)), address(factory.SEND_EARN()), "affiliates");

        ISendEarn sendEarn = ISendEarn(factory.SEND_EARN());
        assertEq(sendEarn.owner(), SEND_OWNER, "SEND_EARN owner");
        assertEq(address(sendEarn.VAULT()), address(vault), "SEND_EARN VAULT");
        assertEq(sendEarn.feeRecipient(), SEND_PLATFORM, "SEND_EARN feeRecipient");
        assertEq(sendEarn.collections(), SEND_PLATFORM, "SEND_EARN collections");
        assertEq(sendEarn.fee(), FEE, "SEND_EARN fee");
    }

    function testCreateSendEarnWithReferrer(address referrer, bytes32 salt) public {
        vm.assume(referrer != address(0));

        bytes32 affiliateInitCodeHash = hashInitCode(
            type(SendEarnAffiliate).creationCode,
            abi.encode(referrer, address(factory), address(factory.SEND_EARN()), address(factory.SEND_EARN()))
        );
        address affiliateExpectedAddress = computeCreate2Address(salt, affiliateInitCodeHash, address(factory));

        bytes32 sendEarnInitCodeHash = hashInitCode(
            type(SendEarn).creationCode,
            abi.encode(
                SEND_PLATFORM,
                SEND_OWNER,
                address(vault),
                address(loanToken),
                string.concat("Send Earn: ", vault.name()),
                string.concat("se", vault.symbol()),
                affiliateExpectedAddress,
                SEND_PLATFORM,
                FEE
            )
        );
        address sendEarnExpectedAddress = computeCreate2Address(salt, sendEarnInitCodeHash, address(factory));

        vm.expectEmit(address(factory));
        emit Events.NewAffiliate(referrer, affiliateExpectedAddress);
        emit Events.CreateSendEarn(
            sendEarnExpectedAddress,
            address(this),
            SEND_OWNER,
            address(vault),
            affiliateExpectedAddress,
            SEND_PLATFORM,
            FEE,
            salt
        );
        ISendEarn sendEarn = factory.createSendEarn(referrer, salt);

        assertEq(sendEarnExpectedAddress, address(sendEarn), "computeCreate2Address");

        assertEq(factory.isSendEarn(address(sendEarn)), true, "isSendEarn");
        assertEq(factory.affiliates(referrer), address(sendEarn), "affiliates");

        assertEq(sendEarn.owner(), SEND_OWNER, "SEND_EARN owner");
        assertEq(address(sendEarn.VAULT()), address(vault), "SEND_EARN VAULT");
        assertEq(sendEarn.feeRecipient(), affiliateExpectedAddress, "SEND_EARN feeRecipient");
        assertEq(sendEarn.collections(), SEND_PLATFORM, "SEND_EARN collections");
        assertEq(sendEarn.fee(), FEE, "SEND_EARN fee");
    }

    function testCreateSendEarnWithReferrerMultiLevel(address referrer, bytes32 salt) public {
        vm.assume(referrer != address(0));

        bytes32 affiliateInitCodeHash = hashInitCode(
            type(SendEarnAffiliate).creationCode,
            abi.encode(referrer, address(factory), address(factory.SEND_EARN()), address(factory.SEND_EARN()))
        );
        address affiliateExpectedAddress = computeCreate2Address(salt, affiliateInitCodeHash, address(factory));

        bytes32 sendEarnInitCodeHash = hashInitCode(
            type(SendEarn).creationCode,
            abi.encode(
                SEND_PLATFORM,
                SEND_OWNER,
                address(vault),
                address(loanToken),
                string.concat("Send Earn: ", vault.name()),
                string.concat("se", vault.symbol()),
                affiliateExpectedAddress,
                SEND_PLATFORM,
                FEE
            )
        );
        address sendEarnExpectedAddress = computeCreate2Address(salt, sendEarnInitCodeHash, address(factory));

        vm.expectEmit(address(factory));
        emit Events.NewAffiliate(referrer, affiliateExpectedAddress);
        emit Events.CreateSendEarn(
            sendEarnExpectedAddress,
            address(this),
            SEND_OWNER,
            address(vault),
            affiliateExpectedAddress,
            SEND_PLATFORM,
            FEE,
            salt
        );
        ISendEarn sendEarn = factory.createSendEarn(referrer, salt);

        assertEq(sendEarnExpectedAddress, address(sendEarn), "computeCreate2Address");

        assertEq(factory.isSendEarn(address(sendEarn)), true, "isSendEarn");
        assertEq(factory.affiliates(referrer), address(sendEarn), "affiliates");

        assertEq(sendEarn.owner(), SEND_OWNER, "SEND_EARN owner");
        assertEq(address(sendEarn.VAULT()), address(vault), "SEND_EARN VAULT");
        assertEq(sendEarn.feeRecipient(), affiliateExpectedAddress, "SEND_EARN feeRecipient");
        assertEq(sendEarn.collections(), SEND_PLATFORM, "SEND_EARN collections");
        assertEq(sendEarn.fee(), FEE, "SEND_EARN fee");
    }

    function testCreateSendEarnWithoutReferrer(bytes32 salt) public {
        vm.recordLogs();
        ISendEarn sendEarn = factory.createSendEarn(address(0), salt);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 0, "no events");

        assertEq(address(sendEarn), address(factory.SEND_EARN()), "factory.SEND_EARN");
        assertEq(sendEarn.owner(), SEND_OWNER, "SEND_EARN owner");
        assertEq(address(sendEarn.VAULT()), address(vault), "SEND_EARN VAULT");
        assertEq(sendEarn.feeRecipient(), SEND_PLATFORM, "SEND_EARN feeRecipient");
        assertEq(sendEarn.collections(), SEND_PLATFORM, "SEND_EARN collections");
        assertEq(sendEarn.fee(), FEE, "SEND_EARN fee");
    }

    function testFactoryAddressZero() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnFactory(SEND_OWNER, address(0), SEND_PLATFORM, FEE, SPLIT, SALT);
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SendEarnFactory(SEND_OWNER, address(vault), address(0), FEE, SPLIT, SALT);
    }

    function testSetFee(uint256 newFee) public {
        newFee = bound(newFee, 0, Constants.MAX_FEE);
        vm.assume(newFee != factory.fee());

        vm.expectEmit(address(factory));
        emit Events.SetFee(SEND_OWNER, newFee);
        vm.prank(SEND_OWNER);
        factory.setFee(newFee);

        assertEq(factory.fee(), newFee, "fee");
    }

    function testSetPlatform(address newPlatform) public {
        vm.assume(newPlatform != address(0));
        vm.assume(newPlatform != SEND_PLATFORM);
        vm.startPrank(SEND_PLATFORM);
        vm.expectEmit(address(factory));
        emit Events.SetPlatform(newPlatform);
        factory.setPlatform(newPlatform);
        assertEq(factory.platform(), newPlatform, "platform");
    }

    function testSetPlatformUnauthorized() public {
        vm.expectRevert(Errors.UnauthorizedPlatform.selector);
        factory.setPlatform(SEND_PLATFORM);
    }

    function testSetPlatformZeroAddress() public {
        vm.startPrank(SEND_PLATFORM);
        vm.expectRevert(Errors.ZeroAddress.selector);
        factory.setPlatform(address(0));
    }

    function testSetSplit(uint256 newSplit) public {
        newSplit = bound(newSplit, 0, Constants.SPLIT_TOTAL);
        vm.assume(newSplit != factory.split());
        vm.startPrank(SEND_OWNER);
        vm.expectEmit(address(factory));
        emit Events.SetSplit(newSplit);
        factory.setSplit(newSplit);
        assertEq(factory.split(), newSplit, "split");
    }

    function testSetSplitMaxExceeded() public {
        vm.startPrank(SEND_OWNER);
        uint256 newSplit = Constants.SPLIT_TOTAL + 1;
        vm.expectRevert(Errors.MaxSplitExceeded.selector);
        factory.setSplit(newSplit);
    }

    function testTransferOwnership(address newOwner) public {
        vm.assume(newOwner != SEND_OWNER);
        vm.expectEmit(address(factory));
        emit OwnershipTransferStarted(SEND_OWNER, newOwner);
        vm.startPrank(SEND_PLATFORM);
        factory.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(factory.pendingOwner(), newOwner, "pendingOwner");

        vm.startPrank(newOwner);
        factory.acceptOwnership();

        assertEq(factory.owner(), newOwner, "owner");
        assertEq(factory.pendingOwner(), address(0), "pendingOwner");
    }

    function testTransferOwnershipZeroAddress() public {
        vm.startPrank(SEND_PLATFORM);
        factory.transferOwnership(address(0));
        vm.stopPrank();
        assertEq(factory.pendingOwner(), address(0), "pendingOwner");
    }

    function testTransferOwnershipUnauthorized() public {
        vm.startPrank(SEND_OWNER);
        vm.expectRevert(Errors.UnauthorizedPlatform.selector);
        factory.transferOwnership(SEND_PLATFORM);
        vm.stopPrank();

        address newOwner = makeAddr("newOwner");
        vm.startPrank(SEND_PLATFORM);
        factory.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(factory.pendingOwner(), newOwner, "pendingOwner");

        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, OWNER));
        factory.acceptOwnership();
    }

    function testCreateAndDeposit(address referrer, bytes32 salt, uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        vm.assume(referrer != address(0));
        vm.assume(referrer != SEND_PLATFORM);

        // Setup caller with assets
        address user = makeAddr("user");
        loanToken.mint(user, assets);

        vm.startPrank(user);
        loanToken.approve(address(factory), assets);

        // Predict the created vault address
        bytes32 affiliateInitCodeHash = hashInitCode(
            type(SendEarnAffiliate).creationCode,
            abi.encode(referrer, address(factory), address(factory.SEND_EARN()), address(factory.SEND_EARN()))
        );
        address affiliateExpectedAddress = computeCreate2Address(salt, affiliateInitCodeHash, address(factory));

        bytes32 sendEarnInitCodeHash = hashInitCode(
            type(SendEarn).creationCode,
            abi.encode(
                SEND_PLATFORM,
                SEND_OWNER,
                address(vault),
                address(loanToken),
                string.concat("Send Earn: ", vault.name()),
                string.concat("se", vault.symbol()),
                affiliateExpectedAddress,
                SEND_PLATFORM,
                FEE
            )
        );
        address sendEarnExpectedAddress = computeCreate2Address(salt, sendEarnInitCodeHash, address(factory));

        // Record logs to check for events
        vm.recordLogs();

        // Call createAndDeposit
        (ISendEarn sendEarn, uint256 shares) = factory.createAndDeposit(referrer, salt, assets);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Verify the returned vault address matches expected
        assertEq(address(sendEarn), sendEarnExpectedAddress, "SendEarn address");

        // Verify the share balance
        assertEq(sendEarn.balanceOf(user), shares, "share balance");

        // Verify deposit was successful
        uint256 expectedShares = sendEarn.convertToShares(assets);
        assertEq(shares, expectedShares, "expected shares");

        // Verify the asset transfer
        assertEq(loanToken.balanceOf(user), 0, "remaining asset balance");
        assertEq(loanToken.balanceOf(address(factory)), 0, "factory asset balance");

        // Verify events were emitted
        bool foundNewAffiliateEvent = false;
        bool foundCreateSendEarnEvent = false;
        bool foundDepositEvent = false;

        for (uint256 i = 0; i < entries.length; i++) {
            // Check for NewAffiliate event
            if (entries[i].topics[0] == keccak256("NewAffiliate(address,address)")) {
                foundNewAffiliateEvent = true;
            }

            // Check for CreateSendEarn event
            if (
                entries[i].topics[0]
                    == keccak256("CreateSendEarn(address,address,address,address,address,address,uint96,bytes32)")
            ) {
                foundCreateSendEarnEvent = true;
            }

            // Check for Deposit event from ERC4626
            if (entries[i].topics[0] == keccak256("Deposit(address,address,uint256,uint256)")) {
                foundDepositEvent = true;
            }
        }

        assertTrue(foundNewAffiliateEvent, "NewAffiliate event not found");
        assertTrue(foundCreateSendEarnEvent, "CreateSendEarn event not found");
        assertTrue(foundDepositEvent, "Deposit event not found");

        vm.stopPrank();
    }

    function testCreateAndDepositWithZeroReferrer(bytes32 salt, uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        // Setup caller with assets
        address user = makeAddr("user");
        loanToken.mint(user, assets);

        vm.startPrank(user);
        loanToken.approve(address(factory), assets);

        // Call createAndDeposit with address(0) referrer
        (ISendEarn sendEarn, uint256 shares) = factory.createAndDeposit(address(0), salt, assets);

        // Verify it's using the default SendEarn
        assertEq(address(sendEarn), address(factory.SEND_EARN()), "default SendEarn");

        // Verify the share balance
        assertEq(sendEarn.balanceOf(user), shares, "share balance");

        // Verify deposit was successful
        uint256 expectedShares = sendEarn.convertToShares(assets);
        assertEq(shares, expectedShares, "expected shares");

        vm.stopPrank();
    }

    function testSetDeposit(address referrer, address referred, bytes32 salt, uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        vm.assume(referrer != address(0));
        vm.assume(referrer != SEND_PLATFORM);
        vm.assume(referred != address(0));
        vm.assume(referred != SEND_PLATFORM);
        vm.assume(referred != referrer);

        // create referrer vault for referred to deposit into
        vm.startPrank(referred);
        loanToken.mint(referred, assets);
        loanToken.approve(address(factory), assets);
        factory.createAndDeposit(referrer, salt, assets);
        vm.stopPrank();

        // Test setting deposit for referred back to default vault
        vm.startPrank(referred);
        vm.expectEmit(address(factory));
        emit Events.SetDeposit(address(sevault));
        factory.setDeposit(address(sevault));
        vm.stopPrank();

        assertEq(factory.deposits(referred), address(sevault), "deposits(referred)");
    }

    function testSetDepositRevertNotSendEarnVault(address user, address invalidVault) public {
        vm.assume(user != address(0));
        vm.assume(!factory.isSendEarn(invalidVault));

        vm.prank(user);
        vm.expectRevert(Errors.NotSendEarnVault.selector);
        factory.setDeposit(invalidVault);
    }

    function testSetDepositRevertAlreadySet(address user, bytes32 salt) public {
        vm.assume(user != address(0));
        vm.assume(user != SEND_PLATFORM);

        // Create a SendEarn vault and set it as deposit
        ISendEarn sendEarn = factory.createSendEarn(user, salt);
        vm.prank(user);
        factory.setDeposit(address(sendEarn));

        // Try setting same vault again
        vm.prank(user);
        vm.expectRevert(Errors.AlreadySet.selector);
        factory.setDeposit(address(sendEarn));
    }

    function testCreateSendEarnWithReferrerDeposit(address referrer, bytes32 salt) public {
        vm.assume(referrer != address(0));

        // Create a SendEarn vault and set it as referrer's deposit
        ISendEarn depositVault = factory.createSendEarn(makeAddr("other"), salt);
        vm.prank(referrer);
        factory.setDeposit(address(depositVault));

        // Create new SendEarn with referrer
        bytes32 newSalt = keccak256(abi.encodePacked(salt));
        ISendEarn sendEarn = factory.createSendEarn(referrer, newSalt);

        // Get the affiliate contract
        address affiliate = sendEarn.feeRecipient();
        SendEarnAffiliate affiliateContract = SendEarnAffiliate(affiliate);

        // Verify affiliate was created with correct pay vault
        assertEq(address(affiliateContract.payVault()), address(depositVault), "incorrect pay vault");
    }

    function testCreateSendEarnWithReferrerNoDeposit(address referrer, bytes32 salt) public {
        vm.assume(referrer != address(0));
        vm.assume(factory.deposits(referrer) == address(0));

        ISendEarn sendEarn = factory.createSendEarn(referrer, salt);

        // Get the affiliate contract
        address affiliate = sendEarn.feeRecipient();
        SendEarnAffiliate affiliateContract = SendEarnAffiliate(affiliate);

        // Verify affiliate was created with default pay vault
        assertEq(address(affiliateContract.payVault()), address(factory.SEND_EARN()), "incorrect pay vault");
    }
}
