# PoC for ERC-4337 EntryPoint Gas Accounting Vulnerability

This repository contains a minimal, self-contained Foundry project to demonstrate a critical gas accounting vulnerability in `EntryPoint.sol` (v0.8.0).

The vulnerability allows a malicious actor to drain a paymaster's staked funds by repeatedly forcing its `postOp` function to run out of gas (OOG), causing the `EntryPoint` to charge the paymaster for the full gas stipend instead of the gas actually consumed.

## How to Reproduce

**Prerequisites:**
- [Foundry](https://getfoundry.sh/) must be installed.

1. **Clone the repository:**
   ```sh
   git clone <repository_url>
   cd <repository_directory>
   ```

2. **Install Dependencies:**
   The required libraries (`account-abstraction` and `forge-std`) are included as submodules. To initialize them, run:
   ```sh
   git submodule update --init --recursive
   ```

3. **Run the Test:**
   Execute the specific test file for the PoC:
   ```sh
   forge test --match-path test/EntryPointRealTest.t.sol
   ```

## Expected Outcome

The test `testPostOpOOGDrainOnRealEntryPoint()` should **PASS**. 

This result proves that even when the `handleOps` transaction reverts due to a `postOp` failure, the paymaster's staked funds in the `EntryPoint` are still drained by an amount proportional to the gas stipend. This confirms the economic griefing vulnerability in the real, unmodified `EntryPoint.sol` contract.