# Send Earn

Send Earn is a permissionless, non-custodial way for users to deposit their USDC into a vault and earn yield on their USDC. Send Earn is a vault-on-a-vault solution powered by Morpho and Moonwell. Users deposit their USDC into a Send Earn USDC (seUSDC) vault. In turn, the vault deposits the vault's assets into a Moonwell USDC (mwUSDC) vault. Users can also withdraw their USDC from the vault at any time.

Send Earn's pioneering approach is to reward users for referring others to use Send Earn.

See [docs/send-earn-about.md](docs/send-earn-about.md) for more information.

## Quick Start

- Install [Foundry](https://github.com/foundry-rs/foundry)
- Install [bun](https://bun.sh/)

```shell
git clone https://github.com/0xsend/send-earn-contracts.git
cd send-earn-contracts
forge install
bun install --yarn
bun run build
```

## Deploy

Jump to Localnet Deployment if needing to deploy to a local network for testing.

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
forge script ./script/DeploySendEarn.s.sol:DeploySendEarnScript \
  -vvvv \
  --rpc-url http://localhost:8546 \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

### Localnet Deployment

Need to transfer some USDC to the owner account so we can set initial burn amount.

```shell
export OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export USDC_HOLDER=0x27a16dc786820B16E5c9028b75B99F6f604b5d26
export ASSET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
cast rpc anvil_impersonateAccount $USDC_HOLDER --rpc-url http://localhost:8546
cast send $ASSET \
  --from $USDC_HOLDER \
  --rpc-url http://localhost:8546 \
  "transfer(address,uint256)(bool)" \
  $OWNER \
  10000000 \
  --unlocked
# blockHash               0xbf31c45f6935a0714bb4f709b5e3850ab0cc2f8bffe895fefb653d154e0aa062
# blockNumber             15052891
# ...
```

## Contributing

Ensure your tests are passing before submitting a PR.

```shell
bun run test
```

Update the snapshots and test coverage:

```shell
bun run test:update
```

Lint the code:

```shell
bun run lint:fix
```

Make a release:

```shell
bunx changeset
```

Create a new version of the package:

```shell
bunx changeset version
```

Commit and push the changes:

```shell
git add .
git commit -m "chore: Version bump"
git push
```

Create a new release on [GitHub](https://github.com/0xsend/send-earn-contracts/actions/workflows/npm-release.yml) and [npm](https://www.npmjs.com/package/@0xsend/send-earn-contracts). The release will be automatically published to [npm](https://www.npmjs.com/package/@0xsend/send-earn-contracts).
