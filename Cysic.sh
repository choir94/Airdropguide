#!/bin/bash

# ───────────────────────────────────────────────
# 🚀 CYSIC Phase III Auto Installer
# 🛠️ By Airdrop Node (https://t.me/airdrop_node)
# Supports Verifier & Prover with screen sessions
# ───────────────────────────────────────────────

# 🎨 Warna
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 🔍 Cek & Install Dependencies
echo -e "${GREEN}🔧 [Airdrop Node] Checking and installing dependencies...${NC}"
sudo apt update -y
sudo apt install curl screen -y

# 📝 Input Alamat Wallet
read -p "🔑 Enter your wallet address (0x...): " WALLET_ADDRESS
if [[ ! $WALLET_ADDRESS =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo -e "${RED}❌ Invalid Ethereum address!${NC}"
    exit 1
fi

# 📋 Menu Pilihan Node
echo ""
echo "========================================="
echo "         CYSIC TESTNET PHASE III         "
echo "            by Airdrop Node              "
echo "========================================="
echo "1. 🟢 Install Verifier Node"
echo "2. 🔵 Install Prover Node"
echo "========================================="
read -p "❓ Choose an option [1 or 2]: " OPTION

# 🟢 Verifier Node Setup
if [ "$OPTION" == "1" ]; then
    echo -e "${GREEN}🚀 Installing Verifier Node...${NC}"
    curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_linux.sh -o ~/setup_linux.sh
    bash ~/setup_linux.sh $WALLET_ADDRESS

    echo -e "${GREEN}📦 Starting Verifier Node in screen session: cysic-verifier${NC}"
    screen -dmS cysic-verifier bash -c "cd ~/cysic-verifier && bash start.sh"

# 🔵 Prover Node Setup
elif [ "$OPTION" == "2" ]; then
    read -p "🌐 Enter your Ethereum RPC URL (from Alchemy or others): " RPC_URL

    echo -e "${GREEN}🚀 Installing Prover Node...${NC}"
    curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_prover.sh -o ~/setup_prover.sh
    bash ~/setup_prover.sh $WALLET_ADDRESS $RPC_URL

    echo -e "${GREEN}📦 Starting Prover Node in screen session: cysic-prover${NC}"
    screen -dmS cysic-prover bash -c "cd ~/cysic-prover && bash start.sh"

else
    echo -e "${RED}❌ Invalid option. Please choose 1 or 2.${NC}"
    exit 1
fi

# ✅ Selesai
echo ""
echo -e "${GREEN}🎉 Node successfully installed and running in screen session!${NC}"
echo -e "${GREEN}ℹ️ To check: screen -ls${NC}"
echo -e "${GREEN}🧑‍💻 Telegram: https://t.me/airdrop_node${NC}"
