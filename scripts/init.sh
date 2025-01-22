#!/bin/bash
set -e

# Khởi tạo chain
loand init $MONIKER --chain-id $CHAIN_ID

# Tạo tài khoản validator
echo "password" | loand keys add $VALIDATOR_KEY_NAME --keyring-backend test

# Lấy địa chỉ validator và pubkey
VALIDATOR_ADDRESS=$(echo "password" | loand keys show $VALIDATOR_KEY_NAME -a --keyring-backend test)

# Thêm genesis account với số lượng token cực lớn
loand genesis add-genesis-account $VALIDATOR_ADDRESS 1000000000000000000000000000stake

# Điều chỉnh các tham số trong genesis
jq '.app_state.staking.params.bond_denom = "stake"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.staking.params.unbonding_time = "1814400s"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.staking.params.max_validators = 100' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.staking.params.historical_entries = 10000' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.staking.params.min_commission_rate = "0.000000000000000000"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.crisis.constant_fee.denom = "stake"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.gov.params.min_deposit[0].denom = "stake"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.mint.params.mint_denom = "stake"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json

# Điều chỉnh power reduction và consensus params
jq '.consensus_params.validator.pub_key_types = ["ed25519"]' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.staking.params.power_reduction = "1000000"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json

# Tạo gentx với số lượng stake lớn hơn DefaultPowerReduction
loand genesis gentx $VALIDATOR_KEY_NAME 900000000000000stake \
  --chain-id $CHAIN_ID \
  --moniker $MONIKER \
  --commission-max-change-rate 0.01 \
  --commission-max-rate 0.2 \
  --commission-rate 0.1 \
  --min-self-delegation "1" \
  --pubkey=$(loand tendermint show-validator) \
  --keyring-backend test \
  --yes

# Collect gentxs
loand genesis collect-gentxs

# Điều chỉnh một số tham số quan trọng trong genesis
jq '.app_state.staking.params.historical_entries = "100"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.slashing.params.signed_blocks_window = "10000"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json
jq '.app_state.slashing.params.min_signed_per_window = "0.500000000000000000"' ~/.loan/config/genesis.json > temp.json && mv temp.json ~/.loan/config/genesis.json

# Validate genesis
loand genesis validate-genesis

# Start chain với các flags bổ sung
exec loand start \
  --rpc.laddr tcp://0.0.0.0:26657 \
  --grpc.address 0.0.0.0:9090 \
  --address tcp://0.0.0.0:26656 \
  --minimum-gas-prices 0stake \
  --pruning nothing \
  --x-crisis-skip-assert-invariants 