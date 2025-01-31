#!/bin/bash

# =====================================================
# 🚀 Script Otomatis Instalasi Media Node Huddle01
# ✨ Dibuat oleh: Airdrop Node
# 📢 Telegram: https://t.me/airdrop_node
# =====================================================

# 🎨 Warna teks
MERAH='\033[1;31m'
HIJAU='\033[1;32m'
KUNING='\033[1;33m'
BIRU='\033[1;34m'
NC='\033[0m' # No Color

clear
echo -e "${BIRU}"
echo "====================================================="
echo "      🚀 INSTALASI MEDIA NODE HUDDLE01 🚀"
echo "           Dibuat oleh: Airdrop Node"
echo "       📢 Telegram: https://t.me/airdrop_node"
echo "====================================================="
echo -e "${NC}"
sleep 2

echo -e "${HIJAU}✅ Memeriksa dan memperbarui sistem...${NC}"
sudo apt update && sudo apt upgrade -y

# ✅ Cek dan instal FFmpeg jika belum ada
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${KUNING}⚡ FFmpeg tidak ditemukan, menginstal sekarang...${NC}"
    sudo apt install ffmpeg -y
    sleep 1
else
    echo -e "${HIJAU}✅ FFmpeg sudah terinstal.${NC}"
fi

# 🔍 Verifikasi instalasi FFmpeg
echo -e "${HIJAU}🔍 Verifikasi FFmpeg...${NC}"
ffmpeg -version | head -n 1
sleep 2

# ✅ Instalasi Media Node CLI
echo -e "${HIJAU}✅ Menginstal Media Node CLI...${NC}"
sudo apt install curl screen -y
curl -fsSL https://huddle01.network/api/install.sh | bash
sleep 1

# Menambahkan path ke .bashrc
echo 'export PATH=$PATH:/root/.hudl' >> ~/.bashrc
source ~/.bashrc

# Memuat ulang .bashrc agar perubahan path diterapkan
echo -e "${HIJAU}🔄 Memuat ulang konfigurasi shell...${NC}"
source ~/.bashrc
sleep 2

# ✅ Verifikasi instalasi
if ! command -v hudl &> /dev/null; then
    echo -e "${MERAH}❌ Instalasi Media Node CLI gagal! Silakan coba lagi.${NC}"
    exit 1
fi

echo -e "${HIJAU}🎉 Media Node CLI berhasil diinstal!${NC}"
sleep 1

# 🔑 Konfigurasi Wallet
echo -e "${KUNING}⚡ Membuat Burner Wallet...${NC}"
hudl wallet configure
sleep 2

echo -e "${MERAH}=====================================================${NC}"
echo -e "${MERAH}⚠️  PENTING! HARAP SIMPAN PRIVATE KEY ANDA!${NC}"
echo -e "${MERAH}=====================================================${NC}"
echo -e "1️⃣  Salin dan simpan PRIVATE KEY Anda dengan aman!"
echo -e "2️⃣  Buka tautan berikut dan buat Pool:"
echo -e "    🔗 ${HIJAU}https://www.huddle01.network/pools${NC}"
echo -e "3️⃣  Setelah membuat Pool, kembali ke terminal ini."
echo -e "${MERAH}=====================================================${NC}"
echo ""
sleep 2

# ⏳ Meminta konfirmasi sebelum melanjutkan
while true; do
    read -p "✅ Apakah Anda sudah menyimpan Private Key dan membuat Pool? (y/n): " pilihan
    case "$pilihan" in
        [Yy]* ) break;;
        [Nn]* ) echo -e "${KUNING}⏳ Silakan selesaikan pembuatan Pool sebelum melanjutkan.${NC}";;
        * ) echo "⚠️ Masukkan 'y' untuk melanjutkan atau 'n' untuk menunggu.";;
    esac
done

# ✅ Verifikasi wallet
echo -e "${HIJAU}🔍 Memeriksa konfigurasi Wallet...${NC}"
hudl wallet show
sleep 1

# 🚀 Menjalankan node menggunakan screen
echo -e "${HIJAU}🛠️  Menjalankan Media Node...${NC}"
screen -dmS media-node hudl node start -d
sleep 5

# 🔄 Konfirmasi bahwa node berjalan
if screen -list | grep -q "media-node"; then
    echo -e "${HIJAU}🎯 Media Node berhasil dijalankan di latar belakang.${NC}"
    echo -e "📜 Untuk melihat log, jalankan perintah: ${HIJAU}screen -r media-node${NC}"
else
    echo -e "${MERAH}❌ Gagal menjalankan Media Node. Silakan periksa secara manual.${NC}"
fi

echo ""
echo -e "${BIRU}=====================================================${NC}"
echo -e "🎉 Instalasi selesai! Media Node Anda sudah berjalan."
echo -e "📢 Bergabung dengan komunitas: ${HIJAU}https://t.me/airdrop_node${NC}"
echo -e "${BIRU}=====================================================${NC}"
