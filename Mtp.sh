#!/bin/bash

# Kode warna
RED="\033[1;31m"
LIGHT_GREEN="\033[1;92m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

# Fungsi untuk mengecek apakah perintah terakhir berhasil
check_command_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌  Terjadi kesalahan. Periksa pesan di atas untuk detailnya.${RESET}"
        exit 1
    fi
}

# Logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Memeriksa apakah Docker sudah terpasang
if command -v docker &> /dev/null; then
    echo -e "${LIGHT_GREEN}✅  Docker sudah terinstal. Melewati langkah instalasi Docker...${RESET}\n"
else
    # Memperbarui sistem
    echo -e "${BLUE}🔄  Memperbarui daftar paket...${RESET}"
    sudo apt-get update -y && sudo apt-get upgrade -y
    check_command_success

    # Menginstal dependensi yang diperlukan
    echo -e "${BLUE}📦  Menginstal dependensi...${RESET}"
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    check_command_success

    # Menambahkan GPG key resmi Docker
    echo -e "${CYAN}🔑  Menambahkan GPG key Docker...${RESET}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    check_command_success

    # Menambahkan repository Docker
    echo -e "${CYAN}📂  Menambahkan repository Docker...${RESET}"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_command_success

    # Memperbarui daftar paket untuk repository baru
    echo -e "${BLUE}🔄  Memperbarui daftar paket untuk repository Docker...${RESET}"
    sudo apt-get update -y
    check_command_success

    # Menginstal Docker
    echo -e "${CYAN}🐳  Menginstal Docker CE...${RESET}"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    check_command_success

    # Menambahkan pengguna ke grup Docker
    echo -e "${CYAN}👤  Menambahkan pengguna Anda ke grup Docker agar dapat menggunakan Docker tanpa sudo...${RESET}"
    sudo usermod -aG docker $USER
    check_command_success

    # Memberikan informasi logout untuk grup Docker
    echo -e "\n${YELLOW}⚠️  Untuk menggunakan Docker tanpa sudo, Anda perlu logout dan login kembali, atau jalankan perintah berikut:${RESET}"
    echo -e "${WHITE}     newgrp docker${RESET}\n"
fi

# Memeriksa arsitektur Linux
ARCHITECTURE=$(uname -m)

# Menentukan URL unduhan berdasarkan arsitektur
if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    DOWNLOAD_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo -e "${CYAN}🔄  Arsitektur Linux Anda adalah X64. Mengunduh client untuk X64...${RESET}"
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    DOWNLOAD_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    echo -e "${CYAN}🔄  Arsitektur Linux Anda adalah ARM64. Mengunduh client untuk ARM64...${RESET}"
else
    echo -e "${RED}❌  Arsitektur Linux tidak dikenali. Proses unduhan dibatalkan.${RESET}"
    exit 1
fi

# Mengunduh file berdasarkan URL yang ditentukan
echo -e "${BLUE}📥  Mengunduh file Multiple CLI...${RESET}"
wget $DOWNLOAD_URL
check_command_success

# Mengekstrak file
echo -e "${BLUE}📂  Mengekstrak file Multiple CLI...${RESET}"
tar -xvf multipleforlinux.tar
check_command_success

# Memberikan izin eksekusi
echo -e "${CYAN}🔧  Memberikan izin eksekusi untuk Multiple CLI...${RESET}"
chmod +x ./multiple-cli
chmod +x ./multiple-node
check_command_success

# Menetapkan PATH
echo -e "${CYAN}🔧  Menetapkan PATH untuk Multiple CLI...${RESET}"
PATH=$PATH:$(pwd)
echo "export PATH=$PATH" | sudo tee -a /etc/profile > /dev/null
source /etc/profile
check_command_success

# Memberikan izin untuk folder
echo -e "${CYAN}🔧  Memberikan izin pada direktori Multiple CLI...${RESET}"
chmod -R 777 multipleforlinux
check_command_success

# Menjalankan multiple-node
echo -e "${CYAN}🚀  Menjalankan Multiple Node...${RESET}"
nohup ./multiple-node > output.log 2>&1 &
check_command_success

# Meminta input dari pengguna untuk identifier dan PIN
echo -e "\n${CYAN}Masukkan Unique Account Identification Code:${RESET}"
read -p "Identifier: " USER_IDENTIFIER
echo -e "${CYAN}Masukkan PIN Code:${RESET}"
read -s -p "PIN Code: " USER_PIN
echo

# Memastikan bahwa input telah diisi
if [[ -z "$USER_IDENTIFIER" || -z "$USER_PIN" ]]; then
    echo -e "${RED}❌  Identifier dan PIN tidak boleh kosong.${RESET}"
    exit 1
fi

# Menjalankan `multiple-cli bind` dengan parameter pengguna
echo -e "\n${BLUE}🔗  Mengikat akun dengan Multiple CLI...${RESET}"
./multiple-cli bind \
    --bandwidth-download 100 \
    --identifier "$USER_IDENTIFIER" \
    --pin "$USER_PIN" \
    --storage 200 \
    --bandwidth-upload 100
check_command_success

echo -e "\n${LIGHT_GREEN}✅  Akun berhasil terikat dengan Multiple CLI!${RESET}"

# Menambahkan informasi untuk log dan dokumentasi
echo -e "\n${YELLOW}📋  Anda dapat memeriksa log node dengan perintah berikut:${RESET}"
echo -e "${WHITE}     tail -f output.log${RESET}"

echo -e "\n${CYAN}📢  Jangan lupa bergabung dengan channel Airdrop Node untuk update terbaru: ${WHITE}https://t.me/airdrop_node${RESET}\n"

# Selesai
echo -e "${LIGHT_GREEN}🎉  Proses Instalasi dan Konfigurasi Selesai!${RESET}"
