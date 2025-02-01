#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Fungsi untuk menampilkan pesan sukses
function success_message {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Fungsi untuk menampilkan pesan proses
function info_message {
    echo -e "${CYAN}[-] $1...${NC}"
}

# Fungsi untuk menampilkan pesan kesalahan
function error_message {
    echo -e "${RED}[✘] $1${NC}"
}

# Pembersihan layar
clear
echo -e "${CYAN}========================================"
echo "   Privasea Acceleration Node Setup (RTX GPU Mode)"
echo -e "========================================${NC}"
echo ""

# 🔹 **Langkah 1: Pastikan Driver NVIDIA dan Firejail Terinstal**
info_message "Memeriksa driver NVIDIA dan Firejail..."
if ! command -v nvidia-smi &> /dev/null; then
    error_message "Driver NVIDIA tidak ditemukan! Pastikan Anda menggunakan GPU RTX!"
    exit 1
fi

if ! command -v firejail &> /dev/null; then
    info_message "Menginstal Firejail..."
    sudo apt update && sudo apt install -y firejail
    success_message "Firejail berhasil diinstal."
fi

echo ""

# 🔹 **Langkah 2: Konfigurasi Firejail untuk Akses GPU**
info_message "Mengatur Firejail agar bisa menggunakan GPU..."
echo "whitelist /dev/nvidia*" | sudo tee -a /etc/firejail/gpu.profile
echo "whitelist /dev/dri" | sudo tee -a /etc/firejail/gpu.profile
success_message "Konfigurasi Firejail berhasil diperbarui."

echo ""

# 🔹 **Langkah 3: Pastikan Docker Terinstal**
if ! command -v docker &> /dev/null; then
    info_message "Menginstal Docker..."
    sudo apt update && sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    success_message "Docker berhasil diinstal."
else
    success_message "Docker sudah terpasang."
fi

echo ""

# 🔹 **Langkah 4: Tarik Gambar Docker**
info_message "Mengunduh gambar Docker..."
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Gambar Docker berhasil diunduh."
else
    error_message "Gagal mengunduh gambar Docker."
    exit 1
fi

echo ""

# 🔹 **Langkah 5: Buat Direktori Konfigurasi**
info_message "Membuat direktori konfigurasi..."
mkdir -p $HOME/privasea/config && success_message "Direktori konfigurasi berhasil dibuat."

echo ""

# 🔹 **Langkah 6: Periksa dan Buat File Keystore jika Belum Ada**
if [ -f "$HOME/privasea/config/wallet_keystore" ]; then
    success_message "File keystore sudah ada. Melewati pembuatan keystore."
else
    info_message "Membuat file keystore..."
    if firejail --profile=gpu.profile --noprofile docker run -it -v "$HOME/privasea/config:/app/config" \
    privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
        success_message "File keystore berhasil dibuat."
    else
        error_message "Gagal membuat file keystore."
        exit 1
    fi

    echo ""

    # 🔹 **Langkah 7: Pindahkan File Keystore**
    info_message "Memindahkan file keystore..."
    if mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore; then
        success_message "File keystore berhasil dipindahkan ke wallet_keystore."
    else
        error_message "Gagal memindahkan file keystore."
        exit 1
    fi
fi

echo ""

# 🔹 **Langkah 8: Konfirmasi untuk Menjalankan Node**
read -p "Apakah Anda ingin melanjutkan untuk menjalankan node (y/n)? " choice
if [[ "$choice" != "y" ]]; then
    echo -e "${CYAN}Proses dibatalkan.${NC}"
    exit 0
fi

# 🔹 **Langkah 9: Memasukkan Password Keystore**
info_message "Masukkan password untuk keystore (untuk mengakses node):"
read -s KeystorePassword
echo ""

# 🔹 **Langkah 10: Setup Supervisord untuk Menjalankan Node**
info_message "Mengatur supervisord untuk menjalankan node..."
# Membuat file konfigurasi supervisord untuk node
cat <<EOF | sudo tee /etc/supervisor/conf.d/privasea_node.conf
[program:privasea_node]
command=docker run -d -v $HOME/privasea/config:/app/config \
-e KEYSTORE_PASSWORD=$KeystorePassword --device=/dev/nvidia0 --device=/dev/nvidiactl \
privasea/acceleration-node-beta:latest
autostart=true
autorestart=true
stderr_logfile=/var/log/privasea_node.err.log
stdout_logfile=/var/log/privasea_node.out.log
EOF

# Memulai supervisord dan node
sudo systemctl restart supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start privasea_node

success_message "Node berhasil dijalankan dengan supervisord!"

echo ""

# 🔹 **Langkah 11: Informasi Akhir**
echo -e "${GREEN}========================================"
echo "   Script dibuat oleh airdrop_node"
echo -e "========================================${NC}"
echo ""
echo -e "${CYAN}File konfigurasi tersedia di:${NC} $HOME/privasea/config"
echo -e "${CYAN}Keystore disimpan sebagai:${NC} wallet_keystore"
echo -e "${CYAN}Password Keystore yang digunakan:${NC} (disembunyikan demi keamanan)"
echo ""
