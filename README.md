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
bun install --yarn --frozen-lockfile
bun run build
```

## Testing

```shell
bun run test
```
