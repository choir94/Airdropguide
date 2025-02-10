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
    sudo apt update -y && sudo apt upgrade -y || { echo "Gagal memperbarui paket. Keluar..."; exit 1; }

    # Hapus paket yang konflik
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || echo "Gagal menghapus $pkg, mungkin tidak terinstal."
    done

    # Instal dependensi yang diperlukan
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Gagal menginstal dependensi. Keluar..."; exit 1; }

    # Tambahkan kunci GPG resmi Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || { echo "Gagal menambahkan kunci GPG Docker. Keluar..."; exit 1; }

    # Siapkan repositori stabil Docker
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || { echo "Gagal menambahkan repositori Docker. Keluar..."; exit 1; }

    # Instal Docker
    sudo apt update -y && sudo apt install -y docker-ce || { echo "Gagal menginstal Docker. Keluar..."; exit 1; }

    # Mulai dan aktifkan layanan Docker
    sudo systemctl start docker || { echo "Gagal memulai layanan Docker. Keluar..."; exit 1; }
    sudo systemctl enable docker || { echo "Gagal mengaktifkan layanan Docker. Keluar..."; exit 1; }

    echo "Docker berhasil diinstal."
}

# Fungsi untuk memeriksa dan menginstal Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { echo "Gagal mengunduh Docker Compose. Keluar..."; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose berhasil diinstal."
    else
        echo "Docker Compose sudah terinstal."
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

# Periksa dan instal Docker Compose
install_docker_compose

# Dapatkan zona waktu server
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    read -p "Masukkan zona waktu Anda (default: Asia/Jakarta): " user_timezone
    TIMEZONE=${user_timezone:-Asia/Jakarta}
fi
echo "Zona waktu server terdeteksi: $TIMEZONE"

# Unduh file dari https://dl.datsproject.io/evm-linux-deb
echo "Mengunduh file evm-linux-deb..."
wget -O evm-linux-deb https://dl.datsproject.io/evm-linux-deb || { echo "Gagal mengunduh file. Keluar..."; exit 1; }

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
    command: /bin/bash -c "wget -O /config/evm-linux-deb https://dl.datsproject.io/evm-linux-deb && chmod +x /config/evm-linux-deb && /config/evm-linux-deb"
EOF

# Verifikasi bahwa docker-compose.yaml telah dibuat dengan sukses
if [ ! -f "docker-compose.yaml" ]; then
    echo "Gagal membuat docker-compose.yaml. Keluar..."
    exit 1
fi

# Jalankan kontainer Chromium
echo "Menjalankan kontainer Chromium..."
docker-compose up -d || { echo "Gagal menjalankan kontainer Docker. Keluar..."; exit 1; }

# Dapatkan alamat IP VPS
IPVPS=$(curl -s ifconfig.me)

# Output informasi akses
echo "Akses Chromium di browser Anda di: http://$IPVPS:3010/ atau https://$IPVPS:3011/"
echo "Harap simpan data Anda, atau Anda akan kehilangan akses!"

# Bersihkan sumber daya Docker yang tidak terpakai
docker system prune -f
echo "Sistem Docker dibersihkan."
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
