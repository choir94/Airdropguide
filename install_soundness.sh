#!/bin/bash

# Warna teks
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# Periksa apakah Rust sudah terinstal
if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Rust sudah terinstal. Melewati instalasi Rust.${NC}"
else
    echo -e "${GREEN}Menginstal Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'source $HOME/.cargo/env' >> ~/.bashrc
    source ~/.bashrc
fi

# Tampilkan versi Rust
rustc --version
cargo --version

# Periksa apakah Soundness CLI sudah terinstal
if command -v soundnessup &> /dev/null; then
    echo -e "${YELLOW}Soundness CLI sudah terinstal. Melewati instalasi CLI.${NC}"
else
    echo -e "${GREEN}Menginstal Soundness CLI...${NC}"
    curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
    source ~/.bashrc
fi

# Instal atau update Soundness CLI
echo -e "${GREEN}Memeriksa pembaruan Soundness CLI...${NC}"
soundnessup update || soundnessup install

# Periksa apakah sudah ada key sebelumnya
if [ -f "$HOME/.soundness/keys.json" ]; then
    echo -e "${YELLOW}Kunci Soundness sudah ada. Melewati pembuatan kunci baru.${NC}"
else
    echo -e "${GREEN}Membuat kunci baru untuk Soundness...${NC}"
    soundness-cli generate-key --name my-key
    echo -e "${GREEN}Simpan frase pemulihan 24 kata dan public key dengan aman.${NC}"
fi

echo -e "${GREEN}Instalasi selesai!${NC}"
