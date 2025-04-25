#!/bin/bash
set -e
set -o pipefail

# Log file
LOG_FILE="$HOME/zgs_install.log"
echo "Installation started at $(date)" > "$LOG_FILE"

# spinner
spinner() {
    local pid=$!
    local delay=0.1
    local spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local color="\e[33m" # Warna kuning
    local reset="\e[0m"

    tput civis # Sembunyikan kursor
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 ${#spin}); do
            echo -ne "${color}\r[${spin:$i:1}] Loading...${reset}"
            sleep $delay
        done
    done
    tput cnorm # Tampilkan kursor
    echo -e "\r\033[K✅ \e[32mDone!\e[0m"
}

# STEP 1
echo -e "\033[1;33m[1/9] Installing build dependencies...\033[0m"
sudo apt-get update -qq >> "$LOG_FILE" 2>&1
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq >> "$LOG_FILE" 2>&1 &
spinner
echo ""

# STEP 2
echo -e "\033[1;33m[2/9] Installing Go (v1.22.0)...\033[0m"
cd $HOME
ver="1.22.0"
wget -q "https://golang.org/dl/go$ver.linux-amd64.tar.gz" >> "$LOG_FILE" 2>&1
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" >> "$LOG_FILE" 2>&1
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version >> "$LOG_FILE" 2>&1 &
spinner
echo ""

# STEP 3
echo -e "\033[1;33m[3/9] Installing Rust...\033[0m"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1 &
spinner
source "$HOME/.cargo/env"
echo ""

# STEP 4
echo -e "\033[1;33m[4/9] Cloning and building 0g-storage-node binary...\033[0m"
cd $HOME
rm -rf 0g-storage-node
git clone https://github.com/0glabs/0g-storage-node.git >> "$LOG_FILE" 2>&1
cd 0g-storage-node
git checkout v1.0.0 >> "$LOG_FILE" 2>&1
git submodule update --init >> "$LOG_FILE" 2>&1

# Build step with output
echo -e "\033[1;34m➡️  Building binary... (this might take a few minutes)\033[0m"
cargo build --release >> "$LOG_FILE" 2>&1 &
spinner
echo ""

# STEP 5
echo -e "\033[1;33m[5/9] Downloading config file...\033[0m"
rm -rf $HOME/0g-storage-node/run/config.toml
curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/choir94/Airdropguide/main/config-v3.toml >> "$LOG_FILE" 2>&1
if [[ ! -s $HOME/0g-storage-node/run/config.toml ]]; then
    echo -e "\033[1;31mError: Failed to download config.toml or file is empty!\033[0m"
    exit 1
fi
echo -e "\033[32m✔ Config file downloaded successfully.\033[0m"
echo ""

# STEP 6
echo -e "\033[1;33m[6/9] Please enter your private key below:\033[0m"
echo -n "🔑 Private Key: "
read PRIVATE_KEY

# Validate private key (basic check)
if [[ -z "$PRIVATE_KEY" ]]; then
    echo -e "\033[1;31mError: Private key cannot be empty!\033[0m"
    exit 1
fi
# Optional: Check if it looks like a hex private key (starts with 0x and has valid length)
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo -e "\033[1;33mWarning: Private key format may be invalid (should be 0x followed by 64 hex characters).\033[0m"
fi

CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"

# Replace only if it matches the exact placeholder
sed -i "s|miner_key = \"YOUR-PRIVATE-KEY\"|miner_key = \"$PRIVATE_KEY\"|" "$CONFIG_PATH" >> "$LOG_FILE" 2>&1
echo -e "\033[32m✔ Private key successfully added to config.\033[0m\n"

# STEP 7
echo -e "\033[1;33m[7/9] Verifying configuration...\033[0m"
if grep -E "^(network_dir|network_enr_address|network_enr_tcp_port|network_enr_udp_port|network_libp2p_port|network_discovery_port|rpc_listen_address|rpc_enabled|db_dir|log_config_file|log_contract_address|mine_contract_address|reward_contract_address|log_sync_start_block_number|blockchain_rpc_endpoint|auto_sync_enabled|find_peer_timeout|miner_key)" "$CONFIG_PATH" >> "$LOG_FILE" 2>&1; then
    echo -e "\033[32m✔ Configuration verified.\033[0m"
else
    echo -e "\033[1;31mError: Configuration verification failed. Check $CONFIG_PATH.\033[0m"
    exit 1
fi
echo ""

# STEP 8
echo -e "\033[1;33m[8/9] Creating systemd service...\033[0m"
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
echo -e "\033[32m✔ Systemd service created.\033[0m"
echo ""

# STEP 9
echo -e "\033[1;33m[9/9] Starting node service...\033[0m"
sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
sudo systemctl enable zgs >> "$LOG_FILE" 2>&1
sudo systemctl restart zgs >> "$LOG_FILE" 2>&1 &
spinner
echo ""

# Finish
echo -e "\033[1;32m🎉 Setup completed! Your ZGS node service is now running.\033[0m"
echo -e "\033[1;34mℹ️  Checking service status below:\033[0m\n"
sudo systemctl status zgs --no-pager

# Post-installation instructions
echo -e "\n\033[1;34m📝 Post-Installation Instructions:\033[0m"
echo -e "  - To check node logs: \033[1;32mjournalctl -u zgs -f\033[0m"
echo -e "  - To stop the node: \033[1;32msudo systemctl stop zgs\033[0m"
echo -e "  - To restart the node: \033[1;32msudo systemctl restart zgs\033[0m"
echo -e "  - Installation logs saved to: \033[1;32m$LOG_FILE\033[0m"
echo -e "\033[1;34mℹ️  Ensure your private key and configuration are secure!\033[0m"
