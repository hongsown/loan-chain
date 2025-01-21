#!/bin/sh

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
    
    # Modify genesis.json directly
    echo "Modifying genesis.json..."
    VALIDATOR_PUBKEY=$(loand tendermint show-validator)
    VALIDATOR_ADDRESS=$(echo "password" | loand keys show validator -a --keyring-backend test)
    
    # Update genesis.json with validator info
    jq ".app_state.auth.accounts += [{
      \"@type\": \"/cosmos.auth.v1beta1.BaseAccount\",
      \"address\": \"$VALIDATOR_ADDRESS\",
      \"pub_key\": null,
      \"account_number\": \"0\",
      \"sequence\": \"0\"
    }]" $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    
    jq ".app_state.bank.balances += [{
      \"address\": \"$VALIDATOR_ADDRESS\",
      \"coins\": [{
        \"denom\": \"stake\",
        \"amount\": \"100000000\"
      }]
    }]" $HOME/.loan/config/genesis.json > temp.json && mv temp.json $HOME/.loan/config/genesis.json
    
    # Create validator transaction
    echo "Creating validator transaction..."
    loand tx staking create-validator \
      --amount=70000000stake \
      --pubkey=$VALIDATOR_PUBKEY \
      --moniker="$MONIKER" \
      --chain-id="$CHAIN_ID" \
      --commission-rate="0.10" \
      --commission-max-rate="0.20" \
      --commission-max-change-rate="0.01" \
      --min-self-delegation="1" \
      --from=validator \
      --keyring-backend=test \
      --broadcast-mode=block \
      -y
fi

# Start the chain
exec loand start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --p2p.laddr tcp://0.0.0.0:26656 \
    --p2p.external-address $(curl -s ifconfig.me):26656 \
    --p2p.seed_mode=false \
    --api.enable \
    --api.address tcp://0.0.0.0:1317 \
    --grpc.address 0.0.0.0:9090 \
    --minimum-gas-prices $MINIMUM_GAS_PRICES