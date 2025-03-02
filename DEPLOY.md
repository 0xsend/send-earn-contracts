# Deploy Send Earn

## Localnet

Deploys using the test x11 junk mnemonic. The vault is the mwUSDC metamorpho vault and the platform is the revenues Send multisig.

The starting total fee is 8%, and the split is 75% to the platform, 25% to the affiliate.

```shell
export OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export VAULT=0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca
export PLATFORM=0x65049C4B8e970F5bcCDAE8E141AA06346833CeC4
export FEE=$(cast to-wei 0.08 ether)
export SPLIT=$(cast to-wei 0.75 ether)
export SALT=$(echo SEND IT | cast keccak)
forge script ./script/DeploySendEarn.s.sol:DeploySendEarnScript \
  -vvvv \
  --rpc-url http://localhost:8546 \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```
