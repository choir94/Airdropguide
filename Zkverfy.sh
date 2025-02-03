#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

set -e  # Hentikan skrip jika ada error

# ============================================================
# 🎨 Fungsi untuk Menampilkan Pesan Berwarna
# ============================================================

GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RED="\e[31m"
BOLD="\e[1m"
RESET="\e[0m"

echo_info() {
    echo -e "\n${GREEN}[INFO] $1${RESET}\n"
}

echo_warn() {
    echo -e "\n${YELLOW}[WARNING] $1${RESET}\n"
}

echo_error() {
    echo -e "\n${RED}[ERROR] $1${RESET}\n"
}

# ============================================================
# 1️⃣ Cek dan Install Docker & Docker Compose
# ============================================================
echo_info "🔄 ${BOLD}Memeriksa instalasi Docker, Docker Compose, dan jq...${RESET}"

# Cek apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo_warn "🔴 Docker tidak terinstal. Menginstal Docker..."
    
    # Install dependencies untuk Docker
    echo_info "⚙️ Menginstal dependensi untuk Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Menambahkan Docker repository dan menginstal Docker
    echo_info "📥 Mengunduh dan menginstal Docker menggunakan get.docker.com..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
else
    echo_info "✅ Docker sudah terinstal."
fi

# Install jq jika belum ada
if ! command -v jq &> /dev/null; then
    echo_warn "🔴 jq tidak terinstal. Menginstal jq..."
    sudo apt install jq -y
else
    echo_info "✅ jq sudah terinstal."
fi

# Cek apakah Docker Compose sudah terinstal
echo_info "🔄 ${BOLD}Memeriksa versi Docker Compose...${RESET}"

if ! command -v docker-compose &> /dev/null || ! docker-compose --version &> /dev/null; then
    echo_warn "🔴 Docker Compose tidak terinstal atau versinya gagal. Menginstal ulang Docker Compose..."

    # Menghapus Docker Compose yang ada jika ada masalah
    sudo rm -f /usr/local/bin/docker-compose

    # Menginstal Docker Compose versi terbaru menggunakan curl
    echo_info "⚙️ Menginstal Docker Compose versi terbaru..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Memberikan hak akses eksekusi pada file binary docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo_info "✅ Docker Compose sudah terinstal dan versi valid."
fi

# ============================================================
# 2️⃣ Tambahkan User ke Grup Docker
# ============================================================
echo_info "➕ ${BOLD}Menambahkan user ke grup Docker...${RESET}"
sudo usermod -aG docker $USER
newgrp docker  # Menerapkan perubahan grup tanpa perlu logout

# ============================================================
# 3️⃣ Buat User zkverify & Tambahkan ke Grup Docker
# ============================================================
echo_info "👤 ${BOLD}Membuat user 'zkverify' jika belum ada...${RESET}"
if ! id "zkverify" &>/dev/null; then
    sudo useradd -m -s /bin/bash zkverify
    echo "zkverify:zkverify" | sudo chpasswd
    sudo usermod -aG docker zkverify
    echo_info "✅ User 'zkverify' berhasil dibuat!"
else
    echo_warn "⏩ User 'zkverify' sudah ada, melewati pembuatan user."
fi

# ============================================================
# 4️⃣ Berpindah ke User zkverify dan Memulai Instalasi
# ============================================================
echo_info "🔄 ${BOLD}Berpindah ke user 'zkverify' dan memulai instalasi...${RESET}"
sudo -i -u zkverify bash << 'EOF'
set -e  # Hentikan jika ada error
cd ~

# ============================================================
# 5️⃣ Clone Repository jika Belum Ada
# ============================================================
if [ ! -d "compose-zkverify-simplified" ]; then
    echo -e "\n${CYAN}[INFO] 📥 Mengunduh repository ZKVerify...${RESET}\n"
    git clone https://github.com/zkVerify/compose-zkverify-simplified.git
else
    echo -e "\n${YELLOW}[WARNING] ⏩ Repository sudah ada, melewati cloning.${RESET}\n"
fi

cd compose-zkverify-simplified

# ============================================================
# 6️⃣ Jalankan Skrip Init
# ============================================================
echo -e "\n${BLUE}[INFO] ⚙️ Menjalankan skrip init...${RESET}\n"
echo -e "1\n2\ny\nn\nn" | ./scripts/init.sh

# ============================================================
# 7️⃣ Jalankan Node
# ============================================================
echo -e "\n${CYAN}[INFO] 🚀 Menjalankan node ZKVerify...${RESET}\n"
echo -e "1\n2" | ./scripts/start.sh
cd deployments/validator-node/testnet
docker compose up -d
EOF

# ============================================================
# 8️⃣ Verifikasi Apakah Container Berjalan
# ============================================================
echo_info "🔍 ${BOLD}Memeriksa status container validator...${RESET}"
if docker ps --format "{{.Names}}" | grep -q "validator"; then
    echo_info "✅ Node ZKVerify berhasil dijalankan!"
else
    echo_error "❌ Node ZKVerify gagal dijalankan. Cek log untuk detail."
fi

# ============================================================
# 9️⃣ Informasi Tambahan Setelah Instalasi
# ============================================================
echo_info "ℹ️ ${BOLD}Gunakan perintah berikut untuk mengecek log:${RESET}"
echo -e "${YELLOW}  docker logs -f \$(docker ps --format \"{{.Names}}\" | grep validator)${RESET}"
echo -e "\n✅ ${BOLD}Instalasi selesai! 🚀${RESET}"
