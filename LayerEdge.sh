#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Tampilkan logo dari URL
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3  # Jeda 3 detik setelah logo

# Fungsi untuk memeriksa apakah perintah berhasil
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 berhasil${NC}"
    else
        echo -e "${RED}✗ Gagal $1${NC}"
        exit 1
    fi
}

echo "Mulai instalasi dependensi dan konfigurasi light-node..."

# Perbarui sistem
if ! command -v apt >/dev/null 2>&1; then
    echo -e "${RED}Sistem tidak mendukung apt. Skrip ini untuk Ubuntu/Debian.${NC}"
    exit 1
fi
echo "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y
check_status "memperbarui sistem"

# Cek dan instal dependensi dasar (git, curl, screen)
echo "Memeriksa dan menginstal dependensi dasar jika belum ada..."
for pkg in git curl screen; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo "Menginstal $pkg..."
        sudo apt install -y $pkg
        check_status "menginstal $pkg"
    else
        echo -e "${GREEN}$pkg sudah terinstal${NC}"
    fi
done

# Cek dan instal Go 1.18+
if ! command -v go >/dev/null 2>&1 || [ "$(go version | cut -d' ' -f3 | cut -d'.' -f2)" -lt 18 ]; then
    echo "Menginstal Go 1.21.8 (memenuhi syarat 1.18+)..."
    wget https://golang.org/dl/go1.21.8.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    go version
    check_status "menginstal Go"
else
    echo -e "${GREEN}Go $(go version) sudah terinstal dan memenuhi syarat${NC}"
fi

# Cek dan instal Rust 1.81.0+
if ! command -v rustc >/dev/null 2>&1 || [ "$(rustc --version | cut -d' ' -f2 | cut -d'.' -f1).$(rustc --version | cut -d' ' -f2 | cut -d'.' -f2)" \< "1.81" ]; then
    echo "Menginstal Rust 1.81.0 atau lebih tinggi..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup update
    rustc --version
    check_status "menginstal Rust"
else
    echo -e "${GREEN}Rust $(rustc --version) sudah terinstal dan memenuhi syarat${NC}"
fi

# Cek dan instal RISC0 toolchain
if ! command -v rzup >/dev/null 2>&1; then
    echo "Menginstal RISC0 toolchain..."
    curl -L https://risczero.com/install | bash
    echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
    source ~/.bashrc
    rzup install
    rzup --version
    check_status "menginstal RISC0 toolchain"
else
    echo -e "${GREEN}RISC0 toolchain sudah terinstal${NC}"
fi

# Kloning repositori light-node jika belum ada
if [ ! -d "light-node" ]; then
    echo "Mengkloning repositori light-node..."
    git clone https://github.com/Layer-Edge/light-node.git
    cd light-node || exit
    check_status "mengkloning repositori"
else
    echo -e "${GREEN}Repositori light-node sudah ada${NC}"
    cd light-node || exit
fi

# Minta pengguna memasukkan private key
echo "Masukkan private key untuk light-node (kosongkan untuk menggunakan default 'cli-node-private-key'):"
read -r user_private_key
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo -e "${RED}Menggunakan default PRIVATE_KEY='cli-node-private-key'. Ganti manual di .env jika perlu.${NC}"
fi

# Buat file .env di direktori light-node
echo "Membuat file .env di direktori light-node..."
cat <<EOL > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='$user_private_key'
EOL
check_status "membuat file .env di ~/light-node"
echo -e "${GREEN}File .env tersedia di: ~/light-node/.env${NC}"

# Jalankan risc0-merkle-service di screen
echo "Membangun dan menjalankan risc0-merkle-service di screen..."
cd risc0-merkle-service
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"
echo "Menunggu 2 menit agar risc0-merkle-service aktif sepenuhnya..."
sleep 120  # Tunggu 120 detik (2 menit)
check_status "menjalankan risc0-merkle-service"

# Kembali ke direktori light-node, bangun, dan jalankan light-node di screen
echo "Membangun light-node dengan go build..."
cd ..
go build
check_status "membangun light-node"

echo "Menjalankan light-node di screen dari direktori ~/light-node..."
screen -dmS light-node bash -c "./light-node; exec bash"
check_status "menjalankan light-node"

echo -e "${GREEN}Instalasi dan peluncuran selesai!${NC}"
echo "Periksa status dengan:"
echo "  - screen -r risc0-merkle (untuk risc0-merkle-service)"
echo "  - screen -r light-node (untuk light-node)"
echo "Keluar dari screen dengan Ctrl+A lalu D."
echo -e "${GREEN}Catatan: Untuk menjalankan manual, gunakan: cd ~/light-node && go build && ./light-node${NC}"
