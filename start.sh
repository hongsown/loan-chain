#!/bin/sh

# Set default values for environment variables
MONIKER=${MONIKER:-"loan-validator"}
CHAIN_ID=${CHAIN_ID:-"loan-1"}
MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-"0stake"}
STAKE_AMOUNT="1000000000000000"

# Initialize chain if not already initialized
if [ ! -d "$HOME/.loan/config" ]; then
    echo "Initializing chain..."
    loand init "$MONIKER" --chain-id "$CHAIN_ID"
    
    # Create validator key
    echo "Creating validator key..."
    echo "password" | loand keys add validator --keyring-backend test
    
    # Get addresses
    VALIDATOR_ACCOUNT_ADDRESS=$(echo "password" | loand keys show validator -a --keyring-backend test)
    VALIDATOR_OPERATOR_ADDRESS=$(echo "password" | loand keys show validator --bech val -a --keyring-backend test)
    VALIDATOR_PUBKEY=$(loand tendermint show-validator)
    
    # Get module account addresses
    BONDED_TOKENS_POOL="cosmos1fl48vsnmsdzcv85q5d2q4z5ajdha8yu34mf0eh"
    
    # Modify genesis.json directly
    echo "Modifying genesis.json..."
    
    # Update genesis.json
    cat > $HOME/.loan/config/genesis.json << EOF
{
  "genesis_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "chain_id": "$CHAIN_ID",
  "initial_height": "1",
  "consensus_params": {
    "block": {
      "max_bytes": "22020096",
      "max_gas": "-1",
      "time_iota_ms": "1000"
    },
    "evidence": {
      "max_age_num_blocks": "100000",
      "max_age_duration": "172800000000000",
      "max_bytes": "1048576"
    },
    "validator": {
      "pub_key_types": [
        "ed25519"
      ]
    },
    "version": {}
  },
  "app_hash": "",
  "app_state": {
    "auth": {
      "params": {
        "max_memo_characters": "256",
        "tx_sig_limit": "7",
        "tx_size_cost_per_byte": "10",
        "sig_verify_cost_ed25519": "590",
        "sig_verify_cost_secp256k1": "1000"
      },
      "accounts": [
        {
          "@type": "/cosmos.auth.v1beta1.BaseAccount",
          "address": "$VALIDATOR_ACCOUNT_ADDRESS",
          "pub_key": null,
          "account_number": "0",
          "sequence": "0"
        }
      ]
    },
    "bank": {
      "params": {
        "send_enabled": [],
        "default_send_enabled": true
      },
      "balances": [
        {
          "address": "$BONDED_TOKENS_POOL",
          "coins": [
            {
              "denom": "stake",
              "amount": "$STAKE_AMOUNT"
            }
          ]
        }
      ],
      "supply": [
        {
          "denom": "stake",
          "amount": "$STAKE_AMOUNT"
        }
      ],
      "denom_metadata": []
    },
    "staking": {
      "params": {
        "unbonding_time": "1814400s",
        "max_validators": 100,
        "max_entries": 7,
        "historical_entries": 10000,
        "bond_denom": "stake",
        "min_commission_rate": "0.000000000000000000"
      },
      "last_total_power": "1000000",
      "last_validator_powers": [
        {
          "address": "$VALIDATOR_OPERATOR_ADDRESS",
          "power": "1000000"
        }
      ],
      "validators": [
        {
          "operator_address": "$VALIDATOR_OPERATOR_ADDRESS",
          "consensus_pubkey": $VALIDATOR_PUBKEY,
          "jailed": false,
          "status": "BOND_STATUS_BONDED",
          "tokens": "$STAKE_AMOUNT",
          "delegator_shares": "$STAKE_AMOUNT.000000000000000000",
          "description": {
            "moniker": "$MONIKER",
            "identity": "",
            "website": "",
            "security_contact": "",
            "details": ""
          },
          "unbonding_height": "0",
          "unbonding_time": "1970-01-01T00:00:00Z",
          "commission": {
            "commission_rates": {
              "rate": "0.100000000000000000",
              "max_rate": "0.200000000000000000",
              "max_change_rate": "0.010000000000000000"
            },
            "update_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
          },
          "min_self_delegation": "1"
        }
      ],
      "delegations": [
        {
          "delegator_address": "$VALIDATOR_ACCOUNT_ADDRESS",
          "validator_address": "$VALIDATOR_OPERATOR_ADDRESS",
          "shares": "$STAKE_AMOUNT.000000000000000000"
        }
      ],
      "unbonding_delegations": [],
      "redelegations": [],
      "exported": false
    }
  }
}
EOF

    # Update config.toml
    sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/' $HOME/.loan/config/config.toml
    sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/' $HOME/.loan/config/config.toml
    sed -i 's/index_all_keys = false/index_all_keys = true/' $HOME/.loan/config/config.toml
    sed -i 's/mode = "full"/mode = "validator"/' $HOME/.loan/config/config.toml
fi

echo "Starting chain..."
exec loand start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --api.enable true \
    --api.enabled-unsafe-cors true \
    --api.address tcp://0.0.0.0:1317 \
    --grpc.enable true \
    --grpc.address 0.0.0.0:9090 \
    --p2p.laddr tcp://0.0.0.0:26656 \
    --p2p.external-address $(curl -s ifconfig.me):26656 \
    --p2p.seed_mode true \
    --minimum-gas-prices "$MINIMUM_GAS_PRICES" \
    --rpc.unsafe \
    --log_level info