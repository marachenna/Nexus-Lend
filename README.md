# NexusLend: Digital Asset Lending Protocol

NexusLend is a decentralized lending protocol built on Stacks that enables users to obtain loans using their digital assets as collateral. The protocol implements a secure, automated lending mechanism with built-in safety features and liquidation protocols.

## Features

- **Collateralized Lending**: Create lending vaults backed by digital assets
- **Flexible Terms**: Customizable APR and loan duration
- **Safety Mechanisms**: Automatic collateral ratio monitoring
- **Collateral Management**: Deposit or withdraw collateral as needed
- **Liquidation Protection**: Clear rules and thresholds for liquidation events

## Technical Specifications

### Key Parameters

- Minimum Collateralization Ratio: 150%
- Maximum APR: 100.00%
- Maximum Term Length: ~1 year (52,560 blocks)
- Maximum Value: 2^128 - 1

### Smart Contract Functions

#### Core Functions

1. `open-vault`
   - Creates a new lending vault
   - Parameters: collateral amount, debt amount, APR, term length
   - Returns: vault ID

2. `deposit-collateral`
   - Adds collateral to an existing vault
   - Parameters: vault ID, deposit amount
   - Returns: new collateral total

3. `withdraw-collateral`
   - Removes collateral from an existing vault
   - Parameters: vault ID, withdrawal amount
   - Returns: withdrawn amount

4. `repay-vault`
   - Repays and closes an existing vault
   - Parameters: vault ID
   - Returns: total amount paid

5. `liquidate-vault`
   - Liquidates an expired vault
   - Parameters: vault ID
   - Returns: success status

#### Query Functions

1. `get-vault-info`
   - Retrieves vault details
   - Parameters: vault ID, owner principal

2. `get-payment-info`
   - Retrieves payment history
   - Parameters: vault ID, owner principal

### Error Codes

- `ERR-NOT-ENOUGH-FUNDS (u100)`: Insufficient funds for operation
- `ERR-NOT-PERMITTED (u101)`: Unauthorized access attempt
- `ERR-VAULT-NOT-FOUND (u102)`: Vault doesn't exist
- `ERR-VAULT-EXISTS (u103)`: Vault already exists
- `ERR-REPAYMENT-FAILED (u104)`: Repayment transaction failed
- `ERR-VAULT-HEALTHY (u105)`: Liquidation not permitted
- `ERR-INVALID-INPUT (u106)`: Invalid parameter values
- `ERR-UNSAFE-RATIO (u107)`: Collateral ratio below threshold

## Development

### Prerequisites

- Clarinet
- Node.js (for testing)
- Stacks blockchain wallet

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/marachenna/nexuslend.git
cd nexuslend
```

2. Install dependencies:
```bash
clarinet install
```

3. Run tests:
```bash
clarinet test
```

### Deployment

1. Update the contract configurations in `Clarinet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy
```

## Security Considerations

- All mathematical operations include overflow checks
- Collateral requirements strictly enforced
- Only vault owners can modify their vaults
- Liquidation requires expired term length
- All state changes are atomic

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
