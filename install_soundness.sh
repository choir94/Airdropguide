#!/bin/bash

# Warna teks
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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
if ! command -v soundnessup &> /dev/null; then
    echo -e "${GREEN}Menginstal Soundness CLI...${NC}"
    curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
    source ~/.bashrc
fi

# Pastikan Soundness CLI ada di PATH
if ! command -v soundnessup &> /dev/null; then
    echo -e "${YELLOW}Menambahkan Soundness CLI ke PATH...${NC}"
    export PATH=$HOME/.local/bin:$PATH
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc
fi

# Verifikasi instalasi Soundness CLI
if command -v soundnessup &> /dev/null; then
    echo -e "${GREEN}Soundness CLI berhasil diinstal.${NC}"
    echo -e "${GREEN}Memeriksa pembaruan Soundness CLI...${NC}"
    soundnessup update || soundnessup install
else
    echo -e "${RED}Soundness CLI gagal diinstal. Silakan coba instalasi manual.${NC}"
    exit 1
fi

# Periksa apakah sudah ada key sebelumnya
if [ -f "$HOME/.soundness/keys.json" ]; then
    echo -e "${YELLOW}Kunci Soundness sudah ada. Melewati pembuatan kunci baru.${NC}"
else
    echo -e "${GREEN}Membuat kunci baru untuk Soundness...${NC}"
    if command -v soundness-cli &> /dev/null; then
        soundness-cli generate-key --name my-key
        echo -e "${GREEN}Simpan frase pemulihan 24 kata dan public key dengan aman.${NC}"
    else
        echo -e "${RED}soundness-cli tidak ditemukan! Pastikan instalasi CLI berhasil.${NC}"
    fi
fi

echo -e "${GREEN}Instalasi selesai!${NC}"
