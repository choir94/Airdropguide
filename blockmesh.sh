#!/bin/bash

# Warna
MERAH="\033[1;31m"
HIJAU="\033[1;32m"
KUNING="\033[1;33m"
BIRU="\033[1;34m"
NOL="\033[0m" # Reset warna

# Skrip instalasi logo
echo -e "${HIJAU}Menampilkan logo...${NOL}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

echo -e "${HIJAU}Memperbarui sistem...${NOL}"
sudo apt update && sudo apt upgrade -y

echo -e "${KUNING}Menghapus file yang lama...${NOL}"
sudo rm -rf blockmesh-cli.tar.gz target

if ! command -v docker &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker...${NOL}"
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo -e "${HIJAU}Docker sudah terpasang, melewati...${NOL}"
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker Compose...${NOL}"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose.tmp
    if [[ -f /usr/local/bin/docker-compose ]]; then
        sudo rm /usr/local/bin/docker-compose
    fi
    sudo mv /usr/local/bin/docker-compose.tmp /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${HIJAU}Docker Compose sudah terpasang, melewati...${NOL}"
fi

echo -e "${KUNING}Membuat direktori target/release...${NOL}"
sudo mkdir -p target/release

echo -e "${BIRU}Mengunduh dan mengekstrak BlockMesh CLI...${NOL}"
curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest \
| grep -oP '"browser_download_url": "\K(.*blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz)' \
| xargs sudo curl -L -o blockmesh-cli.tar.gz
sudo tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

if [[ ! -f target/release/blockmesh-cli ]]; then
    echo -e "${MERAH}Error: file biner blockmesh-cli tidak ditemukan di target/release. Keluar...${NOL}"
    exit 1
fi

read -p "Masukkan email BlockMesh Anda: " email
read -s -p "Masukkan kata sandi BlockMesh Anda: " password
echo

if ! sudo docker ps --filter "name=blockmesh-cli-container" | grep -q 'blockmesh-cli-container'; then
    echo -e "${HIJAU}Membuat kontainer Docker untuk BlockMesh CLI...${NOL}"
    sudo docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
else
    echo -e "${HIJAU}Kontainer BlockMesh CLI sudah berjalan, melewati...${NOL}"
fi
