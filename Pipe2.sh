#!/bin/bash

# Step 1: Prompt the user for input values
echo "Enter the URL for downloading the compiled PoP binary:"
read DOWNLOAD_URL
echo "Enter your Solana public key:"
read PUB_KEY

# Step 2: Download the compiled binary
echo "Downloading the compiled PoP binary from $DOWNLOAD_URL..."
wget -q $DOWNLOAD_URL -O /usr/local/bin/pop

# Step 3: Set executable permission
echo "Setting executable permission..."
chmod +x /usr/local/bin/pop

# Step 4: Create cache directory
echo "Creating cache directory..."
mkdir -p /data/download_cache

# Step 5: Quick Start - Run the node with default configuration (4GB RAM, 100GB disk)
echo "Starting PoP Cache Node v2 with default settings..."
/usr/local/bin/pop &

# Step 6: Run the node with custom configuration (8GB RAM, 500GB disk, custom cache directory)
echo "Configuring and starting PoP with custom settings..."
/usr/local/bin/pop --ram 8 --max-disk 500 --cache-dir /data --pubKey $PUB_KEY &

# Output confirmation
echo "PoP Cache Node v2 installation complete."
echo "Running on port 8003 with the following configuration:"
echo "RAM: 8GB, Max Disk: 500GB, Cache Directory: /data, Public Key: $PUB_KEY"
