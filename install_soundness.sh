#!/bin/bash

# Warna teks
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# Cek & Install Rust jika belum ada
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
    echo -e "${GREEN}🛠 Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'source $HOME/.cargo/env' >> ~/.bashrc
    source ~/.bashrc
else
    echo -e "${YELLOW}✅ Rust already installed.${NC}"
fi

# Tampilkan versi Rust
rustc --version
cargo --version

# Cek & Install Soundness CLI jika belum ada
if ! command -v soundnessup &> /dev/null; then
    echo -e "${GREEN}🔽 Installing Soundness CLI...${NC}"
    curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
    source ~/.bashrc
else
    echo -e "${YELLOW}✅ Soundness CLI already installed.${NC}"
fi

# Pastikan Soundness CLI bisa diakses
export PATH=$HOME/.soundness/bin:$PATH
echo 'export PATH=$HOME/.soundness/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Cek apakah soundness-cli ada di PATH
if ! command -v soundness-cli &> /dev/null; then
    echo -e "${RED}❌ soundness-cli not found! Reinstalling...${NC}"
    rm -rf ~/.soundness
    soundnessup install
    export PATH=$HOME/.soundness/bin:$PATH
    source ~/.bashrc
fi

# Verifikasi instalasi Soundness CLI
if command -v soundness-cli &> /dev/null; then
    echo -e "${GREEN}✅ Soundness CLI successfully installed.${NC}"
else
    echo -e "${RED}❌ Soundness CLI installation failed. Please check manually.${NC}"
    exit 1
fi

# Cek apakah sudah ada kunci sebelumnya
if [ -f "$HOME/.soundness/keys.json" ]; then
    echo -e "${YELLOW}🔑 Soundness key already exists. Skipping key generation.${NC}"
else
    echo -e "${GREEN}🔑 Generating new Soundness key...${NC}"
    soundness-cli generate-key --name my-key
    echo -e "${GREEN}⚠️ Save your 24-word recovery phrase and public key safely!${NC}"
fi

echo -e "${GREEN}🎉 Installation complete!${NC}"
