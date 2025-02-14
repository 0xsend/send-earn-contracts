// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IMorphoFlashLoanCallback} from "morpho-blue/interfaces/IMorphoCallbacks.sol";
import {IERC20Errors} from "openzeppelin-contracts/interfaces/draft-IERC6093.sol";
import "./helpers/SendEarn.t.sol";

/// @notice ERC4626 vault allowing users to deposit assets to earn yield through MetaMorpho as an underlying vault.
contract ERC4626Test is SendEarnTest, IMorphoFlashLoanCallback {
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    function setUp() public override {
        super.setUp();

        _setCap(allMarkets[0], CAP);
        _sortSupplyQueueIdleLast();
    }

    function testDecimals(uint8 decimals) public {
        vm.mockCall(address(loanToken), abi.encodeWithSignature("decimals()"), abi.encode(decimals));

        sevault = new SendEarn(
            SEND_OWNER,
            address(vault),
            address(loanToken),
            string.concat("Send Earn: ", vault.name()),
            string.concat("se", vault.symbol()),
            address(0),
            address(0),
            0
        );

        assertEq(sevault.decimals(), Math.max(18, decimals), "decimals");
    }

    function testMint(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        uint256 shares = sevault.convertToShares(assets);

        loanToken.setBalance(SUPPLIER, assets);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() + assets);
        vm.prank(SUPPLIER);
        uint256 deposited = sevault.mint(shares, ONBEHALF);

        assertGt(deposited, 0, "deposited");
        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(sevault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(sevault.balanceOf(ONBEHALF), shares, "balanceOf(ONBEHALF)");
        assertEq(morpho.expectedSupplyAssets(allMarkets[0], address(vault)), assets, "expectedSupplyAssets(vault)");
    }

    function testDeposit(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        uint256 shares = sevault.convertToShares(assets);

        loanToken.setBalance(SUPPLIER, assets);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() + assets);
        vm.prank(SUPPLIER);
        uint256 deposited = sevault.deposit(assets, ONBEHALF);

        assertGt(deposited, 0, "deposited");
        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(sevault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(sevault.balanceOf(ONBEHALF), shares, "balanceOf(ONBEHALF)");
        assertEq(vault.balanceOf(address(sevault)), shares, "balanceOf(sevault)");
        assertEq(morpho.expectedSupplyAssets(allMarkets[0], address(vault)), assets, "expectedSupplyAssets(vault)");
    }

    function testRedeem(uint256 deposited, uint256 redeemed) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        redeemed = bound(redeemed, 0, shares);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() - sevault.convertToAssets(redeemed));
        vm.prank(ONBEHALF);
        sevault.redeem(redeemed, RECEIVER, ONBEHALF);

        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(sevault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(vault.balanceOf(address(sevault)), shares - redeemed, "vault.balanceOf(address(sevault))");
        assertEq(sevault.balanceOf(ONBEHALF), shares - redeemed, "balanceOf(ONBEHALF)");
    }

    function testWithdraw(uint256 deposited, uint256 withdrawn) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        withdrawn = bound(withdrawn, 0, deposited);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() - withdrawn);
        vm.prank(ONBEHALF);
        uint256 redeemed = sevault.withdraw(withdrawn, RECEIVER, ONBEHALF);

        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(sevault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(vault.balanceOf(address(sevault)), shares - redeemed, "balanceOf(address(sevault))");
        assertEq(sevault.balanceOf(ONBEHALF), shares - redeemed, "balanceOf(ONBEHALF)");
    }

    function testWithdrawIdle(uint256 deposited, uint256 withdrawn) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        withdrawn = bound(withdrawn, 0, deposited);

        _setCap(allMarkets[0], 0);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.expectEmit();
        emit EventsLib.UpdateLastTotalAssets(sevault.totalAssets() - withdrawn);
        vm.prank(ONBEHALF);
        uint256 redeemed = sevault.withdraw(withdrawn, RECEIVER, ONBEHALF);

        assertEq(loanToken.balanceOf(address(sevault)), 0, "balanceOf(vault)");
        assertEq(loanToken.balanceOf(address(vault)), 0, "balanceOf(vault)");
        assertEq(vault.balanceOf(address(sevault)), shares - redeemed, "vault.balanceOf(address(sevault))");
        assertEq(sevault.balanceOf(ONBEHALF), shares - redeemed, "balanceOf(ONBEHALF)");
        assertEq(_idle(), deposited - withdrawn, "idle");
    }

    function testRedeemTooMuch(uint256 deposited) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited * 2);

        vm.startPrank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);
        vm.stopPrank();

        vm.prank(SUPPLIER);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, SUPPLIER, shares, shares + 1)
        );
        sevault.redeem(shares + 1, RECEIVER, SUPPLIER);
    }

    function testWithdrawAll(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, assets);

        vm.prank(SUPPLIER);
        uint256 minted = sevault.deposit(assets, ONBEHALF);

        assertEq(sevault.maxWithdraw(ONBEHALF), assets, "maxWithdraw(ONBEHALF)");

        vm.prank(ONBEHALF);
        uint256 shares = sevault.withdraw(assets, RECEIVER, ONBEHALF);

        assertEq(shares, minted, "shares");
        assertEq(sevault.balanceOf(ONBEHALF), 0, "balanceOf(ONBEHALF)");
        assertEq(loanToken.balanceOf(RECEIVER), assets, "loanToken.balanceOf(RECEIVER)");
        assertEq(vault.balanceOf(address(sevault)), 0, "vault.balanceOf(address(sevault))");
        assertEq(morpho.expectedSupplyAssets(allMarkets[0], address(vault)), 0, "expectedSupplyAssets(vault)");
    }

    function testRedeemAll(uint256 deposited) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 minted = sevault.deposit(deposited, ONBEHALF);

        assertEq(sevault.maxRedeem(ONBEHALF), minted, "maxRedeem(ONBEHALF)");

        vm.prank(ONBEHALF);
        uint256 assets = sevault.redeem(minted, RECEIVER, ONBEHALF);

        assertEq(assets, deposited, "assets");
        assertEq(sevault.balanceOf(ONBEHALF), 0, "balanceOf(ONBEHALF)");
        assertEq(loanToken.balanceOf(RECEIVER), deposited, "loanToken.balanceOf(RECEIVER)");
        assertEq(vault.balanceOf(address(sevault)), 0, "vault.balanceOf(address(sevault))");
        assertEq(morpho.expectedSupplyAssets(allMarkets[0], address(vault)), 0, "expectedSupplyAssets(vault)");
    }

    function testRedeemNotDeposited(uint256 deposited) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.prank(SUPPLIER);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, SUPPLIER, 0, shares));
        sevault.redeem(shares, SUPPLIER, SUPPLIER);
    }

    function testRedeemNotApproved(uint256 deposited) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        vm.prank(RECEIVER);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, RECEIVER, 0, shares));
        sevault.redeem(shares, RECEIVER, ONBEHALF);
    }

    function testWithdrawNotApproved(uint256 assets) public {
        assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, assets);

        vm.prank(SUPPLIER);
        sevault.deposit(assets, ONBEHALF);

        uint256 shares = sevault.previewWithdraw(assets);
        vm.prank(RECEIVER);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, RECEIVER, 0, shares));
        sevault.withdraw(assets, RECEIVER, ONBEHALF);
    }

    function testTransferFrom(uint256 deposited, uint256 toTransfer) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        toTransfer = bound(toTransfer, 0, shares);

        vm.prank(ONBEHALF);
        sevault.approve(SUPPLIER, toTransfer);

        vm.prank(SUPPLIER);
        sevault.transferFrom(ONBEHALF, RECEIVER, toTransfer);

        assertEq(vault.balanceOf(address(sevault)), shares, "balanceOf(sevault)");
        assertEq(sevault.balanceOf(ONBEHALF), shares - toTransfer, "balanceOf(SUPPLIER)");
        assertEq(sevault.balanceOf(RECEIVER), toTransfer, "balanceOf(RECEIVER)");
        assertEq(sevault.balanceOf(SUPPLIER), 0, "balanceOf(SUPPLIER)");
    }

    function testTransferFromNotApproved(uint256 deposited, uint256 amount) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited, ONBEHALF);

        amount = bound(amount, 0, shares);

        vm.prank(SUPPLIER);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, SUPPLIER, 0, shares));
        sevault.transferFrom(ONBEHALF, RECEIVER, shares);
    }

    function testWithdrawMoreThanBalanceButLessThanTotalAssets(uint256 deposited, uint256 assets) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.startPrank(SUPPLIER);
        uint256 shares = sevault.deposit(deposited / 2, ONBEHALF);
        sevault.deposit(deposited / 2, SUPPLIER);
        vm.stopPrank();

        assets = bound(assets, deposited / 2 + 1, sevault.totalAssets());

        uint256 sharesBurnt = sevault.previewWithdraw(assets);

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, ONBEHALF, shares, sharesBurnt)
        );
        vm.prank(ONBEHALF);
        sevault.withdraw(assets, RECEIVER, ONBEHALF);
    }

    function testWithdrawMoreThanTotalAssets(uint256 deposited, uint256 assets) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);

        assets = bound(assets, deposited + 1, type(uint256).max / (deposited + 1));

        vm.prank(ONBEHALF);
        vm.expectRevert(ErrorsLib.NotEnoughLiquidity.selector);
        sevault.withdraw(assets, RECEIVER, ONBEHALF);
    }

    function testWithdrawMoreThanBalanceAndLiquidity(uint256 deposited, uint256 assets) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);

        assets = bound(assets, deposited + 1, type(uint256).max / (deposited + 1));

        collateralToken.setBalance(BORROWER, type(uint128).max);

        // Borrow liquidity.
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(allMarkets[0], type(uint128).max, BORROWER, hex"");
        morpho.borrow(allMarkets[0], 1, 0, BORROWER, BORROWER);

        vm.startPrank(ONBEHALF);
        vm.expectRevert(ErrorsLib.NotEnoughLiquidity.selector);
        sevault.withdraw(assets, RECEIVER, ONBEHALF);
    }

    function testTransfer(uint256 deposited, uint256 toTransfer) public {
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        uint256 minted = sevault.deposit(deposited, ONBEHALF);

        toTransfer = bound(toTransfer, 0, minted);

        vm.prank(ONBEHALF);
        sevault.transfer(RECEIVER, toTransfer);

        assertEq(sevault.balanceOf(SUPPLIER), 0, "balanceOf(SUPPLIER)");
        assertEq(vault.balanceOf(address(sevault)), minted, "balanceOf(sevault)");
        assertEq(sevault.balanceOf(ONBEHALF), minted - toTransfer, "balanceOf(ONBEHALF)");
        assertEq(sevault.balanceOf(RECEIVER), toTransfer, "balanceOf(RECEIVER)");
    }

    function testMaxWithdraw(uint256 depositedAssets, uint256 borrowedAssets) public {
        depositedAssets = bound(depositedAssets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        borrowedAssets = bound(borrowedAssets, MIN_TEST_ASSETS, depositedAssets);

        loanToken.setBalance(SUPPLIER, depositedAssets);

        vm.prank(SUPPLIER);
        sevault.deposit(depositedAssets, ONBEHALF);

        collateralToken.setBalance(BORROWER, type(uint128).max);

        vm.startPrank(BORROWER);
        morpho.supplyCollateral(allMarkets[0], type(uint128).max, BORROWER, hex"");
        morpho.borrow(allMarkets[0], borrowedAssets, 0, BORROWER, BORROWER);
        vm.stopPrank();
        assertEq(vault.maxWithdraw(address(sevault)), depositedAssets - borrowedAssets, "maxWithdraw(sevault)");
        assertEq(sevault.maxWithdraw(ONBEHALF), depositedAssets - borrowedAssets, "maxWithdraw(ONBEHALF)");
    }

    function testMaxWithdrawFlashLoan(uint256 supplied, uint256 deposited) public {
        supplied = bound(supplied, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
        deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

        loanToken.setBalance(SUPPLIER, supplied);

        vm.prank(SUPPLIER);
        morpho.supply(allMarkets[0], supplied, 0, ONBEHALF, hex"");

        loanToken.setBalance(SUPPLIER, deposited);

        vm.prank(SUPPLIER);
        sevault.deposit(deposited, ONBEHALF);

        assertGt(sevault.maxWithdraw(ONBEHALF), 0);
        assertGt(vault.maxWithdraw(address(sevault)), 0);

        loanToken.approve(address(morpho), type(uint256).max);
        morpho.flashLoan(address(loanToken), loanToken.balanceOf(address(morpho)), hex"");
    }

    function testMaxDeposit() public {
        _setCap(allMarkets[0], 1 ether);

        Id[] memory supplyQueue = new Id[](1);
        supplyQueue[0] = allMarkets[0].id();

        vm.prank(ALLOCATOR);
        vault.setSupplyQueue(supplyQueue);

        loanToken.setBalance(SUPPLIER, 1 ether);
        collateralToken.setBalance(BORROWER, 2 ether);

        vm.prank(SUPPLIER);
        morpho.supply(allMarkets[0], 1 ether, 0, SUPPLIER, hex"");

        vm.startPrank(BORROWER);
        morpho.supplyCollateral(allMarkets[0], 2 ether, BORROWER, hex"");
        morpho.borrow(allMarkets[0], 1 ether, 0, BORROWER, BORROWER);
        vm.stopPrank();

        _forward(1_000);

        loanToken.setBalance(SUPPLIER, 1 ether);

        vm.prank(SUPPLIER);
        sevault.deposit(1 ether, ONBEHALF);

        assertEq(sevault.maxDeposit(SUPPLIER), 0);
        assertEq(vault.maxDeposit(address(sevault)), 0);
        assertEq(sevault.maxMint(SUPPLIER), 0);
        assertEq(vault.maxMint(address(sevault)), 0);
    }

    function onMorphoFlashLoan(uint256, bytes memory) external {
        assertEq(sevault.maxWithdraw(ONBEHALF), 0);
        assertEq(vault.maxWithdraw(address(sevault)), 0);
    }
}
