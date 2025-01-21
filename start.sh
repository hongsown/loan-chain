#!/bin/sh

# Initialize chain if not already initialized
if [ ! -d "$HOME/.loan/config" ]; then
    loand init ${MONIKER} --chain-id ${CHAIN_ID}
    
    # Update config if needed
    if [ ! -z "$SEEDS" ]; then
        sed -i "s/seeds = \"\"/seeds = \"$SEEDS\"/" $HOME/.loan/config/config.toml
    fi
    
    if [ ! -z "$PERSISTENT_PEERS" ]; then
        sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PERSISTENT_PEERS\"/" $HOME/.loan/config/config.toml
    fi
    
    # Update app.toml for API and gRPC
    sed -i 's/enable = false/enable = true/' $HOME/.loan/config/app.toml
    sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' $HOME/.loan/config/app.toml
fi

# Start the chain
exec loand start --rpc.laddr tcp://0.0.0.0:26657 --api.enable true --api.address tcp://0.0.0.0:1317 