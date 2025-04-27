#!/bin/bash

# Pastikan kita mulai di ~/Drosera
cd ~/Drosera || { echo "Error: Tidak bisa berpindah ke direktori ~/Drosera."; exit 1; }

# Fungsi untuk memeriksa keberhasilan perintah
check_status() {
    if [[ $? -ne 0 ]]; then
        echo "Error: $1 gagal. Keluar."
        exit 1
    fi
}

# Fungsi untuk memvalidasi kunci pribadi
validate_private_key() {
    local private_key=$1
    if [[ ! "$private_key" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo "Error: Format kunci pribadi tidak valid. Harus berupa 64 karakter heksadesimal."
        exit 1
    fi
}

# Membersihkan jalankan skrip sebelumnya
echo "Membersihkan jalankan skrip sebelumnya..."
pkill -f drosera-operator
sudo docker compose -f ~/Drosera-Network/docker-compose.yaml down -v 2>/dev/null
sudo docker stop drosera-node1 drosera-node2 2>/dev/null
sudo docker rm drosera-node1 drosera-node2 2>/dev/null
sudo rm -rf ~/my-drosera-trap ~/Drosera-Network ~/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz /usr/bin/drosera-operator ~/drosera-operator
check_status "Pembersihan"
source /root/.bashrc

# Mengunduh dan menampilkan logo dari repository GitHub
echo "Mengunduh dan menampilkan logo..."
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Pesan sambutan
echo "Memulai Otomatisasi Setup Testnet Drosera untuk Dua Operator"
echo "Pastikan Anda sudah membiayai dompet Holesky ETH untuk kedua operator."
echo ""

# Meminta input yang diperlukan
read -p "Masukkan kunci pribadi wallet EVM pertama (Operator 1): " OPERATOR1_PRIVATE_KEY
validate_private_key "$OPERATOR1_PRIVATE_KEY"
read -p "Masukkan alamat publik wallet pertama (Operator 1): " OPERATOR1_ADDRESS
read -p "Masukkan kunci pribadi wallet EVM kedua (Operator 2): " OPERATOR2_PRIVATE_KEY
validate_private_key "$OPERATOR2_PRIVATE_KEY"
read -p "Masukkan alamat publik wallet kedua (Operator 2): " OPERATOR2_ADDRESS

# Deteksi IP publik VPS
echo "Mendeteksi IP publik VPS..."
VPS_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)
if [[ -z "$VPS_IP" ]]; then
    read -p "Tidak dapat mendeteksi IP publik VPS. Silakan masukkan secara manual: " VPS_IP
fi
echo "IP publik VPS: $VPS_IP"
read -p "Masukkan URL RPC Ethereum Holesky Anda (dari Alchemy/QuickNode, atau tekan Enter untuk menggunakan default): " ETH_RPC_URL
if [[ -z "$ETH_RPC_URL" ]]; then
    ETH_RPC_URL="https://ethereum-holesky-rpc.publicnode.com"
fi
read -p "Masukkan email GitHub Anda: " GITHUB_EMAIL
read -p "Masukkan nama pengguna GitHub Anda: " GITHUB_USERNAME

# Langkah 1: Perbarui dan Install Dependencies
echo "Langkah 1: Memperbarui sistem dan menginstal dependensi..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
check_status "Instalasi dependensi"
source /root/.bashrc

# Langkah 2: Install Docker (jika belum terinstal)
echo "Langkah 2: Memeriksa instalasi Docker..."
if command -v docker &> /dev/null; then
    echo "Docker sudah terinstal. Melewatkan instalasi."
else
    echo "Menginstal Docker..."
    sudo apt update -y && sudo apt upgrade -y
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo docker run hello-world
    check_status "Instalasi Docker"
fi
source /root/.bashrc

# Langkah 3: Install CLIs (Drosera, Foundry, Bun)
echo "Langkah 3: Menginstal CLIs Drosera, Foundry, dan Bun..."

# Instalasi CLI Drosera
echo "Menginstal CLI Drosera..."
max_attempts=3
attempt=1
while [[ $attempt -le $max_attempts ]]; do
    echo "Percobaan $attempt/$max_attempts: Menginstal CLI Drosera..."
    curl -L https://app.drosera.io/install | bash
    sleep 3
    source /root/.bashrc
    sleep 2
    if [[ -d "/root/.drosera/bin" ]]; then
        export PATH=$PATH:/root/.drosera/bin
        echo 'export PATH=$PATH:/root/.drosera/bin' >> /root/.bashrc
        source /root/.bashrc
    fi
    if command -v droseraup &> /dev/null; then
        droseraup
        source /root/.bashrc
        if command -v drosera &> /dev/null; then
            echo "Berhasil: CLI Drosera terinstal."
            break
        else
            echo "CLI Drosera belum terinstal sepenuhnya."
        fi
    else
        echo "Perintah droseraup tidak ditemukan."
    fi
    ((attempt++))
    if [[ $attempt -le $max_attempts ]]; then
        echo "Mencoba lagi dalam 10 detik..."
        sleep 10
    else
        echo "Error: Gagal menginstal CLI Drosera setelah $max_attempts percobaan."
        exit 1
    fi
done
check_status "Instalasi CLI Drosera"
source /root/.bashrc

# Instalasi CLI Foundry
echo "Menginstal CLI Foundry..."
max_attempts=3
attempt=1
while [[ $attempt -le $max_attempts ]]; do
    echo "Percobaan $attempt/$max_attempts: Menginstal CLI Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    sleep 3
    source /root/.bashrc
    if command -v foundryup &> /dev/null; then
        foundryup
        if command -v forge &> /dev/null; then
            echo "Berhasil: CLI Foundry terinstal."
            break
        else
            echo "CLI Foundry belum terinstal sepenuhnya."
        fi
    else
        echo "Perintah foundryup tidak ditemukan."
    fi
    ((attempt++))
    if [[ $attempt -le $max_attempts ]]; then
        echo "Mencoba lagi dalam 10 detik..."
        sleep 10
    else
        echo "Error: Gagal menginstal CLI Foundry setelah $max_attempts percobaan."
        exit 1
    fi
done
check_status "Instalasi CLI Foundry"
source /root/.bashrc

# Instalasi CLI Bun
echo "Menginstal CLI Bun..."
max_attempts=3
attempt=1
while [[ $attempt -le $max_attempts ]]; do
    echo "Percobaan $attempt/$max_attempts: Menginstal CLI Bun..."
    curl -fsSL https://bun.sh/install | bash
    sleep 3
    source /root/.bashrc
    if command -v bun &> /dev/null; then
        echo "Berhasil: CLI Bun terinstal."
        break
    else
        echo "Perintah bun tidak ditemukan."
    fi
    ((attempt++))
    if [[ $attempt -le $max_attempts ]]; then
        echo "Mencoba lagi dalam 10 detik..."
        sleep 10
    else
        echo "Error: Gagal menginstal CLI Bun setelah $max_attempts percobaan."
        exit 1
    fi
done
check_status "Instalasi CLI Bun"
source /root/.bashrc

# Langkah 4: Setup Trap dan Operator
echo "Langkah 4: Menyiapkan Trap dan Operator di Testnet Drosera..."
trap_dir=~/my-drosera-trap

# Membuat dan menyiapkan direktori Trap
echo "Membuat direktori Trap dan mengonfigurasi..."
mkdir -p $trap_dir
# (Sisa kode setup Trap di sini...)

echo "Setup Testnet Drosera selesai!"
