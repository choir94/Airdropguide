#!/bin/bash

# ------------------------------------------------------
# 1. Memperbarui sistem dan meng-upgrade paket
# ------------------------------------------------------
echo -e "\033[1;35mMelakukan update dan upgrade sistem...\033[0m"
sudo apt update && sudo apt upgrade -y
echo -e "\033[1;35mUpdate dan upgrade selesai.\033[0m"

# ------------------------------------------------------
# 2. Memastikan curl dan jq terinstal
# ------------------------------------------------------
echo -e "\033[1;34mMemastikan curl dan jq terinstal...\033[0m"
sudo apt install -y curl jq
echo -e "\033[1;32mcurl dan jq telah terinstal.\033[0m"

# ------------------------------------------------------
# 3. Mengatur IP Publik untuk Discovery
# ------------------------------------------------------
echo -e "\033[1;32mMendapatkan IP Publik untuk discovery...\033[0m"
export PUBLIC_IP=$(curl -s ifconfig.me)
echo -e "\033[1;32mIP Publik Anda adalah: $PUBLIC_IP\033[0m"

# ------------------------------------------------------
# 4. Mengkloning Repositori dan Menyiapkan Data
# ------------------------------------------------------
echo -e "\033[1;35mMengkloning repositori docker-scripts...\033[0m"
git clone https://github.com/overprotocol/docker-scripts.git
mv docker-scripts overprotocol
cd overprotocol

echo -e "\033[1;35mInisialisasi direktori data dan JWT token...\033[0m"
make init

# ------------------------------------------------------
# 5. Menjalankan Full Node
# ------------------------------------------------------
echo -e "\033[1;34mMenjalankan full node...\033[0m"
docker-compose -f mainnet.yml up -d

# ------------------------------------------------------
# 6. Memeriksa Kesehatan Node
# ------------------------------------------------------
echo -e "\033[1;36mMemeriksa status sinkronisasi node...\033[0m"
curl 127.0.0.1:3500/eth/v1/node/syncing | jq

# ------------------------------------------------------
# 7. Menunggu Sinkronisasi
# ------------------------------------------------------
echo -e "\033[1;31mMenunggu 120 detik sebelum melanjutkan...\033[0m"
sleep 120

# ------------------------------------------------------
# 8. Menghasilkan Kunci Validator
# ------------------------------------------------------
echo -e "\033[1;33mMenghasilkan kunci validator...\033[0m"
docker run -it --rm -v $(pwd)/validator_keys:/app/validator_keys overfoundation/staking-deposit-cli:v2.7.2 new-mnemonic

echo -e "\033[1;33mKunci validator telah dihasilkan dalam direktori ./validator_keys\033[0m"

# ------------------------------------------------------
# 9. Membuat Deposit Data untuk Validator
# ------------------------------------------------------
echo -e "\033[1;32mMembuat deposit data dan kunci validator...\033[0m"
# Pastikan Anda sudah mengganti file dengan deposit_data-*.json dan keystore-m_*.json

# ------------------------------------------------------
# 10. Membangun Kontainer Staking
# ------------------------------------------------------
echo -e "\033[1;36mMembangun kontainer untuk mengirim transaksi deposit...\033[0m"
docker build -t over-staking send-deposit/

# ------------------------------------------------------
# 11. Memasukkan Input Pengguna untuk Variabel Lingkungan
# ------------------------------------------------------
read -p "$(echo -e "\033[1;34mMasukkan URL RPC Publik: \033[0m")" PUBLIC_RPC_URL
read -p "$(echo -e "\033[1;34mMasukkan Private Key Anda (dengan awalan 0x): \033[0m")" PRIVATE_KEY
read -p "$(echo -e "\033[1;34mMasukkan Nama File Deposit Data (misalnya deposit_data-xxxx.json): \033[0m")" DEPOSIT_DATA_FILE_NAME
read -p "$(echo -e "\033[1;34mMasukkan Alamat Over untuk Penerima Biaya: \033[0m")" SUGGESTED_FEE_RECIPIENT

# ------------------------------------------------------
# 12. Menjalankan Kontainer Deposit dengan Kunci Pribadi dan Data
# ------------------------------------------------------
echo -e "\033[1;33mMenjalankan kontainer untuk mengirim transaksi deposit...\033[0m"
docker run -v $(pwd)/validator_keys:/app/validator_keys \
  -e PUBLIC_RPC_URL=$PUBLIC_RPC_URL \
  -e PRIVATE_KEY=$PRIVATE_KEY \
  -e DEPOSIT_DATA_FILE_NAME=$DEPOSIT_DATA_FILE_NAME \
  -e SUGGESTED_FEE_RECIPIENT=$SUGGESTED_FEE_RECIPIENT \
  over-staking

# ------------------------------------------------------
# 13. Mengimpor Penyimpanan Kunci Validator
# ------------------------------------------------------
echo -e "\033[1;35mMengimpor penyimpanan kunci validator...\033[0m"
docker run -it -v $(pwd)/validator_keys:/keys \
  -v $(pwd)/wallet:/wallet \
  --name validator \
  overfoundation/chronos-validator:latest \
  accounts import \
  --keys-dir=/keys \
  --wallet-dir=/wallet \
  --accept-terms-of-use

# ------------------------------------------------------
# 14. Menjalankan Klien Validator dengan Node Penuh
# ------------------------------------------------------
echo -e "\033[1;32mMenjalankan klien validator dengan node penuh...\033[0m"
docker compose -f mainnet-validator.yml up -d

# ------------------------------------------------------
# 15. Memeriksa Log Validator
# ------------------------------------------------------
echo -e "\033[1;36mMemeriksa log dari validator...\033[0m"
docker logs validator -f

echo -e "\033[1;32mProses instalasi dan setup selesai!\033[0m"