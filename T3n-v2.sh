#!/bin/bash

# Display a header
clear
echo "======================================"
echo "🚀 Setting up t3rn Executor"
echo "======================================"

# Prompt for user (default: root)
read -p "Enter the username to run the executor (default: root): " EXECUTOR_USER
EXECUTOR_USER=${EXECUTOR_USER:-root}

# Prompt for Private Key
read -sp "Enter your PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL
echo ""

INSTALL_DIR="/home/$EXECUTOR_USER/t3rn"
ENV_FILE="/etc/t3rn-executor.env"

# Ensure the installation directory exists
mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"

echo "📥 Downloading the latest t3rn executor..."
TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
wget -q "https://github.com/t3rn/executor-release/releases/download/$TAG/executor-linux-$TAG.tar.gz"

echo "📦 Extracting files..."
tar -xzf executor-linux-*.tar.gz
cd executor/executor/bin

# Configure environment variables
echo "⚙️ Configuring environment settings..."
sudo bash -c "cat > $ENV_FILE" <<EOL
RPC_ENDPOINTS="{\"l2rn\": [\"https://b2n.rpc.caldera.xyz/http\"], \"arbt\": [\"https://arbitrum-sepolia.drpc.org\", \"https://sepolia-rollup.arbitrum.io/rpc\"], \"bast\": [\"https://base-sepolia-rpc.publicnode.com\", \"https://base-sepolia.drpc.org\"], \"opst\": [\"https://sepolia.optimism.io\", \"https://optimism-sepolia.drpc.org\"], \"unit\": [\"https://unichain-sepolia.drpc.org\", \"https://sepolia.unichain.org\"]}"
EOL

# Set permissions
sudo chown -R "$EXECUTOR_USER":"$EXECUTOR_USER" "$INSTALL_DIR"
sudo chmod 600 "$ENV_FILE"

# Start executor inside a screen session named "t3rn"
echo "🖥️ Launching t3rn Executor in a screen session..."
screen -dmS t3rn bash -c "cd $INSTALL_DIR/executor/executor/bin && \
    ENVIRONMENT=testnet \
    LOG_LEVEL=debug \
    LOG_PRETTY=false \
    EXECUTOR_PROCESS_BIDS_ENABLED=true \
    EXECUTOR_PROCESS_ORDERS_ENABLED=true \
    EXECUTOR_PROCESS_CLAIMS_ENABLED=true \
    EXECUTOR_MAX_L3_GAS_PRICE=100 \
    PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL \
    ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn \
    EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true \
    ./executor"

echo "✅ t3rn Executor has been successfully launched!"
echo ""
echo "👉 To view logs and interact with the executor, use:"
echo "   screen -r t3rn"
echo ""
echo "🚀 To detach from the screen session without stopping the executor, press:"
echo "   Ctrl + A, then D"
echo ""
echo "======================================"
echo "🎉 Setup complete!"
echo "======================================"
