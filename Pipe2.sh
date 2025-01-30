#!/bin/bash

# Warna teks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header
clear
echo -e "${CYAN}============================================="
echo -e "  🚀 Pipe Network Devnet v2 Installer"
echo -e "  🛠️  Script by Airdrop Node"
echo -e "=============================================${NC}\n"

# Meminta URL dari pengguna
read -p "🔗 Masukkan URL biner yang dikompilasi: " BIN_URL

# Nama file biner
BIN_NAME="pipe"

# Meminta Public Key dari pengguna
read -p "🔑 Masukkan Public Key: " PUB_KEY

# Meminta ukuran RAM (dalam GB)
read -p "💻 Masukkan ukuran RAM (dalam GB): " RAM_SIZE

# Meminta ukuran disk maksimum (dalam GB)
read -p "💾 Masukkan ukuran disk maksimum (dalam GB): " MAX_DISK

# Memeriksa apakah URL atau Public Key kosong
if [[ -z "$BIN_URL" || -z "$PUB_KEY" || -z "$RAM_SIZE" || -z "$MAX_DISK" ]]; then
    echo -e "\n${RED}❌ Semua input harus diisi. Silakan coba lagi.${NC}\n"
    exit 1
fi

# Menentukan direktori untuk Pipe Network
PIPE_DIR="./pipe"

# Membuat direktori pipe jika belum ada
if [[ ! -d "$PIPE_DIR" ]]; then
    echo -e "\n${YELLOW}📂 Membuat direktori 'pipe'...${NC}"
    mkdir -p "$PIPE_DIR"
fi

# Masuk ke direktori pipe
cd "$PIPE_DIR" || exit

# Unduh biner
echo -e "\n${YELLOW}📥 Mengunduh biner dari: ${BIN_URL} ...${NC}\n"
wget -O $BIN_NAME $BIN_URL

# Periksa apakah unduhan berhasil
if [[ ! -f "$BIN_NAME" ]]; then
    echo -e "\n${RED}❌ Gagal mengunduh biner. Periksa URL dan coba lagi.${NC}\n"
    exit 1
fi

# Berikan izin eksekusi
echo -e "\n${YELLOW}🔑 Memberikan izin eksekusi pada biner...${NC}"
chmod +x $BIN_NAME

# Buat direktori cache jika belum ada
echo -e "\n${YELLOW}📂 Membuat direktori 'download_cache'...${NC}"
mkdir -p download_cache

# Jalankan biner dengan parameter tambahan
echo -e "\n${GREEN}🚀 Menjalankan Pipe Network Devnet v2 dengan konfigurasi berikut:${NC}"
echo -e "  RAM: ${RAM_SIZE} GB"
echo -e "  Disk Maksimum: ${MAX_DISK} GB"
echo -e "  Cache Directory: /data"
echo -e "  Public Key: ${PUB_KEY}\n"

./$BIN_NAME \
  --ram $RAM_SIZE \
  --max-disk $MAX_DISK \
  --cache-dir /data \
  --pubKey $PUB_KEY

# Sukses
echo -e "\n${GREEN}✅ Instalasi selesai! Pipe Network Devnet v2 siap digunakan.${NC}\n"
