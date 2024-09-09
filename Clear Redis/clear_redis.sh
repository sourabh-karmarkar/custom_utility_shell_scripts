#!/bin/bash

# Set your ElastiCache Redis endpoint here
CLUSTER_ENDPOINT="YOUR_REDIS_CONFIGURATION_ENDPOINT"
CLUSTER_PORT="6379"  # Default Redis port, change if necessary

# Function to get memory usage and number of keys
get_node_info() {
  NODE=$1
  MEMORY_USED=$(redis-cli -h $NODE -p $CLUSTER_PORT -c INFO MEMORY | grep "used_memory_human:" | cut -d':' -f2)
  KEYS_COUNT=$(redis-cli -h $NODE -p $CLUSTER_PORT -c DBSIZE)
  
  echo "Node: $NODE"
  echo "Memory used: $MEMORY_USED"
  echo "Number of keys: $KEYS_COUNT"
  echo "--------------------------------"
}

# Function to flush data from a single node
flush_node() {
  MASTER_FLUSH_NODE=$1
  echo "Flushing data from node $MASTER_FLUSH_NODE"
  redis-cli -h $MASTER_FLUSH_NODE -p $CLUSTER_PORT FLUSHALL
}

# Get all shard and node endpoints
echo "Fetching shard and node endpoints for master and slaves"
NODES=$(redis-cli -h $CLUSTER_ENDPOINT -p $CLUSTER_PORT -c CLUSTER NODES | awk '{print $2}' | cut -d':' -f1 | uniq)
echo "All Redis Nodes: $NODES"
echo "--------------------------------"
echo "Fetching shard and node endpoints for only master"
MASTER_NODES=$(redis-cli -h $CLUSTER_ENDPOINT -p $CLUSTER_PORT -c CLUSTER NODES | awk '$3 == "master" || $3 == "myself,master" {print $2}' | cut -d':' -f1 | uniq)
echo "All Redis Master Nodes: $MASTER_NODES"
echo "--------------------------------"

# Get memory usage and key count before flush
echo "Memory and key info of master and slaves before flush"
for NODE in $NODES; do
  get_node_info $NODE
done

# Flush data from each master node
for MASTER_NODE in $MASTER_NODES; do
  flush_node $MASTER_NODE
done

# Get memory usage and key count after flush
echo "Memory and key info after flush:"
for NODE in $NODES; do
  get_node_info $NODE
done

echo "All nodes flushed successfully!"
