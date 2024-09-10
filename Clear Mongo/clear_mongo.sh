# WORK IN PROGRESS

#!/bin/bash

# Define MongoDB credentials, replica set members, target database, and target collection
MONGO_USERNAME="hmsuser"
MONGO_PASSWORD="hmsuser"
REPLICA_SET_MEMBERS=("r8e964-be-mongo-v4.4.14-master1.stage-rc.in" "r8e964-be-mongo-v4.4.14-slave1.stage-rc.in" "r8e964-be-mongo-v4.4.14-slave2.stage-rc.in") # Replace with your replica set members
REPLICA_SET_PORT="27017"
AUTH_DB="hmsdb" # Change if using a different authentication database
TARGET_DB="hmsdb" # Replace with the target database name
TARGET_COLLECTION="userObject" # Replace with the target collection name

# Function to print memory and collection statistics
print_stats() {
  local HOST=$1
  local STATE=$2

  echo "Fetching statistics for $STATE state on $HOST..."

  # Connect to MongoDB and print statistics
  mongo --host $HOST --port $REPLICA_SET_PORT -u $MONGO_USERNAME -p $MONGO_PASSWORD --authenticationDatabase $AUTH_DB --quiet <<EOF
  use hmsdb
  db = db.getSiblingDB("$TARGET_DB");
  // Print database stats
  print("==== $STATE Database Stats for $TARGET_DB ====");
  dbStats = db.stats();
  printjson({
    "Collections": dbStats.collections,
    "Objects": dbStats.objects,
    "Data Size (MB)": dbStats.dataSize / (1024 * 1024),
    "Storage Size (MB)": dbStats.storageSize / (1024 * 1024),
    "Indexes": dbStats.indexes,
    "Index Size (MB)": dbStats.indexSize / (1024 * 1024)
  });

  // Print collection stats
  print("==== $STATE Collection Stats for $TARGET_COLLECTION ====");
  collectionStats = db["$TARGET_COLLECTION"].stats();
  printjson({
    "Document Count": collectionStats.count,
    "Size (MB)": collectionStats.size / (1024 * 1024),
    "Storage Size (MB)": collectionStats.storageSize / (1024 * 1024),
    "Free Storage Size (MB)": collectionStats.freeStorageSize / (1024 * 1024),
    "Index Size (MB)": collectionStats.totalIndexSize / (1024 * 1024)
  });
EOF
}

# Function to delete all documents from the target collection
clear_mongo_collection() {
  local HOST=$1

  echo "Clearing data in collection '$TARGET_COLLECTION' in database '$TARGET_DB' on $HOST..."

  # Connect to MongoDB and remove all documents from the specified collection
  mongo --host $HOST --port $REPLICA_SET_PORT -u $MONGO_USERNAME -p $MONGO_PASSWORD --authenticationDatabase $AUTH_DB --quiet <<EOF
  db = db.getSiblingDB("$TARGET_DB");
  print("Deleting all documents from collection: " + "$TARGET_COLLECTION");
  db["$TARGET_COLLECTION"].deleteMany({});
EOF
}

# Loop through each replica set member and perform the operations
for HOST in "${REPLICA_SET_MEMBERS[@]}"; do
  echo "Working on replica set member: $HOST"

  # Print statistics before clearing the data
  print_stats $HOST "Before Clearing"

  # Clear the data in the target collection
  clear_mongo_collection $HOST

  # Print statistics after clearing the data
  print_stats $HOST "After Clearing"

  echo "Completed operations for $HOST."
done

echo "Data clearing and stats collection completed for all replica set members."
