# SoulBound Protocol — Claude Code Instructions

## Project Context
This is the AGPL-3.0 open source protocol repo for SoulBound Finance.
It contains ONLY on-chain Solidity contracts, Foundry tests, deploy scripts,
and protocol documentation. There is NO frontend, NO backend, NO off-chain
logic in this repo. Ever.

## Tech Stack
- Solidity ^0.8.19
- Foundry (forge, cast, anvil)
- No npm, no node, no hardhat, no JavaScript anywhere

## Architecture (4 contracts + 1 interface)
- SoulBoundToken.sol — Non-transferable identity token (SBT), ZKP commitment,
  EULA gate, nonce tracking
- DepositPool.sol — Multi-token deposits, per-tx EIP-712 fee attestation,
  tiered fees, fee distribution (protocol fee → treasury, OTU + gas → ClaimPool)
- ClaimPool.sol — Operator-processed redemptions, batch processing,
  gas fund management, per-token accounting
- SoulBoundDeployer.sol — Atomic deployment + linking of full system
- ISoulBoundToken.sol — Interface for cross-contract calls

## Hard Rules — NEVER violate these

### 1. Scope Discipline
- NEVER create files outside src/, test/, scripts/, docs/
- NEVER create frontend code, backend code, API code, or off-chain logic
- NEVER create mock data, seed data, stub data, or sample data
- NEVER create placeholder implementations that "fail open" or skip validation
- ASK before creating any new file. Describe what and why. Wait for approval.
- ASK before modifying any file not explicitly mentioned in the current task.

### 2. Code Quality
- NEVER use deprecated Solidity patterns
- NEVER use OpenZeppelin imports — we keep dependencies minimal. If we need
  utility logic, we write it inline or in a library within src/.
- NEVER add console.log, print statements, or debug output to contract code
- NEVER create contracts with constructor args that default to address(0)
  or have fallback behavior that skips security checks
- ALL external/public functions MUST have NatSpec documentation
- ALL state changes MUST follow CEI (Checks-Effects-Interactions) pattern
- ALL custom errors, no require strings (gas optimization)
- ALL access control via explicit modifiers, no inline checks

### 3. Testing
- Tests are in Solidity using Foundry's forge-std
- Test file naming: {Contract}.t.sol
- EVERY public/external function gets at least: happy path, revert case,
  edge case (zero amount, max amount, unauthorized caller)
- Gas snapshots for all core operations (deposit, generateOTU, processRedemption)
- Integration tests cover full lifecycle: deploy → mint SBT → deposit →
  generate OTU → redeem
- NEVER skip a failing test by commenting it out or weakening the assertion
- NEVER create mock contracts that bypass security checks to make tests pass

### 4. Security Posture
- No fail-open patterns. If something can't be verified, revert.
- No unchecked blocks except for counter increments that cannot overflow
- No delegatecall anywhere
- No selfdestruct anywhere
- No tx.origin checks
- EIP-712 signatures must be validated with s-value range check (EIP-2)
  and v-value validation (27 or 28 only)
- ecrecover result must be checked for address(0)

### 5. Communication
- ALWAYS tell me when I'm wrong or there's a better approach. Be direct.
- ALWAYS tell me when a task is unclear or underspecified. Ask before assuming.
- ALWAYS flag if something I'm asking for contradicts the architecture or
  introduces a security risk.
- ALWAYS tell me if I'm wasting tokens on something that could be done
  more efficiently.
- NEVER silently make architectural decisions. Surface them.
- If you see a bug in existing code while working on something else, flag it
  immediately — don't silently fix it or ignore it.

## What This Repo Does NOT Know About
The following exist in the proprietary platform but are NOT part of this repo
and should NEVER be referenced, documented, or implemented here:
- OTU code generation algorithm
- Backend API (Express, routes, middleware)
- Batch timing obfuscation logic
- Multi-resolver service (ENS, handle resolution)
- Geo-blocking / IP filtering
- Frontend (React, Tailwind, any UI)
- Admin dashboard
- Email notifications
- Analytics
- Database schema
- Infrastructure / deployment ops
