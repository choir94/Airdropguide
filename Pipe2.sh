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

# Periksa apakah URL kosong
if [[ -z "$BIN_URL" ]]; then
    echo -e "\n${RED}❌ URL tidak boleh kosong. Silakan coba lagi.${NC}\n"
    exit 1
fi

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

# Jalankan biner
echo -e "\n${GREEN}🚀 Menjalankan Pipe Network Devnet v2...${NC}"
./$BIN_NAME

# Menampilkan metrik
echo -e "\n${CYAN}📊 Menampilkan metrik...${NC}"
./pipe --status

# Memeriksa poin
echo -e "\n${CYAN}🏆 Memeriksa poin...${NC}"
./pipe --points-route

# Sukses
echo -e "\n${GREEN}✅ Instalasi selesai! Pipe Network Devnet v2 siap digunakan.${NC}\n"
