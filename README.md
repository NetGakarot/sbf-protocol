# SBF Protocol

Privacy-preserving payment protocol. On-chain primitive for anonymous, cash-like digital asset transfers with regulatory compatibility.

Built by [Soulbound Security](https://soulboundsecurity.io).

## Overview

SBF Protocol enables privacy-preserving transfers through a deposit/claim pool architecture gated by non-transferable Soulbound Tokens (SBTs). Users deposit supported tokens, generate One-Time-Use (OTU) withdrawal codes off-chain, and recipients redeem anonymously — no on-chain link between depositor and redeemer.

**Core properties:**

- **Minimum Attributability** — KYC verification at deposit via ZKP commitment, anonymous redemption via OTU bearer instruments
- **Per-Transaction Fee Attestation** — EIP-712 signed attestation of purpose (charitable/commercial) per OTU, not per user. Immutable on-chain record. Game theory over admin approval.
- **Multi-Token** — USDC, USDT, WBTC, ETH at launch. Token whitelist controlled by multisig.
- **Stateless Redemption** — Recipient addresses are ephemeral. No recipient data stored on-chain or off-chain beyond the redemption transaction itself.

## Architecture

```
┌──────────────────────┐
│   SoulBoundToken     │  Identity layer. Non-transferable. ZKP commitment.
│   (SBT)              │  EULA gate on mint. Nonce tracks OTU generation.
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│   DepositPool        │  Inflow. Multi-token deposits. Per-tx EIP-712
│                      │  fee attestation. Splits fees on OTU generation:
│                      │    Protocol fee → Treasury (direct)
│                      │    OTU + gas fee → ClaimPool
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│   ClaimPool          │  Outflow. Operator-processed redemptions.
│                      │  Batch processing for timing obfuscation.
│                      │  Gas fund for future DeFi operations.
└──────────────────────┘

Deployment: SoulBoundDeployer — atomic deploy + link in single tx.
```

## Fee Model

Fees are charged **on top** of the OTU face value, not deducted from it.

| Tier | Protocol Fee | Gas Fee | Total | Status |
|------|-------------|---------|-------|--------|
| Charitable / Donation / Gift | 1.00% | 0.25% | 1.25% | Active |
| Commercial / Enterprise | 2.00% | 0.25% | 2.25% | Disabled at launch |

Fee tier is selected **per transaction** via EIP-712 signed attestation. The user cryptographically attests to the purpose of each OTU on an immutable ledger. No admin approval. No oracle. Pure game theory — individuals self-select freely; businesses will never sign a false charitable attestation on-chain.

Gas fee (0.25%) is immutable. Protocol fees are adjustable by controller multisig, capped at 5%.

## Repository Structure

```
sbf-protocol/
├── src/
│   ├── SoulBoundToken.sol
│   ├── DepositPool.sol
│   ├── ClaimPool.sol
│   ├── SoulBoundDeployer.sol
│   └── interfaces/
│       └── ISoulBoundToken.sol
├── test/
├── scripts/
├── docs/
│   └── PROTOCOL_SPEC.md
├── audits/
├── CLAUDE.md
├── foundry.toml
├── LICENSE
└── README.md
```

## Development

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

```bash
# Clone
git clone https://github.com/SoulboundSecurity/sbf-protocol.git
cd sbf-protocol

# Build
forge build

# Test
forge test

# Gas report
forge test --gas-report
```

## Deployment

Target chain: **Arbitrum One** (mainnet) / **Arbitrum Sepolia** (testnet).

```bash
# Deploy full system atomically
forge script scripts/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

## Security

This protocol has not yet been audited. Use at your own risk.

To report a vulnerability: **info@soulboundsecurity.io**

## Links

- **Website:** [soulboundsecurity.io](https://soulboundsecurity.io)
- **App:** [soulbound.finance](https://soulbound.finance)
- **Twitter:** [@soulboundsec](https://twitter.com/soulboundsec)
- **Contact:** info@soulboundsecurity.io

## License

AGPL-3.0 — see [LICENSE](LICENSE).

© Soulbound Security LTD 2026