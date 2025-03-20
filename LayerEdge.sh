#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# File log untuk debugging
LOG_FILE="$HOME/layeredge_install.log"
echo "Log instalasi akan disimpan di: $LOG_FILE"
echo "Instalasi dimulai pada $(date)" > "$LOG_FILE"

# Tampilkan logo dari URL
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash >> "$LOG_FILE" 2>&1
sleep 3  # Jeda 3 detik setelah logo

# Fungsi untuk memeriksa apakah perintah berhasil
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 berhasil${NC}"
        echo "[SUCCESS] $1 berhasil pada $(date)" >> "$LOG_FILE"
    else
        echo -e "${RED}✗ Gagal $1${NC}"
        echo "[ERROR] Gagal $1 pada $(date)" >> "$LOG_FILE"
        echo "Silakan periksa log di $LOG_FILE untuk detailnya."
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
sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
check_status "memperbarui sistem"

# Cek dan instal dependensi dasar (git, curl, screen)
echo "Memeriksa dan menginstal dependensi dasar jika belum ada..."
for pkg in git curl screen; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo "Menginstal $pkg..."
        sudo apt install -y $pkg >> "$LOG_FILE" 2>&1
        check_status "menginstal $pkg"
    else
        echo -e "${GREEN}$pkg sudah terinstal${NC}"
    fi
done

# Cek dan instal Go 1.18+
if ! command -v go >/dev/null 2>&1 || [ "$(go version | cut -d' ' -f3 | cut -d'.' -f2)" -lt 18 ]; then
    echo "Menginstal Go 1.21.8 (memenuhi syarat 1.18+)..."
    wget https://golang.org/dl/go1.21.8.linux-amd64.tar.gz -O go.tar.gz >> "$LOG_FILE" 2>&1
    sudo tar -C /usr/local -xzf go.tar.gz >> "$LOG_FILE" 2>&1
    rm go.tar.gz
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin
    go version >> "$LOG_FILE" 2>&1
    check_status "menginstal Go"
else
    echo -e "${GREEN}Go $(go version) sudah terinstal dan memenuhi syarat${NC}"
fi

# Cek dan instal Rust 1.81.0+
if ! command -v rustc >/dev/null 2>&1 || [ "$(rustc --version | cut -d' ' -f2 | cut -d'.' -f1).$(rustc --version | cut -d' ' -f2 | cut -d'.' -f2)" \< "1.81" ]; then
    echo "Menginstal Rust 1.81.0 atau lebih tinggi..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1
    source "$HOME/.cargo/env"
    rustup update >> "$LOG_FILE" 2>&1
    rustc --version >> "$LOG_FILE" 2>&1
    check_status "menginstal Rust"
else
    echo -e "${GREEN}Rust $(rustc --version) sudah terinstal dan memenuhi syarat${NC}"
fi

# Cek dan instal RISC0 toolchain
if ! command -v rzup >/dev/null 2>&1; then
    echo "Menginstal RISC0 toolchain..."
    curl -L https://risczero.com/install | bash >> "$LOG_FILE" 2>&1
    if ! grep -q "$HOME/.risc0/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:$HOME/.risc0/bin
    if ! command -v rzup >/dev/null 2>&1; then
        echo -e "${RED}✗ Instalasi RISC0 gagal. Periksa koneksi atau coba instal manual.${NC}"
        echo "Petunjuk: Jalankan 'curl -L https://risczero.com/install | bash' secara manual."
        exit 1
    fi
    rzup install >> "$LOG_FILE" 2>&1
    rzup --version >> "$LOG_FILE" 2>&1
    check_status "menginstal RISC0 toolchain"
else
    echo -e "${GREEN}RISC0 toolchain sudah terinstal$(rzup --version)${NC}"
fi

# Kloning repositori light-node jika belum ada
if [ ! -d "light-node" ]; then
    echo "Mengkloning repositori light-node..."
    git clone https://github.com/Layer-Edge/light-node.git >> "$LOG_FILE" 2>&1
    cd light-node || exit
    check_status "mengkloning repositori"
else
    echo -e "${GREEN}Repositori light-node sudah ada${NC}"
    cd light-node || exit
fi

# Minta pengguna memasukkan private key dengan aman
echo "Masukkan private key untuk light-node (kosongkan untuk menggunakan default 'cli-node-private-key'):"
echo -n "Private Key: "
read -s user_private_key
echo ""
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo -e "${RED}Menggunakan default PRIVATE_KEY='cli-node-private-key'. Ganti manual di .env atau .layer_edge_env jika perlu.${NC}"
fi

# Buat file .env di direktori light-node dengan izin ketat
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
chmod 600 .env
echo -e "${GREEN}File .env tersedia di: $(pwd)/.env (dengan izin aman)${NC}"

# Buat file .layer_edge_env di /root/ dengan izin ketat
echo "Membuat file .layer_edge_env di /root/ sebagai konfigurasi alternatif..."
cat <<EOL > /root/.layer_edge_env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='$user_private_key'
EOL
check_status "membuat file .layer_edge_env di /root/"
chmod 600 /root/.layer_edge_env
echo -e "${GREEN}File .layer_edge_env tersedia di: /root/.layer_edge_env (dengan izin aman)${NC}"

# Jalankan risc0-merkle-service di screen
echo "Membangun dan menjalankan risc0-merkle-service di screen..."
cd risc0-merkle-service || exit
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"
echo "Menunggu 2 menit agar risc0-merkle-service aktif sepenuhnya..."
sleep 120
check_status "menjalankan risc0-merkle-service"

# Kembali ke direktori light-node, bangun, dan jalankan light-node di screen
echo "Membangun light-node dengan go build..."
cd ..
go build >> "$LOG_FILE" 2>&1
check_status "membangun light-node"

# Tes jalankan light-node untuk memastikan konfigurasi dimuat
echo "Menguji apakah light-node dapat memuat konfigurasi..."
timeout 5s ./light-node > test_run.log 2>&1
if grep -q "Error loading .env file" test_run.log; then
    echo -e "${RED}✗ light-node gagal memuat .env dari $(pwd)/.env${NC}"
    echo "Mencoba menggunakan /root/.layer_edge_env sebagai alternatif..."
    timeout 5s ./light-node --config /root/.layer_edge_env > test_run.log 2>&1
    if grep -q "Error loading" test_run.log; then
        echo -e "${RED}✗ light-node masih gagal memuat konfigurasi dari /root/.layer_edge_env${NC}"
        echo "Periksa dokumentasi light-node untuk lokasi konfigurasi yang benar."
        echo "Lokasi saat ini: $(pwd)/.env dan /root/.layer_edge_env"
        exit 1
    else
        echo -e "${GREEN}✓ light-node berhasil memuat /root/.layer_edge_env${NC}"
        CONFIG_PATH="/root/.layer_edge_env"
    fi
else
    echo -e "${GREEN}✓ light-node berhasil memuat .env dari $(pwd)/.env${NC}"
    CONFIG_PATH="$(pwd)/.env"
fi
rm test_run.log

echo "Menjalankan light-node di screen dari direktori ~/light-node..."
screen -dmS light-node bash -c "./light-node --config '$CONFIG_PATH'; exec bash"
check_status "menjalankan light-node"

echo -e "${GREEN}Instalasi dan peluncuran selesai!${NC}"
echo "Periksa status dengan:"
echo "  - screen -r risc0-merkle (untuk risc0-merkle-service)"
echo "  - screen -r light-node (untuk light-node)"
echo "Keluar dari screen dengan Ctrl+A lalu D."
echo -e "${GREEN}Catatan: Untuk menjalankan manual, gunakan: cd ~/light-node && go build && ./light-node --config $CONFIG_PATH${NC}"
echo "Log instalasi tersedia di: $LOG_FILE"
echo -e "${GREEN}Keamanan: Private key disimpan di .env dan /root/.layer_edge_env dengan izin ketat (chmod 600).${NC}"
