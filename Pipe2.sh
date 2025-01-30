#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Set the working directory and cache directory
mkdir -p /root/pipenetwork
mkdir -p /root/pipenetwork/download_cache
cd /root/pipenetwork

# Ask the user for the URL to download the pop binary
echo -e "\n========================="
echo -e " Pipe Network POP Node Setup"
echo -e "=========================\n"

echo "Please enter the URL to download the pop binary:"
read POP_BINARY_URL

# Check if URL is empty
if [ -z "$POP_BINARY_URL" ]; then
    echo -e "\nError: No URL provided. Exiting.\n"
    exit 1
fi

# Download the pop binary into the pipenetwork directory
echo -e "\nDownloading pop binary from $POP_BINARY_URL..."
wget "$POP_BINARY_URL" -O /root/pipenetwork/pop

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo -e "\nError: Failed to download the pop binary. Exiting.\n"
    exit 1
fi

# Make the binary executable
chmod +x /root/pipenetwork/pop

# Ask the user for RAM size, disk size, and Solana public key
echo -e "\nPlease enter your RAM size (e.g., 4GB, 8GB, etc.):"
read RAM_SIZE

echo "Please enter your maximum disk size (e.g., 100GB, 500GB, etc.):"
read MAX_DISK_SIZE

echo "Please enter your Solana public key:"
read SOLANA_PUBKEY

# Check if any of the inputs are empty
if [ -z "$RAM_SIZE" ] || [ -z "$MAX_DISK_SIZE" ] || [ -z "$SOLANA_PUBKEY" ]; then
    echo -e "\nError: Missing required input. Exiting.\n"
    exit 1
fi

# Run the pop binary with the --gen-referral-route flag to capture the referral route
echo -e "\nGenerating referral route..."
REFERRAL_ROUTE=$( /root/pipenetwork/pop \
    --ram $RAM_SIZE \
    --max-disk $MAX_DISK_SIZE \
    --cache-dir /root/pipenetwork/download_cache \
    --pubKey $SOLANA_PUBKEY \
    --gen-referral-route )

# Display the referral route
echo -e "\n==============================="
echo -e " Referral Route Generated:"
echo -e "==============================="
echo -e "$REFERRAL_ROUTE\n"

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
echo -e "\nReloading systemd to apply changes..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo -e "\nEnabling the service to start on boot..."
sudo systemctl enable pipe-pop

# Start the service
echo -e "\nStarting the Pipe POP Node Service..."
sudo systemctl start pipe-pop

# Check the status of the Pipe POP node using the --status flag
echo -e "\n==============================="
echo -e " Checking Pipe POP Node Status:"
echo -e "==============================="
/root/pipenetwork/pop --status

# Check the status of the systemd service to ensure it's running
echo -e "\n==============================="
echo -e " Systemd Service Status:"
echo -e "==============================="
sudo systemctl status pipe-pop
