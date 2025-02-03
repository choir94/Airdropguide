#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

set -e  # Hentikan skrip jika ada error

# ============================================================
# Cek dan Install Docker & Docker Compose
# ============================================================
echo "Memeriksa instalasi Docker, Docker Compose, dan jq..."

# Cek apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo "Docker tidak terinstal. Menginstal Docker..."
    
    # Install dependencies untuk Docker
    echo "Menginstal dependensi untuk Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Menambahkan Docker repository dan menginstal Docker
    echo "Mengunduh dan menginstal Docker menggunakan get.docker.com..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
else
    echo "Docker sudah terinstal."
fi

# Install jq jika belum ada
if ! command -v jq &> /dev/null; then
    echo "jq tidak terinstal. Menginstal jq..."
    sudo apt install jq -y
else
    echo "jq sudah terinstal."
fi

# Cek apakah Docker Compose sudah terinstal
echo "Memeriksa versi Docker Compose..."

if ! command -v docker-compose &> /dev/null || ! docker-compose --version &> /dev/null; then
    echo "Docker Compose tidak terinstal atau versinya gagal. Menginstal ulang Docker Compose..."

    # Menghapus Docker Compose yang ada jika ada masalah
    sudo rm -f /usr/local/bin/docker-compose

    # Menginstal Docker Compose versi terbaru menggunakan curl
    echo "Menginstal Docker Compose versi terbaru..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Memberikan hak akses eksekusi pada file binary docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose sudah terinstal dan versi valid."
fi

# ============================================================
# Tambahkan User ke Grup Docker
# ============================================================
echo "Menambahkan user ke grup Docker..."
sudo usermod -aG docker $USER
newgrp docker  # Menerapkan perubahan grup tanpa perlu logout

# ============================================================
# Input Nama User zkverify
# ============================================================
echo "Masukkan nama user untuk zkverify (default: zkverify): "
read -p "Nama User: " zkverify_user
zkverify_user=${zkverify_user:-zkverify}  # Default ke 'zkverify' jika tidak ada input

echo "Membuat user '$zkverify_user' jika belum ada..."

# Cek apakah user zkverify_user sudah ada
if ! id "$zkverify_user" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$zkverify_user"
    echo "$zkverify_user:$zkverify_user" | sudo chpasswd
    sudo usermod -aG docker "$zkverify_user"
    echo "User '$zkverify_user' berhasil dibuat!"
else
    echo "User '$zkverify_user' sudah ada, melewati pembuatan user."
fi

# ============================================================
# Berpindah ke User zkverify_user dan Memulai Instalasi
# ============================================================
echo "Berpindah ke user '$zkverify_user' dan memulai instalasi..."
sudo -i -u "$zkverify_user" bash << EOF
set -e  # Hentikan jika ada error
cd ~

# ============================================================
# Clone Repository jika Belum Ada
# ============================================================
if [ ! -d "compose-zkverify-simplified" ]; then
    echo "Mengunduh repository ZKVerify..."
    git clone https://github.com/zkVerify/compose-zkverify-simplified.git
else
    echo "Repository sudah ada, melewati cloning."
fi

cd compose-zkverify-simplified

# ============================================================
# Jalankan Skrip Init
# ============================================================
echo "Menjalankan skrip init..."
echo -e "1\n2\ny\nn\nn" | ./scripts/init.sh

# ============================================================
# Jalankan Node
# ============================================================
echo "Menjalankan node ZKVerify..."
echo -e "1\n2" | ./scripts/start.sh
cd deployments/validator-node/testnet
docker compose up -d
EOF

# ============================================================
# Verifikasi Apakah Container Berjalan
# ============================================================
echo "Memeriksa status container validator..."
if docker ps --format "{{.Names}}" | grep -q "validator"; then
    echo "Node ZKVerify berhasil dijalankan!"
else
    echo "Node ZKVerify gagal dijalankan. Cek log untuk detail."
fi

# ============================================================
# Informasi Tambahan Setelah Instalasi
# ============================================================
echo "Gunakan perintah berikut untuk mengecek log:"
echo "  docker logs -f \$(docker ps --format \"{{.Names}}\" | grep validator)"
echo "Instalasi selesai!"
