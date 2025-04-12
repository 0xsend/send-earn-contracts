# Deploying Localnet

```shell
export OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export VAULT=0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca
export PLATFORM=0x65049C4B8e970F5bcCDAE8E141AA06346833CeC4
export FEE=$(cast to-wei 0.08 ether)
export SPLIT=$(cast to-wei 0.80 ether)
export SALT=$(echo SEND IT | cast keccak)
export ASSET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
export INITIAL_BURN=10000
export INITIAL_BURN_PREFUND=5000000
export USDC_HOLDER=0x27a16dc786820B16E5c9028b75B99F6f604b5d26
export ASSET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
export FACTORY=0x5a11492a244920ed0c5f440d13088da21fdf99c1
cast rpc anvil_impersonateAccount $USDC_HOLDER --rpc-url http://localhost:8546

# Transfer USDC to Owner
cast send $ASSET \
  --from $USDC_HOLDER \
  --rpc-url http://localhost:8546 \
  "transfer(address,uint256)(bool)" \
  $OWNER \
  10000000 \
  --unlocked

# Deploy SendEarnFactory
forge script ./script/DeploySendEarn.s.sol:DeploySendEarnScript \
  -vvvv \
  --rpc-url http://localhost:8546 \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```
