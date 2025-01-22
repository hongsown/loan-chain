#!/bin/bash

# Set default values for environment variables
MONIKER=${MONIKER:-"loan-validator"}
CHAIN_ID=${CHAIN_ID:-"loan-1"}
MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0stake"}

# Initialize chain if not already initialized
if [ ! -d "$HOME/.loan/config" ]; then
    echo "Initializing chain..."
    loand init "$MONIKER" --chain-id "$CHAIN_ID"
    
    # Modify config.toml
    sed -i 's/addr_book_strict = true/addr_book_strict = false/g' $HOME/.loan/config/config.toml
    sed -i 's/external_address = ""/external_address = "tcp:\/\/0.0.0.0:26656"/g' $HOME/.loan/config/config.toml
    
    # Create validator key
    echo "Creating validator key..."
    echo "password" | loand keys add validator --keyring-backend test
    
    # Get validator address
    VALIDATOR_ADDRESS=$(echo "password" | loand keys show validator -a --keyring-backend test)
    
    # Add genesis account
    loand genesis add-genesis-account $VALIDATOR_ADDRESS 1000000000000000stake
    
    # Modify genesis.json
    jq '.app_state.staking.params.bond_denom = "stake"' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    jq '.app_state.staking.params.max_validators = 100' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    jq '.app_state.staking.params.min_commission_rate = "0.000000000000000000"' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    jq '.app_state.crisis.constant_fee.denom = "stake"' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    jq '.app_state.gov.params.min_deposit[0].denom = "stake"' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    jq '.app_state.mint.params.mint_denom = "stake"' $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    
    # Create gentx
    loand genesis gentx validator 700000000stake \
        --chain-id="$CHAIN_ID" \
        --moniker="$MONIKER" \
        --commission-rate="0.10" \
        --commission-max-rate="0.20" \
        --commission-max-change-rate="0.01" \
        --min-self-delegation="1" \
        --keyring-backend=test \
        --yes
    
    # Collect gentxs
    loand genesis collect-gentxs
fi

# Start the chain
exec loand start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --grpc.address 0.0.0.0:9090 \
    --address tcp://0.0.0.0:26656 \
    --minimum-gas-prices 0stake \
    --pruning nothing