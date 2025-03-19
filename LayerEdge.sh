#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Tampilkan logo dari URL
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

echo -e "${GREEN}=== Mulai Instalasi Auto Script ===${NC}"

# Fungsi untuk memeriksa perintah
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}$1 tidak ditemukan. Silakan instal $1 terlebih dahulu.${NC}"
        exit 1
    else
        echo -e "${GREEN}$1 terdeteksi.${NC}"
    fi
}

# 1. Pengecekan Prasyarat
echo -e "${GREEN}Memeriksa prasyarat...${NC}"

# Cek Git
check_command git

# Cek Rust
check_command rustc
RUST_VERSION=$(rustc --version | cut -d' ' -f2)
if [[ "$RUST_VERSION" < "1.81.0" ]]; then
    echo -e "${RED}Rust versi $RUST_VERSION terdeteksi. Diperlukan versi 1.81.0 atau lebih tinggi.${NC}"
    exit 1
else
    echo -e "${GREEN}Rust versi $RUST_VERSION memenuhi syarat.${NC}"
fi

# Cek Go
check_command go

# Instal RISC Zero Toolchain jika belum ada
echo -e "${GREEN}Memeriksa RISC Zero Toolchain...${NC}"
if ! command -v rzup &> /dev/null; then
    echo -e "\n${YELLOW}🔹 Menginstal RISC Zero Toolchain...${NC}\n"
    curl -L https://risczero.com/install | bash && rzup install || {
        echo -e "\n${RED}⚠️ Instalasi 'rzup' gagal, mencoba kembali...${NC}\n"
        source "$HOME/.bashrc"
        rzup install
        if [ $? -ne 0 ]; then
            echo -e "${RED}Gagal menginstal RISC Zero Toolchain setelah mencoba ulang.${NC}"
            exit 1
        fi
    }
else
    echo -e "${GREEN}RISC Zero Toolchain sudah terinstal.${NC}"
fi

# Cek dan Instal Screen jika belum ada (khusus Debian/Ubuntu)
if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}Screen tidak ditemukan. Menginstal screen...${NC}"
    sudo apt-get update && sudo apt-get install -y screen
    if [ $? -ne 0 ]; then
        echo -e "${RED}Gagal menginstal screen. Silakan instal secara manual.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Screen berhasil diinstal.${NC}"
else
    echo -e "${GREEN}Screen sudah terinstal.${NC}"
fi

# 2. Clone Repository light-node
echo -e "${GREEN}Mengkloning repository light-node...${NC}"
if [ -d "light-node" ]; then
    echo -e "${GREEN}Direktori light-node sudah ada. Melewati proses clone.${NC}"
else
    git clone https://github.com/Layer-Edge/light-node.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}Gagal mengkloning repository light-node.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Repository light-node berhasil dikloning.${NC}"
fi

# 3. Konfigurasi Variabel Lingkungan
echo -e "${GREEN}Mengatur variabel lingkungan...${NC}"
echo -e "${YELLOW}Masukkan Private Key untuk cli-node (kosongkan untuk default 'cli-node-private-key'): ${NC}"
read -r PRIVATE_KEY_INPUT
if [ -z "$PRIVATE_KEY_INPUT" ]; then
    PRIVATE_KEY_INPUT="cli-node-private-key"
fi

cat <<EOL > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='$PRIVATE_KEY_INPUT'
EOL
echo -e "${GREEN}File .env telah dibuat dengan Private Key: $PRIVATE_KEY_INPUT${NC}"

# Export variabel lingkungan untuk sesi ini
export $(cat .env | xargs)

# 4. Jalankan Server risc0-merkle-service dengan Screen
echo -e "${GREEN}Membangun dan menjalankan risc0-merkle-service...${NC}"
if [ -d "risc0-merkle-service" ]; then
    cd risc0-merkle-service || {
        echo -e "${RED}Gagal masuk ke direktori risc0-merkle-service.${NC}"
        exit 1
    }
    cargo build
    if [ $? -ne 0 ]; then
        echo -e "${RED}Gagal membangun risc0-merkle-service.${NC}"
        exit 1
    fi
    screen -dmS risc0-merkle-service cargo run
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}risc0-merkle-service berjalan di sesi screen 'risc0-merkle-service'.${NC}"
        echo -e "${YELLOW}Gunakan 'screen -r risc0-merkle-service' untuk melihat output.${NC}"
    else
        echo -e "${RED}Gagal menjalankan risc0-merkle-service di screen.${NC}"
        exit 1
    fi
    cd ..
else
    echo -e "${RED}Direktori risc0-merkle-service tidak ditemukan.${NC}"
    exit 1
fi

# Tunggu beberapa detik agar server risc0 stabil
sleep 5

# 5. Jalankan Light Node dengan Screen
echo -e "${GREEN}Membangun dan menjalankan light-node...${NC}"
cd light-node || {
    echo -e "${RED}Gagal masuk ke direktori light-node.${NC}"
    exit 1
}
go build
if [ $? -ne 0 ]; then
    echo -e "${RED}Gagal membangun light-node.${NC}"
    exit 1
fi
screen -dmS light-node ./light-node
if [ $? -eq 0 ]; then
    echo -e "${GREEN}light-node berjalan di sesi screen 'light-node'.${NC}"
    echo -e "${YELLOW}Gunakan 'screen -r light-node' untuk melihat output.${NC}"
else
    echo -e "${RED}Gagal menjalankan light-node di screen.${NC}"
    exit 1
fi
cd ..

# 6. Verifikasi
echo -e "${GREEN}Memastikan kedua server berjalan...${NC}"
if screen -list | grep -q "risc0-merkle-service" && screen -list | grep -q "light-node"; then
    echo -e "${GREEN}Instalasi dan peluncuran server berhasil!${NC}"
    echo -e "${YELLOW}Sesi screen aktif: 'risc0-merkle-service' dan 'light-node'.${NC}"
else
    echo -e "${RED}Salah satu atau kedua server gagal berjalan di screen.${NC}"
    exit 1
fi

echo -e "${GREEN}=== Selesai ===${NC}"
