#!/bin/bash
################################################################################
# Helper script to run individual nodes, one at a time, in order to build up the
# blockchain test network.
#
# Notes
# -----
# - Blockchain nodes are labeled as `nodeX`, where X=[0..9] is the node number
# - The user must supply a node number [0..9] as the first argument ("$1")
# - The default http port is "8545", however, a different http port number may
#   be supplied as the second argument to this script ("$2")
# - The default http address is "127.0.0.1", however, a different http address
#   may be supplied as the third argument to this script ("$3")
# - The port number is 3030X, where "X" is the node number [0..9]
# - Node0 is the bootnode.  Great care is taken to construct the full address
#   of the bootnode using "enode://$NODEKEYHEX@$HTTP_ADDRESS:$PORT" (see below)
#
################################################################################
NODE_NUM="$1"  # the node number [0..9] is the first argument to this script ("$1")
HTTP_PORT="${2:-8545}"  # the http port is the second argument to this script ("$2")
HTTP_ADDRESS="${3:-127.0.0.1}"  # the http address is the third argument to this script ("$3")


#===============================================================================
# CHECK USER'S ARGUMENTS -------------------------------------------------------
#===============================================================================
# Check that the user supplied a node number
if [ -z "$NODE_NUM" ]; then
  echo "ERROR: No node number specified!"
  exit 1
fi
# Check that the user's node number is in the allowed range [0..9]
if [ "$NODE_NUM" -lt 0 ] || [ "$NODE_NUM" -gt 9 ]; then
  echo "ERROR: Node number must be in range [0, 1, ..., 9]"
  exit 1
fi


#===============================================================================
# BUILD OTHER IMPORTANT VARIABLES FROM THE NODE NUMBER -------------------------
#===============================================================================
NODE_NAME="node${NODE_NUM}"
NODE_DATADIR="$(find . -name $NODE_NAME -type d)"
NODE_ADDRESS_FILE="${NODE_DATADIR}/address.txt"
NODE_PASSWORD_FILE="${NODE_DATADIR}/password.txt"
PORTX="3030X"  # replace "X" with node number (see below)
PORT=$(echo "$PORTX" | tr 'X' "$NODE_NUM")

# Check that the top-level node data directory exists and is not null
if [ -z "$NODE_DATADIR" ] || [ ! -d "$NODE_DATADIR" ]; then
  echo "ERROR: Directory for \"$NODE_NAME\" not found!"
  exit 1
fi

# Check that the node address file exists
if [ ! -f "$NODE_ADDRESS_FILE" ]; then
  echo "ERROR: Node address file \"${NODE_ADDRESS_FILE}\" does not exist!"
  exit 1
fi

# Check that the node password file exists
if [ ! -f "$NODE_PASSWORD_FILE" ]; then
  echo "ERROR: Node password file \"${NODE_PASSWORD_FILE}\" does not exist!"
  exit 1
fi

# Inform user
echo "--------------------------"
echo "Blockchain node parameters"
echo "--------------------------"
echo "NODE_DATADIR:       $NODE_DATADIR"
echo "NODE_ADDRESS_FILE:  $NODE_ADDRESS_FILE"
echo "NODE_PASSWORD_FILE: $NODE_PASSWORD_FILE"
echo "HTTP_ADDRESS:       $HTTP_ADDRESS"
echo "HTTP_PORT:          $HTTP_PORT"
echo "PORT:               $PORT"
printf "\n"


#===============================================================================
# CONSTRUCT THE GO-ETHEREUM COMMAND --------------------------------------------
#===============================================================================
# Construct the basic `geth` command with all command-line options that are the
# same for all nodes in the blockchain network
geth_command_common=$(cat << GETH_COMMAND
geth --datadir $NODE_DATADIR \\
     --unlock $(cat "$NODE_ADDRESS_FILE") \\
     --password $NODE_PASSWORD_FILE \\
     --allow-insecure-unlock \\
     --mine \\
     --miner.threads 1 \\
     --port $PORT
GETH_COMMAND
)
#----------------------
# NODE0 (THE BOOTNODE)
#----------------------
if [ "$NODE_NUM" -eq 0 ]; then
  # Construct the rest of the `geth` command for running `node0`
  geth_command="$(cat << GETH_COMMAND
$geth_command_common \\
     --http \\
     --http.addr $HTTP_ADDRESS \\
     --http.port $HTTP_PORT
GETH_COMMAND
)"
#--------------------------
# NODE[1..9] (OTHER NODES)
#--------------------------
else
  # Construct the rest of the `geth` command for running `node[1..9]`. Remember,
  # `node0` is the bootnode.  First, find `node0`'s data directory.
  bootnode_datadir=$(find . -name node0 -type d)
  if [ -z "$bootnode_datadir" ]; then
    echo "ERROR: Bootnode directory not found!"
    exit 1
  fi
  # Next, find `node0`'s nodekey file
  bootnode_keyfile=$(find "$bootnode_datadir" -name nodekey -type f)
  if [ -z "$bootnode_keyfile" ]; then
    echo "ERROR: Bootnode key file not found!"
    exit 1
  fi
  # Extract relevant data from `node0/geth/nodekey` file
  bootnode_address=$(bootnode -nodekeyhex $(cat "$bootnode_keyfile") -writeaddress)
  # Get the bootnode port number
  bootnode_portnum=$(echo "$PORTX" | tr 'X' '0')
  # Finish constructing the rest of the `geth` command for nodes [1..9]
  geth_command="$(cat << GETH_COMMAND
$geth_command_common \\
     --ipcdisable \\
     --bootnodes "enode://${bootnode_address}@${HTTP_ADDRESS}:${bootnode_portnum}"
GETH_COMMAND
)"
fi

# Print the `geth` command for the user's convenience
echo "-------------------"
echo "Full \`geth\` command"
echo "-------------------"
echo "$geth_command"
printf "\n"


#===============================================================================
# RUN THE GO-ETHEREUM COMMAND --------------------------------------------------
#===============================================================================
eval "$geth_command"
exit 0

