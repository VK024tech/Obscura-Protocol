# Obscura Protocol

Obscura Protocol is a zk-SNARK based privacy protocol for unlinkable fixed-denomination ETH transfers.
It combines:
- a Groth16 withdrawal circuit
- Solidity contracts for deposits/withdrawals and Merkle root tracking
- a Next.js frontend for key generation, deposit, scan, and withdraw

## Core Features
- Fixed denomination pool: **1 ETH**
- Merkle commitment tree with root history
- Nullifier-based double-spend protection
- Groth16 proof verification on-chain
- Encrypted withdrawal notes (TweetNaCl box)
- Note storage/retrieval through IPFS (Pinata)
- Frontend UX for:
  - encryption key generation
  - deposit
  - deposit discovery via event scan + note decrypt
  - zk proof generation + withdrawal

## Repository Layout
- `Obscura_Contract/`:
  Foundry smart contract project (Obscura, Merkle tree, verifier, hasher, tests, scripts)
- `Obscura_Frontend/obscura-frontend/`:
  Next.js frontend (RainbowKit + wagmi + viem + snarkjs)
- `circuits/`:
  Circom circuit sources (`Obscura.circom`)
- `build/`:
  Generated proving artifacts (`.r1cs`, `.zkey`, wasm, verification key)
- `generateInput.js`:
  Utility script for local input generation experiments

## Architecture (High Level)
1. User generates receiver keypair in frontend.
2. Depositor creates `secret/nullifier`, computes commitment, encrypts note for receiver, uploads encrypted note to IPFS.
3. Contract stores commitment as a leaf and emits event `(commitment, leafIndex, cid)`.
4. Receiver scans deposit events, fetches/decrypts notes, filters owned + unspent deposits.
5. Frontend reconstructs Merkle proof inputs and generates Groth16 proof in browser (`snarkjs` + wasm/zkey).
6. Withdraw call verifies proof and transfers:
   - recipient amount
   - relayer fee
   - protocol fee

## Contract Layer
Main contract: `Obscura_Contract/src/Obscura.sol`

Important parameters:
- `DEPOSIT_AMOUNT = 1 ether`
- `TREE_DEPTH = 20`
- `FEE_BPS = 20` (0.2%)

Security checks in `withdraw`:
- known root check
- nullifier uniqueness
- relayer caller check (`msg.sender == relayer`)
- recipient/relayer non-zero checks
- signal hash binding to:
  - recipient
  - relayer
  - relayer fee
  - `block.chainid`
  - contract address

Merkle tree logic:
- `Obscura_Contract/src/MerkleTreeWithHistory.sol`
- root history size: `30`

## Frontend Layer
App location: `Obscura_Frontend/obscura-frontend`

Core flows:
- `src/components/generateKeys.tsx`
- `src/components/deposit.tsx`
- `src/components/withdraw.tsx`

Protocol libs:
- `src/lib/mixer.ts` (secret/nullifier + commitment generation)
- `src/lib/deposit.ts` (note encrypt + IPFS upload + contract payload prep)
- `src/lib/findDeposit.ts` (event scan + decrypt + ownership filtering)
- `src/lib/generateProof.ts` (proof input generation + Groth16 proving)

## Prerequisites
- Node.js 18+ (20+ recommended)
- npm
- Foundry (`forge`, `cast`, `anvil`)
- Circom/snarkjs (if regenerating circuit artifacts)

## Environment Variables

### Frontend (`Obscura_Frontend/obscura-frontend/.env.local`)
Required by current code:
- `NEXT_PUBLIC_PROJECTID`
- `NEXT_PUBLIC_ANVIL_ADDRESS`
- `NEXT_PUBLIC_PINATA_JWT`
- `NEXT_PUBLIC_PINATA_GATEWAY`

Optional/used in config files:
- `NEXT_PUBLIC_ANVIL_CHAINID`
- `NEXT_PUBLIC_ANVIL_RPC`
- `NEXT_PUBLIC_SEPOLIA_CHAINID`
- `NEXT_PUBLIC_SEPOLIA_RPC`
- `NEXT_PUBLIC_SEPOLIA_ADDRESS`
- `NEXT_PUBLIC_MAINNET_CHAINID`
- `NEXT_PUBLIC_MAINNET_RPC`
- `NEXT_PUBLIC_MAINNET_ADDRESS`
- `TREE_LEVELS` (defaults to `20`)

### Contract (`Obscura_Contract/.env`)
Used by Foundry endpoints:
- `SEPOLIA_RPC_URL`
- `ANVIL_RPC_URL`

## Local Development

### 1) Start local chain
From `Obscura_Contract/`:
```bash
anvil --code-size-limit 120000 --gas-limit 100000000
```

### 2) Deploy contracts (Foundry scripts)
From `Obscura_Contract/`:
```bash
forge script script/DeployVerifier.s.sol --rpc-url anvil --broadcast
forge script script/DeployHasher.s.sol --rpc-url anvil --broadcast
forge script script/DeployObscura.s.sol --rpc-url anvil --broadcast
```

Notes:
- `DeployObscura.s.sol` currently contains hardcoded verifier/hasher addresses.
- Update those addresses if deployments change.

### 3) Configure frontend env
Set `NEXT_PUBLIC_ANVIL_ADDRESS` to deployed Obscura contract address and add wallet/IPFS vars.

### 4) Start frontend
From `Obscura_Frontend/obscura-frontend/`:
```bash
npm install
npm run dev
```

## Circuit Artifacts
Frontend expects:
- `public/circuits/withdraw.wasm`
- `public/circuits/withdraw_final.zkey`

These files are consumed by `snarkjs.fullProve(...)` during withdraw.

## Testing & Quality

### Contract tests
From `Obscura_Contract/`:
```bash
forge test
```

### Frontend lint
From `Obscura_Frontend/obscura-frontend/`:
```bash
npm run lint
```

## Current Status / Known Issues
- Contract tests currently show many failures related to field-bound checks in test commitments.
- Frontend lint still reports several `no-explicit-any` violations in protocol-facing files.
- `NEXT_PUBLIC_PINATA_JWT` is public at build time by design; move note upload/decrypt sensitive ops to a backend if stronger secrecy is required.
- `src/lib/viemClient.ts` is currently pinned to local anvil RPC (`http://localhost:8545`).

## Security Notes
- Private keys generated in frontend are highly sensitive; never share them.
- Nullifier reuse is prevented on-chain, but note handling/storage hygiene is still critical.
- For production:
  - prefer server-side relayer and private proving infra
  - remove hardcoded deploy addresses
  - harden env/secret handling
  - complete audit and threat modeling



