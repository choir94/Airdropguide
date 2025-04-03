#!/bin/bash

# Warna untuk output
BLUE='\033[0;34m'
WHITE='\033[0;97m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Direktori skrip saat ini
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

# Fungsi instalasi dependensi
install_dependencies() {
    echo -e "${YELLOW}Menginstal dependensi...${RESET}"

    # Inisialisasi Git jika belum ada
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Menginisialisasi repository Git...${RESET}"
        git init
    fi

    # Instal Foundry jika belum terinstal
    if ! command -v forge &> /dev/null; then
        echo -e "${YELLOW}Foundry belum terinstal. Menginstal Foundry...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    # Instal OpenZeppelin Contracts jika belum ada
    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        echo -e "${YELLOW}Menginstal OpenZeppelin Contracts...${RESET}"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        echo -e "${WHITE}OpenZeppelin Contracts sudah terinstal.${RESET}"
    fi
}

# Fungsi input detail yang diperlukan
input_required_details() {
    echo -e "${YELLOW}-----------------------------------${RESET}"

    # Hapus file .env lama jika ada
    [ -f "$SCRIPT_DIR/token_deployment/.env" ] && rm "$SCRIPT_DIR/token_deployment/.env"

    # Input nama token
    read -p "Masukkan Nama Token (default: AirdropNode): " TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"

    # Input simbol token
    read -p "Masukkan Simbol Token (default: NODE): " TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    # Input jumlah kontrak
    read -p "Jumlah kontrak yang akan dideploy (default: 1): " NUM_CONTRACTS
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    # Input private key
    read -p "Masukkan Private Key Anda: " PRIVATE_KEY

    # Input RPC URL untuk Tea Sepolia
    read -p "Masukkan RPC URL (default: https://tea-sepolia.g.alchemy.com/public): " RPC_URL
    RPC_URL="${RPC_URL:-https://tea-sepolia.g.alchemy.com/public}"

    # Input Explorer URL untuk Tea Sepolia
    read -p "Masukkan Explorer URL (default: https://sepolia.tea.xyz/): " EXPLORER_URL
    EXPLORER_URL="${EXPLORER_URL:-https://sepolia.tea.xyz/}"

    # Simpan input ke file .env
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
EXPLORER_URL="$EXPLORER_URL"
VERIFIER_URL="https://sepolia.tea.xyz/api/"
CHAIN_ID="10218"
EOL

    # Konfigurasi foundry.toml
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
rpc_url = "$RPC_URL"
EOL

    echo -e "${YELLOW}Data berhasil disimpan dan konfigurasi diperbarui.${RESET}"
}

# Fungsi untuk verifikasi kontrak di Blockscout
verify_contract() {
    local contract_address="$1"
    echo -e "${YELLOW}Memulai verifikasi kontrak di Tea Sepolia Explorer untuk: $contract_address${RESET}"

    # Verifikasi kontrak menggunakan forge dengan Blockscout
    echo -e "${BLUE}Memverifikasi kontrak menggunakan forge...${RESET}"
    forge verify-contract \
        --rpc-url "$RPC_URL" \
        --verifier blockscout \
        --verifier-url "$VERIFIER_URL" \
        "$contract_address" \
        "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode"

    # Periksa hasil verifikasi
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Kontrak berhasil diverifikasi di Tea Sepolia Explorer!${RESET}"
    else
        echo -e "${RED}Verifikasi kontrak gagal untuk alamat $contract_address.${RESET}"
    fi
}

# Fungsi untuk deploy kontrak
deploy_contract() {
    echo -e "${YELLOW}-----------------------------------${RESET}"
    source "$SCRIPT_DIR/token_deployment/.env"

    # Buat direktori src jika belum ada
    mkdir -p "$SCRIPT_DIR/src"

    # Tulis kode kontrak
    cat <<EOL > "$SCRIPT_DIR/src/AirdropNode.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 1000 * (10 ** decimals()));
    }
}
EOL

    # Kompilasi kontrak
    echo -e "${BLUE}Mengompilasi kontrak...${RESET}"
    forge build || { echo -e "${RED}Kompilasi gagal.${RESET}"; exit 1; }

    # Deploy kontrak
    for i in $(seq 1 "$NUM_CONTRACTS"); do
        echo -e "${BLUE}Mendeploy kontrak $i dari $NUM_CONTRACTS...${RESET}"

        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY" \
            --broadcast)

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Deploy kontrak $i gagal.${RESET}"
            continue
        fi

        # Ambil alamat kontrak
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        echo -e "${YELLOW}Kontrak $i berhasil di-deploy di alamat: $CONTRACT_ADDRESS${RESET}"
        echo -e "${WHITE}Lihat kontrak di: ${BLUE}$EXPLORER_URL/address/$CONTRACT_ADDRESS${RESET}"

        # Verifikasi kontrak di Tea Sepolia Explorer
        verify_contract "$CONTRACT_ADDRESS"
    done
}

# Eksekusi fungsi utama
install_dependencies
input_required_details
deploy_contract

# Pesan akhir
echo -e "${YELLOW}-----------------------------------${RESET}"
echo -e "${BLUE}Gabung di channel Telegram untuk update dan bantuan: https://t.me/airdrop_node${RESET}"
