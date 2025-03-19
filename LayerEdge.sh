#!/bin/bash

set -e  # Hentikan skrip jika ada error

# Menampilkan logo
echo "🔹 Fetching and displaying logo..."
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5  # Memberikan waktu untuk melihat logo

echo ""
echo "==============================================="
echo "      🚀 INSTALLING LAYER EDGE LIGHT NODE      "
echo "==============================================="
echo ""

# 🔹 Updating system and installing dependencies
echo -e "\n🔹 Updating system and installing dependencies...\n"
sudo apt update && sudo apt install -y curl build-essential git screen

# 🔹 Checking & Installing Go
if ! command -v go &>/dev/null; then
    echo -e "\n🔹 Installing Go...\n"
    curl -fsSL https://golang.org/dl/go1.18.linux-amd64.tar.gz | sudo tar -xz -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# 🔹 Checking & Installing Rust
if ! command -v rustc &>/dev/null; then
    echo -e "\n🔹 Installing Rust...\n"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# 🔹 Checking & Installing RISC0 Toolchain (rzup)
echo -e "\n🔹 Checking if 'rzup' is installed...\n"
if ! command -v rzup &>/dev/null; then
    echo -e "\n'🔹 rzup' not found. Installing...\n"
    curl -L https://risczero.com/install | bash && rzup install
    if [ -f "$HOME/.risc0/bin/rzup" ]; then
        echo -e "\n✅ 'rzup' installed successfully. Adding to PATH...\n"
        export PATH=$HOME/.risc0/bin:$PATH
        echo 'export PATH=$HOME/.risc0/bin:$PATH' >> ~/.bashrc
        echo 'export PATH=$HOME/.risc0/bin:$PATH' >> ~/.profile
        source ~/.bashrc
    else
        echo -e "\n❌ Installation failed. Please check manually.\n"
        exit 1
    fi
else
    echo -e "\n✅ 'rzup' is already installed.\n"
fi

# 🔹 Input Private Key
echo -e "\n🔹 Please enter your PRIVATE KEY:"
read -s PRIVATE_KEY  # Input dengan mode tersembunyi

# 🔹 Configuring Environment Variables
echo -e "\n🔹 Configuring environment variables...\n"
cat <<EOF > ~/.layer_edge_env
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
export PRIVATE_KEY='$PRIVATE_KEY'
EOF

echo 'source ~/.layer_edge_env' >> ~/.bashrc
source ~/.layer_edge_env

# 🔹 Clone & Build Layer Edge Light Node
echo -e "\n🔹 Cloning Layer Edge Light Node repository...\n"
if [ ! -d "layer-edge-light-node" ]; then
    git clone https://github.com/layeredge/light-node.git layer-edge-light-node
fi

cd layer-edge-light-node
echo -e "\n🔹 Building Light Node...\n"
go build
cd ..

# 🔹 Clone & Build RISC0 Merkle Service
echo -e "\n🔹 Cloning and building RISC0 Merkle Service...\n"
if [ ! -d "risc0-merkle-service" ]; then
    git clone https://github.com/risczero/merkle-service.git risc0-merkle-service
fi

cd risc0-merkle-service
cargo build
cd ..

echo -e "\n✅ Installation complete!\n"

# 🔹 Running Merkle Service in Screen
echo -e "\n🔹 Starting RISC0 Merkle Service...\n"
screen -dmS merkle_service bash -c "cd risc0-merkle-service && cargo run"

# 🔹 Waiting until Merkle Service is running
echo -e "\n🔹 Waiting for Merkle Service to be fully up...\n"
while ! nc -z 127.0.0.1 3001; do
    echo "⏳ Waiting for Merkle Service (port 3001)..."
    sleep 2
done
echo -e "\n✅ Merkle Service is running!\n"

# 🔹 Running Layer Edge Light Node in Screen
echo -e "\n🔹 Starting Layer Edge Light Node...\n"
screen -dmS light_node bash -c "cd layer-edge-light-node && ./light-node"

echo -e "\n✅ Both services are running in background screens!\n"
echo "==============================================="
echo "  🎯 Use the following commands to monitor:"
echo "==============================================="
echo "  📌 Merkle Service: screen -r merkle_service"
echo "  📌 Light Node: screen -r light_node"
echo ""
echo "  🔄 Exit screen without stopping process: Press CTRL + A, then D"
echo "  ❌ Stop screens: screen -S merkle_service -X quit && screen -S light_node -X quit"
echo ""
