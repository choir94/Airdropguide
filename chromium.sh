#!/bin/bash

# Tampilkan logo (opsional)
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 2

# Cek root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: Skrip ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# Install Docker & Compose Plugin
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "INFO: Docker belum ditemukan. Menginstal..."

        apt update -y && apt upgrade -y

        # Hapus versi lama
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            apt-get remove -y $pkg || true
        done

        # Dependensi dasar
        apt-get install -y ca-certificates curl gnupg

        # Tambah GPG dan repositori Docker resmi
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt update -y && apt upgrade -y

        # Install Docker dan Plugin Compose
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Aktifkan layanan
        systemctl enable docker
        systemctl start docker

        echo "SUCCESS: Docker terinstal: $(docker --version)"
    else
        echo "SUCCESS: Docker tersedia: $(docker --version)"
    fi
}

# Cek Docker Compose Plugin
check_and_install_compose() {
    if ! docker compose version &> /dev/null; then
        echo "INFO: Docker Compose Plugin tidak ditemukan. Menginstal..."
        apt-get install -y docker-compose-plugin
        echo "SUCCESS: Docker Compose Plugin berhasil diinstal."
    else
        echo "SUCCESS: Docker Compose tersedia: $(docker compose version | head -n 1)"
    fi
}

# Jalankan pengecekan & instalasi
check_root
check_and_install_docker
check_and_install_compose

# Cek layanan aktif
if ! systemctl is-active --quiet docker; then
    echo "ERROR: Docker tidak aktif. Menyalakan..."
    systemctl restart docker || { echo "Gagal menjalankan Docker. Keluar..."; exit 1; }
fi

# Zona waktu otomatis
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    read -p "Masukkan zona waktu Anda (default: Asia/Jakarta): " user_timezone
    TIMEZONE=${user_timezone:-Asia/Jakarta}
fi
echo "INFO: Zona waktu server: $TIMEZONE"

# Input akun
read -p "INPUT: Masukkan nama pengguna untuk Chromium: " CUSTOM_USER
if [ -z "$CUSTOM_USER" ]; then echo "ERROR: Nama pengguna tidak boleh kosong."; exit 1; fi

read -p "INPUT: Masukkan kata sandi untuk Chromium: " PASSWORD
if [ -z "$PASSWORD" ]; then echo "ERROR: Kata sandi tidak boleh kosong."; exit 1; fi

# Buat folder dan file docker-compose
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:amd64-kasm
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
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Jalankan container
echo "INFO: Menjalankan Chromium container..."
docker compose up -d || { echo "ERROR: Gagal menjalankan container."; exit 1; }

# Info akses
IPVPS=$(curl -s ifconfig.me)
echo ""
echo "SUCCESS: Chromium siap digunakan!"
echo "URL: http://$IPVPS:3010 atau https://$IPVPS:3011"
echo "Username: $CUSTOM_USER"
echo "Password: $PASSWORD"
echo "WARNING: Simpan informasi ini baik-baik."

# Cleanup
docker system prune -f > /dev/null
echo "INFO: Sistem Docker dibersihkan."
echo -e "\nSUCCESS: Instalasi selesai!"
echo -e "COMMUNITY: Gabung komunitas: https://t.me/airdrop_node"
