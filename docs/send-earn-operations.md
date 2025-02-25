# Send Earn Operations

This is an operational guide for the Send Earn protocol. It is intended to be a reference for those who want to understand the protocol and how it works.

## Actors

- Depositor: A user who deposits tokens into a Send Earn vault to earn yield.
- Affiliate: A user who receives a portion of the fees from interest accrued by referring depositors.
- Platform: A multisig wallet that receives platform fees from interest accrued on vaults.
- Collector: A user who collects tokens (dust) from the vaults.
- Owner(Operator): The owner of the Send Earn vault performing state updates on Send Earn contracts.

## Contracts

- SEF: Send Earn Factory - Creates and manages vaults and affiliate relationships
- SEV: Send Earn Vault - ERC4626 vault managing deposits and yield into an underlying vault e.g. MetaMorpho.
- SEA: Send Earn Affiliate - Handles referral relationships and fee splitting

### Actions

#### Depositor Actions
- SEV.deposit: Deposits USDC into vault and receives seUSDC shares
- SEV.withdraw: Burns seUSDC shares to withdraw underlying USDC
- SEV.mint: Mints exact amount of shares by depositing assets
- SEV.redeem: Redeems exact amount of shares for assets
- SEF.createSendEarnAndSetDeposit: Creates new vault with optional referrer
- SEF.deposits: Returns vault address for depositor to deposit

#### Affiliate Actions
- SEA.pay: Triggers payment of accrued fees to affiliate and platform
- SEA.setPayVault: Sets the vault where affiliate receives their earnings
- SEV.withdraw: Withdraws earned fees from affiliate vault
- View affiliate earnings and referred deposits

#### Platform Actions
- SEV.withdraw: Withdraws platform fees from vaults
- SEV.setOwner: Updates vault ownership
- SEF.setOwner: Updates factory ownership
- SEF.setPlatform: Updates platform address
- SEV.setPlatform: Updates platform address for specific vault
- SEF.setFee: Sets default fee for new vaults
- SEF.setSplit: Updates fee split between platform and affiliates

#### Collector Actions
- SEV.collect: Collects dust tokens from vaults to collector address
- View collectible balances

#### Owner/Operator Actions
- SEV.setFeeRecipient: Updates fee recipient for vault
- SEV.setFee: Updates fee percentage for vault
- SEV.setCollections: Updates collector address
- SEF.setFee: Sets protocol-wide default fee
- SEF.setSplit: Sets protocol-wide fee split ratio
- Protocol parameter updates

## Key Operations

### Deposit Flow
1. User deposits USDC to SendEarn vault
2. Vault mints seUSDC shares to user
3. USDC is deployed to MetaMorpho
4. Yield begins accruing

### Fee Distribution Flow
1. Interest accrues on deposits and mints to the fee recipient
2. 6-8% fee taken from yield only
3. For referred deposits:
   - 75% to platform
   - 25% to referrer
4. Fees auto-deposit as shares in respective vaults

### Affiliate Creation Flow
1. New referrer specified during deposit
2. SEF deploys new affiliate contract
3. SEF creates dedicated affiliate vault
4. Deposit processed with referral relationship
