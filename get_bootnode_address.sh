#!/bin/bash
################################################################################
# Helper script to determine the full bootnode address of `node0`, i.e. the
# bootnode for this network.
#
# Notes
# -----
# - The zeroth node, i.e. `node0`, is the bootnode for this network
# - The file `testnet./node0/geth/nodekey` is used to calculate the full
#   bootnode address
# - The default http port is "127.0.0.1" ("localhost")
# - The default node ports are `3030X`, where X=[0..9].  In this case, since
#   `node0` is the bootnode, the default port is 30300
#
################################################################################
bootnode_name="node0"
http_address="127.0.0.1"
port="30300"

# First, find the bootnode's data directory
bootnode_datadir=$(find . -name "$bootnode_name" -type d)
if [ -z "$bootnode_datadir" ]; then
  echo "ERROR: Bootnode directory not found!"
  exit 1
fi

# Next, find the bootnode's `nodekey` file (within the bootnode data directory)
bootnode_keyfile=$(find "$bootnode_datadir" -name nodekey -type f)
if [ -z "$bootnode_keyfile" ]; then
  echo "ERROR: Bootnode key file not found!"
  exit 1
fi

# Next, extract the bootnode address from the nodekey file
bootnode_address=$(bootnode -nodekeyhex $(cat "$bootnode_keyfile") -writeaddress)

# Finally, print the full bootnode address
echo "enode://${bootnode_address}@${http_address}:${port}"
exit 0
