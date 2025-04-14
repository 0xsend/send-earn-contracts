# Deploy Send Earn

## Localnet

Deploys using the test x11 junk mnemonic. The vault is the mwUSDC metamorpho vault and the platform is the revenues Send multisig.

The starting total fee is 8%, and the split is 75% to the platform, 25% to the affiliate.

```shell
export OWNER=0xb4AdA291C62ca91a1160eC1DF4bC50f47D7e02e3
export VAULT=0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca
export PLATFORM=0x65049C4B8e970F5bcCDAE8E141AA06346833CeC4
export FEE=$(cast to-wei 0.08 ether)
export SPLIT=$(cast to-wei 0.75 ether)
export SALT=$(echo SEND IT | cast keccak)
export ASSET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
export INITIAL_BURN=10000
export INITIAL_BURN_PREFUND=5000000
forge script ./script/DeploySendEarn.s.sol:DeploySendEarnScript \
  -vvvv \
  --verify \
  --broadcast
```
