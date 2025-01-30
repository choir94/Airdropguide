#!/bin/bash

# Set the working directory and cache directory
mkdir -p /root/pipenetwork
mkdir -p /root/pipenetwork/download_cache
cd /root/pipenetwork

# Ask the user for the URL to download the pop binary
echo "Please enter the URL to download the pop binary:"
read POP_BINARY_URL

# Check if URL is empty
if [ -z "$POP_BINARY_URL" ]; then
    echo "Error: No URL provided. Exiting."
    exit 1
fi

# Download the pop binary into the pipenetwork directory
echo "Downloading pop binary from $POP_BINARY_URL..."
wget "$POP_BINARY_URL" -O /root/pipenetwork/pop

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the pop binary. Exiting."
    exit 1
fi

# Make the binary executable
chmod +x /root/pipenetwork/pop

# Ask the user for RAM size, disk size, and Solana public key
echo "Please enter your RAM size (e.g., 4GB, 8GB, etc.):"
read RAM_SIZE

echo "Please enter your maximum disk size (e.g., 100GB, 500GB, etc.):"
read MAX_DISK_SIZE

echo "Please enter your Solana public key:"
read SOLANA_PUBKEY

# Check if any of the inputs are empty
if [ -z "$RAM_SIZE" ] || [ -z "$MAX_DISK_SIZE" ] || [ -z "$SOLANA_PUBKEY" ]; then
    echo "Error: Missing required input. Exiting."
    exit 1
fi

# Run the pop binary with the --gen-referral-route flag to capture the referral route
echo "Generating referral route..."
REFERRAL_ROUTE=$( /root/pipenetwork/pop \
    --ram $RAM_SIZE \
    --max-disk $MAX_DISK_SIZE \
    --cache-dir /root/pipenetwork/download_cache \
    --pubKey $SOLANA_PUBKEY \
    --gen-referral-route )

# Display the referral route
echo "Referral Route Generated: $REFERRAL_ROUTE"

# Create the systemd service file with the --gen-referral-route option
cat <<EOL > /etc/systemd/system/pipe-pop.service
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=root
Group=root
WorkingDirectory=/root/pipenetwork
ExecStart=/root/pipenetwork/pop \
    --ram $RAM_SIZE \
    --max-disk $MAX_DISK_SIZE \
    --cache-dir /root/pipenetwork/download_cache \
    --pubKey $SOLANA_PUBKEY \
    --gen-referral-route
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable pipe-pop

# Start the service
sudo systemctl start pipe-pop

# Check the status of the Pipe POP node using the --status flag
echo "Checking Pipe POP Node status..."
/root/pipenetwork/pop --status

# Check the status of the systemd service to ensure it's running
sudo systemctl status pipe-pop
