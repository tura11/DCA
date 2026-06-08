# DCA Protocol

A decentralized Dollar Cost Averaging protocol built on Ethereum.

## What it does

Users deposit ETH and set a position (amount of TKX tokens and interval in seconds). 
Chainlink Automation automatically executes withdrawals at set intervals, 
sending TKX tokens to the user at a fixed rate of 1 ETH = 1000 TKX.

## Contracts

| Contract | Sepolia Address |
|----------|----------------|
| DCA | 0x1eE094020Feb9CE87566a63ED2c78ff67568074a |

## How it works

1. User calls `deposit()` with ETH
2. User calls `setPosition(amount, period)` to set how many TKX per interval
3. Chainlink Automation calls `checkUpkeep()` regularly
4. When interval passes, `performUpkeep()` triggers automatic withdrawal
5. User can also manually call `withdraw()` or `cancel()` to get ETH back

## Tech stack

- Solidity 0.8.30
- Foundry
- OpenZeppelin (SafeERC20)
- Chainlink Automation

## Security considerations

- Reentrancy protection in `cancel()` – state updated before ETH transfer
- `checkUpkeep` is view-only, no state changes
- Fixed exchange rate (1 ETH = 1000 TKX) – in production would use Chainlink Price Feed oracle
- Contract not audited – for educational purposes only

## Run locally

```bash
git clone ...
forge install
forge build
forge test
```

