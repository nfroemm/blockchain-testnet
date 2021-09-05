#!/bin/bash
################################################################################
# Helper script to setup a local proof-of-authority (PoA) blockchain test
# network ("testnet") using go-ethereum (`geth`) command-line tools,
#
#   https://geth.ethereum.org/docs/install-and-build/installing-geth
#
# Notes
# -----
# - The first argument to this script ("$1") is the network name.  The default
#   is "testnet", which is why you see "${1:-testnet}" below.
# - The second argument to this script ("$2") is the number of blockchain nodes.
#   The default value is "2", which is why you see "${2:-2}" below.  The allowed
#   number of blockchain nodes {2, 3, ..., 10} because it takes at least two
#   nodes to define a network, yet we'd like to keep the testnet relatively
#   small and lightweight.
# - The command that actually creates the node accounts is `geth account new`.
#   Make sure you understand what's going on in the code around this line!
# - A few additional files are created for the user's convenience:
#   - `./testnet/node*/address.txt` -- contains the node address
#   - `./testnet/node*/password.txt` -- contains the node password.  The default
#     password is simply the node name.
#
################################################################################
BLOCKCHAIN_NETWORK_DIR="${1:-testnet}"  # 1st command-line argument
BLOCKCHAIN_NUM_NODES="${2:-2}"  # 2nd command-line argument


#===============================================================================
# CHECK USER'S ARGUMENTS -------------------------------------------------------
#===============================================================================
# Check that the top-level directory does not already exist (avoid collisions)
if [ -d "$BLOCKCHAIN_NETWORK_DIR" ]; then
  echo "ERROR: Blockchain testnet directory \"$BLOCKCHAIN_NETWORK_DIR\" exists!"
  echo "Terminating program."
  exit 1
fi
# Check that the number of blockchain nodes is more than one (since it takes at
# least two nodes to define a network) but less than or equal to ten, since we'd
# like to keep our testnet small and lightweight
if [ "$BLOCKCHAIN_NUM_NODES" -lt 2 ] || [ "$BLOCKCHAIN_NUM_NODES" -gt 10 ]; then
  echo "ERROR: Number of blockchain nodes must be in range {2, 3, ..., 10}!"
  echo "Your value: $BLOCKCHAIN_NUM_NODES"
  echo "Terminating program."
  exit 1
fi


#===============================================================================
# SETUP NETWORK ----------------------------------------------------------------
#===============================================================================
mkdir -p "$BLOCKCHAIN_NETWORK_DIR"
for node_num in $(seq "$BLOCKCHAIN_NUM_NODES"); do
  # Construct node name
  node_name="node$(expr $node_num - 1)"  # 0-based, e.g. "node0", ..., "node9"
  # Construct node directory path
  node_dir="${BLOCKCHAIN_NETWORK_DIR}/${node_name}"
  # Check if the node directory already exists
  if [ -d "$node_dir" ]; then
    # Terminate the program if the node directory already exists (avoid collisions)
    echo "ERROR: \"${node_dir}\" already exists!"
    echo "Terminating program."
    exit 1
  else
    # Create the node directory if necessary
    mkdir -p "$node_dir"
  fi
  # Construct this node's password file
  node_password="${node_name}"  # change to whatever you want!
  node_password_file="${node_dir}/password.txt"
  echo "$node_password" >> "$node_password_file"
  # Create the blockchain node using go-ethereum CLI
  geth account new --datadir "$node_dir" --password "$node_password_file"
  # Extract this node's public address from the keystore file name
  node_address=$( sed 's/\(.*\)Z--\(.*\)/\2/g' < <(find "$node_dir" -type f -name '*UTC*') )
  node_address_file="${node_dir}/address.txt"
  # Save this node's address to disk
  echo "$node_address" >> "$node_address_file"
done

# All done -- no errors! :)
exit 0
