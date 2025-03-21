#!/bin/bash
# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Fungsi untuk memeriksa apakah perintah berhasil
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 berhasil${NC}"
    else
        echo -e "${RED}✗ Gagal $1${NC}"
        exit 1
    fi
}

echo "Mulai instalasi otomatis light-node dan dependensinya..."

# Perbarui sistem
echo "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y
check_status "memperbarui sistem"

# Instal dependensi dasar (git, curl, screen)
echo "Menginstal dependensi dasar..."
sudo apt install -y git curl screen
check_status "menginstal dependensi dasar"

# Cek dan instal Go (versi 1.21.6)
if ! command -v go >/dev/null 2>&1 || [ "$(go version | cut -d' ' -f3 | cut -d'.' -f2)" -lt 21 ]; then
    echo "Menginstal Go 1.21.6..."
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
    rm go1.21.6.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    go version
    check_status "menginstal Go"
else
    echo -e "${GREEN}Go $(go version) sudah terinstal dan memenuhi syarat (1.21.6 atau lebih tinggi)${NC}"
fi

# Cek dan instal Rust (versi 1.85.1)
if ! command -v rustc >/dev/null 2>&1 || [ "$(rustc --version | cut -d' ' -f2 | cut -d'.' -f1).$(rustc --version | cut -d' ' -f2 | cut -d'.' -f2)" \< "1.85" ]; then
    echo "Menginstal Rust 1.85.1..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup install 1.85.1
    rustup default 1.85.1
    rustc --version
    check_status "menginstal Rust"
else
    echo -e "${GREEN}Rust $(rustc --version) sudah terinstal dan memenuhi syarat (1.85.1)${NC}"
fi

# Instal RISC0 toolchain
echo "Menginstal RISC0 toolchain..."
curl -L https://risczero.com/install | bash
echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
source ~/.bashrc
rzup install
check_status "menginstal RISC0 toolchain"

# Kloning repositori light-node
if [ ! -d "~/light-node" ]; then
    echo "Mengkloning repositori light-node..."
    git clone https://github.com/Layer-Edge/light-node.git ~/light-node
    check_status "mengkloning repositori"
fi

# Masuk ke folder light-node
cd ~/light-node || exit

# Minta private key dari pengguna dan hapus 0x jika ada
echo "Masukkan private key untuk light-node (tanpa awalan '0x', kosongkan untuk default 'cli-node-private-key'):"
read -r user_private_key
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo -e "${RED}Menggunakan default PRIVATE_KEY='cli-node-private-key'${NC}"
else
    # Hapus 0x dari awal jika pengguna memasukkannya
    user_private_key=$(echo "$user_private_key" | sed 's/^0x//')
    echo -e "${GREEN}Private key diterima: $user_private_key${NC}"
fi

# Buat file .env dengan konfigurasi
echo "Membuat file .env di ~/light-node..."
cat <<EOL > ~/light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='$user_private_key'
EOL
check_status "membuat file .env"

# Masuk ke folder risc0-merkle-service
cd ~/light-node/risc0-merkle-service || exit

# Jalankan risc0-merkle-service di screen
echo "Menjalankan risc0-merkle-service..."
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"
check_status "menjalankan risc0-merkle-service"

# Tunggu beberapa menit agar risc0-merkle-service siap
echo "Menunggu 5 menit untuk risc0-merkle-service..."
sleep 300

# Pastikan kembali berada di direktori light-node sebelum menjalankan light-node
cd ~/light-node || exit

# Jalankan light-node di screen
echo "Membangun dan menjalankan light-node..."
go build
check_status "membangun light-node"
screen -dmS light-node bash -c "./light-node; exec bash"
check_status "menjalankan light-node"

echo -e "${GREEN}Instalasi otomatis selesai!${NC}"
echo "Periksa status dengan:"
echo "  - screen -r risc0-merkle"
echo "  - screen -r light-node"
echo "Keluar dari screen dengan Ctrl+A lalu D"
