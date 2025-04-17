#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Fungsi untuk memeriksa apakah skrip dijalankan sebagai root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Skrip ini harus dijalankan sebagai root. Keluar..."
        exit 1
    fi
}

# Fungsi untuk memeriksa dan menginstal Docker
install_docker() {
    echo "Menginstal Docker..."
    apt-get update -y && apt-get upgrade -y || { echo "Gagal memperbarui paket. Keluar..."; exit 1; }

    # Hapus paket yang konflik
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        apt-get remove -y $pkg || echo "Gagal menghapus $pkg, mungkin tidak terinstal."
    done

    # Instal dependensi yang diperlukan
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release || { echo "Gagal menginstal dependensi. Keluar..."; exit 1; }

    # Tambahkan kunci GPG resmi Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || { echo "Gagal menambahkan kunci GPG Docker. Keluar..."; exit 1; }
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Siapkan repositori stabil Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Gagal menambahkan repositori Docker. Keluar..."; exit 1; }

    # Instal Docker
    apt-get update -y && apt-get install -y docker-ce docker-ce-cli containerd.io || { echo "Gagal menginstal Docker. Keluar..."; exit 1; }

    # Mulai dan aktifkan layanan Docker
    systemctl start docker || { echo "Gagal memulai layanan Docker. Keluar..."; exit 1; }
    systemctl enable docker || { echo "Gagal mengaktifkan layanan Docker. Keluar..."; exit 1; }

    echo "Docker berhasil diinstal."
}

# Fungsi untuk memeriksa dan menginstal Docker Compose Plugin
install_docker_compose() {
    if ! command -v docker compose &> /dev/null; then
        echo "Menginstal Docker Compose Plugin..."
        apt-get update -y
        apt-get install -y docker-compose-plugin || { echo "Gagal menginstal Docker Compose Plugin. Keluar..."; exit 1; }
        echo "Docker Compose Plugin berhasil diinstal."
    else
        echo "Docker Compose Plugin sudah terinstal."
    fi
}

# Periksa apakah skrip dijalankan sebagai root
check_root

# Periksa dan instal Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker sudah terinstal."
fi

# Periksa dan instal Docker Compose Plugin
install_docker_compose

# Verifikasi Docker dan Docker Compose
docker --version || { echo "Docker tidak berfungsi dengan benar. Keluar..."; exit 1; }
docker compose version || { echo "Docker Compose tidak berfungsi dengan benar. Keluar..."; exit 1; }

# Dapatkan zona waktu server
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    read -p "Masukkan zona waktu Anda (default: Asia/Jakarta): " user_timezone
    TIMEZONE=${user_timezone:-Asia/Jakarta}
fi
echo "Zona waktu server terdeteksi: $TIMEZONE"

# Minta input nama pengguna dan kata sandi dari pengguna
read -p "Masukkan nama pengguna untuk Chromium: " CUSTOM_USER
if [ -z "$CUSTOM_USER" ]; then
    echo "Nama pengguna tidak boleh kosong. Keluar..."
    exit 1
fi
read -p "Masukkan kata sandi untuk Chromium: " PASSWORD
if [ -z "$PASSWORD" ]; then
    echo "Kata sandi tidak boleh kosong. Keluar..."
    exit 1
fi
echo "Nama pengguna yang dipilih: $CUSTOM_USER"
echo "Kata sandi yang dipilih: $PASSWORD"

# Siapkan Chromium dengan Docker Compose
echo "Menyiapkan Chromium dengan Docker Compose..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Verifikasi bahwa docker-compose.yaml telah dibuat dengan sukses
if [ ! -f "docker-compose.yaml" ]; then
    echo "Gagal membuat docker-compose.yaml. Keluar..."
    exit 1
fi

# Jalankan kontainer Chromium
echo "Menjalankan kontainer Chromium..."
docker compose up -d || { echo "Gagal menjalankan kontainer Docker. Keluar..."; exit 1; }

# Dapatkan alamat IP VPS
IPVPS=$(curl -s ifconfig.me)

# Output informasi akses
echo "Akses Chromium di browser Anda di: http://$IPVPS:3010/ atau https://$IPVPS:3011/"
echo "Nama pengguna: $CUSTOM_USER"
echo "Kata sandi: $PASSWORD"
echo "Harap simpan data Anda, atau Anda akan kehilangan akses!"

# Bersihkan sumber daya Docker yang tidak terpakai
docker system prune -f
echo "Sistem Docker dibersihkan."
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
