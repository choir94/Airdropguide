#!/bin/bash

set -e  # Hentikan skrip jika terjadi error

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
# 1️⃣ Update Sistem & Install Dependensi
# ============================================================
echo_info "🔄 ${BOLD}Mengupdate sistem & menginstal dependensi...${RESET}"
sudo apt update && sudo apt install -y docker.io docker-compose jq sed git

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
