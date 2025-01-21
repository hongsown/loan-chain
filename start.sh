#!/bin/sh

# Set default values for environment variables
MONIKER=${MONIKER:-"loan-validator"}
CHAIN_ID=${CHAIN_ID:-"loan-1"}
MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0stake"}
VALIDATOR_KEY_NAME="val"
STAKE_AMOUNT="10000000stake" # 10M stake tokens

# Initialize chain if not already initialized
if [ ! -d "$HOME/.loan/config" ]; then
    echo "Initializing chain..."
    loand init "$MONIKER" --chain-id "$CHAIN_ID"
    
    # Create validator key
    echo "Creating validator key..."
    echo "password" | loand keys add $VALIDATOR_KEY_NAME --keyring-backend test
    
    # Add genesis account
    echo "Adding genesis account..."
    echo "password" | loand add-genesis-account $VALIDATOR_KEY_NAME $STAKE_AMOUNT --keyring-backend test
    
    # Create genesis validator
    echo "Creating genesis validator..."
    echo "password" | loand gentx $VALIDATOR_KEY_NAME $STAKE_AMOUNT \
        --chain-id "$CHAIN_ID" \
        --moniker "$MONIKER" \
        --commission-max-change-rate 0.01 \
        --commission-max-rate 0.2 \
        --commission-rate 0.1 \
        --min-self-delegation 1 \
        --keyring-backend test
    
    # Collect genesis transactions
    echo "Collecting gentx..."
    loand collect-gentxs
    
    # Validate genesis
    echo "Validating genesis..."
    loand validate-genesis
    
    echo "Configuring chain..."
    # Update config if needed
    if [ ! -z "$SEEDS" ]; then
        sed -i "s/seeds = \"\"/seeds = \"$SEEDS\"/" $HOME/.loan/config/config.toml
    fi
    
    if [ ! -z "$PERSISTENT_PEERS" ]; then
        sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PERSISTENT_PEERS\"/" $HOME/.loan/config/config.toml
    fi
    
    # Cấu hình minimum-gas-prices trong app.toml
    if [ -f "$HOME/.loan/config/app.toml" ]; then
        sed -i "s/minimum-gas-prices = \"\"/minimum-gas-prices = \"$MINIMUM_GAS_PRICES\"/" $HOME/.loan/config/app.toml
        
        # Update app.toml cho API và gRPC
        sed -i 's/enable = false/enable = true/' $HOME/.loan/config/app.toml
        sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' $HOME/.loan/config/app.toml
    else
        echo "Warning: app.toml not found"
    fi
fi

echo "Starting chain..."
# Start chain với minimum gas price
exec loand start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --api.enable true \
    --api.address tcp://0.0.0.0:1317 \
    --minimum-gas-prices "$MINIMUM_GAS_PRICES" 