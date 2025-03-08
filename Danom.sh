#!/bin/bash

# Update system and install dependencies
echo "Mengupdate sistem dan menginstal dependensi..."
sudo apt update && sudo apt install -y wget curl tar screen

# Download and extract Danom
echo "Mengunduh dan mengekstrak Danom..."
wget https://github.com/DanomSite/release/releases/download/v4/DanomV4.tar.gz && tar -xvzf DanomV4.tar.gz
cd Danom

# Run installation script
echo "Menjalankan skrip instalasi..."
curl -fsSL 'https://testnet.danom.site/install.sh' | bash

# Configure wallet
echo "Mengonfigurasi wallet..."
read -p "Masukkan alamat wallet 0x Anda: " WALLET_ADDRESS
read -p "Masukkan API Hugging Face Anda: " API_TOKEN

echo '{"wallet": "'$WALLET_ADDRESS'", "pool_list": "'$API_TOKEN'"}' > wallet_config.json

# Start Danom worker in a screen session
echo "Memulai Danom worker..."
screen -S danom -dm ./danom

echo "Instalasi selesai! Worker Danom berjalan di screen session."
echo "Untuk memeriksa worker, gunakan perintah: screen -r danom"
echo "Untuk keluar dari screen, tekan CTRL + A, lalu D."
