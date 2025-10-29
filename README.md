# Flash Loan Contract

A Solidity smart contract implementation for executing flash loans using Aave v3 protocol. This project demonstrates how to borrow assets without collateral, execute custom logic, and repay the loan within a single transaction.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Running Tests](#running-tests)
  - [Deploying the Contract](#deploying-the-contract)
  - [Interacting with the Contract](#interacting-with-the-contract)
- [Contract Details](#contract-details)
- [Supported Networks](#supported-networks)
- [Security Considerations](#security-considerations)
- [License](#license)

## Overview

Flash loans allow you to borrow any available amount of assets without putting up collateral, as long as the liquidity is returned to the protocol within one block transaction. This implementation uses Aave v3's flash loan functionality.

## Features

- Execute flash loans on multiple networks (Ethereum, Polygon, Arbitrum, etc.)
- Owner-controlled fund management
- Comprehensive test suite with unit and integration tests
- Multi-network deployment script
- Support for any ERC20 token available on Aave v3

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js (optional, for additional tooling)
- An RPC URL for the network you want to deploy to (Alchemy, Infura, etc.)
- A wallet with funds for deployment and gas fees

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flash-loan
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

## Configuration

1. Copy the environment example file:
```bash
cp .env.example .env
```

2. Edit `.env` and add your configuration:
```env
# Your private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key

# API keys for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Usage

### Running Tests

Run all tests:
```bash
forge test
```

Run tests with detailed output:
```bash
forge test -vvv
```

Run specific test:
```bash
forge test --match-test test_Deployment
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

Run integration tests with Sepolia fork:
```bash
forge test --fork-url $SEPOLIA_RPC_URL -vvv
```

Run tests for a specific contract:
```bash
forge test --match-contract FlashLoanTest
```

### Deploying the Contract

Deploy to Sepolia testnet:
```bash
forge script script/FlashLoan.s.sol:FlashLoanScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

Deploy to Ethereum mainnet:
```bash
forge script script/FlashLoan.s.sol:FlashLoanScript \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify
```

Deploy to other networks (Polygon, Arbitrum, etc.):
```bash
forge script script/FlashLoan.s.sol:FlashLoanScript \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast \
  --verify
```

Simulate deployment without broadcasting:
```bash
forge script script/FlashLoan.s.sol:FlashLoanScript \
  --rpc-url $SEPOLIA_RPC_URL
```

### Interacting with the Contract

#### Request a Flash Loan

Using cast:
```bash
cast send <CONTRACT_ADDRESS> \
  "requestFlashLoan(address,uint256)" \
  <TOKEN_ADDRESS> \
  <AMOUNT> \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

Example (request 100 DAI on Sepolia):
```bash
cast send 0xYourContractAddress \
  "requestFlashLoan(address,uint256)" \
  0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357 \
  100000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Check Token Balance

```bash
cast call <CONTRACT_ADDRESS> \
  "getBalance(address)(uint256)" \
  <TOKEN_ADDRESS> \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Withdraw Tokens (Owner Only)

```bash
cast send <CONTRACT_ADDRESS> \
  "withdraw(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Contract Details

### Main Contract: FlashLoan.sol

**Key Functions:**

- `requestFlashLoan(address _asset, uint256 _amount)` - Initiates a flash loan
- `executeOperation(...)` - Callback function executed during the flash loan (add your custom logic here)
- `getBalance(address _asset)` - Returns the contract's balance of a specific token
- `withdraw(address _asset)` - Allows owner to withdraw tokens from the contract
- `receive()` - Allows the contract to receive ETH

**Inherited From:**
- `FlashLoanSimpleReceiverBase` - Aave v3 base contract for flash loan receivers

### Test Suite

**FlashLoanTest** - Unit tests covering:
- Contract deployment
- Owner access control
- Balance checking
- Withdrawal functionality
- ETH reception
- Fuzz testing

**FlashLoanIntegrationTest** - Integration tests:
- Real flash loan execution on forked networks
- Full transaction flow testing

## Supported Networks

The deployment script automatically configures the correct Aave v3 Pool Addresses Provider for:

| Network | Chain ID | Pool Addresses Provider |
|---------|----------|------------------------|
| Ethereum Mainnet | 1 | 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e |
| Sepolia Testnet | 11155111 | 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A |
| Polygon | 137 | 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb |
| Arbitrum | 42161 | 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb |
| Optimism | 10 | 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb |
| Avalanche | 43114 | 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb |

## Security Considerations

⚠️ **Important Security Notes:**

1. **Flash Loan Logic**: The current `executeOperation` function is a basic implementation. Add your custom arbitrage, liquidation, or other logic here.

2. **Fund Management**: Ensure the contract has enough tokens to pay the flash loan premium (typically 0.05% - 0.09% of the borrowed amount).

3. **Access Control**: Only the owner can withdraw funds. Keep your private key secure.

4. **Approval**: The contract approves the Aave pool to spend the borrowed amount plus premium. This is necessary for repayment.

5. **Testing**: Always test on testnets (like Sepolia) before deploying to mainnet.

6. **Reentrancy**: Consider adding reentrancy guards if implementing complex logic in `executeOperation`.

7. **Price Manipulation**: Be aware of oracle manipulation attacks when implementing arbitrage strategies.

## Example Use Cases

Flash loans can be used for:

1. **Arbitrage**: Profit from price differences across DEXs
2. **Collateral Swap**: Change your collateral type on lending platforms
3. **Self-Liquidation**: Close your own position before liquidation
4. **Debt Refinancing**: Move debt from one protocol to another

## Development

### Project Structure

```
flash-loan/
├── src/
│   └── FlashLoan.sol          # Main flash loan contract
├── script/
│   └── FlashLoan.s.sol        # Deployment script
├── test/
│   └── FlashLoan.t.sol        # Test suite
├── lib/                        # Dependencies (forge-std, aave-v3-core, etc.)
├── foundry.toml               # Foundry configuration
└── README.md
```

### Adding Custom Logic

To add your custom logic to the flash loan, edit the `executeOperation` function in [src/FlashLoan.sol](src/FlashLoan.sol):

```solidity
function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
) external override returns (bool) {
    // Your custom logic here
    // Example: Arbitrage, liquidation, collateral swap, etc.

    // Calculate amount to repay
    uint256 amountOwed = amount + premium;

    // Approve the pool to pull the funds
    IERC20(asset).approve(address(POOL), amountOwed);

    return true;
}
```

## Troubleshooting

**Tests failing with "EvmError: Revert":**
- Ensure you have the correct RPC URL configured
- Check that the flash loan has funds to pay the premium

**Deployment failing:**
- Verify your private key is correct in `.env`
- Ensure your wallet has enough ETH for gas fees
- Check the RPC URL is working

**"Unsupported network" error:**
- The script only supports networks listed in the table above
- For custom networks, use the `runWithCustomProvider` function

## Resources

- [Aave v3 Documentation](https://docs.aave.com/developers/core-contracts/pool)
- [Foundry Book](https://book.getfoundry.sh/)
- [Flash Loans Overview](https://docs.aave.com/developers/guides/flash-loans)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This code is provided as-is for educational purposes. Use at your own risk. Always audit smart contracts before deploying to mainnet with real funds.
