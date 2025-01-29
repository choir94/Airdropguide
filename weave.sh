#!/bin/bash

# Hentikan eksekusi jika ada error
set -e

# Fungsi: Menampilkan header
print_header() {
  echo -e "\n============================================================"
  echo -e "                   INSTALLASI INITIA WEAVE                  "
  echo -e "============================================================\n"
}

# Fungsi: Perbarui dan instal dependensi
install_dependencies() {
  echo -e "\n[1/6] Memperbarui sistem dan menginstal dependensi...\n"
  sudo apt update -y && sudo apt upgrade -y
  sudo apt install -y htop ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
  tmux iptables curl nvme-cli git wget make jq libleveldb-dev build-essential pkg-config \
  ncdu tar clang bsdmainutils lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4
}

# Fungsi: Clone dan instal Initia Weave
install_weave() {
  echo -e "\n[2/6] Mengunduh dan menginstal Initia Weave...\n"
  git clone https://github.com/initia-labs/weave.git
  cd weave

  # Pastikan mendapatkan semua tag terbaru
  git fetch --all --tags
  
  # Cek apakah v0.1.2 tersedia
  if git tag | grep -q "v0.1.2"; then
    echo -e "\nMenggunakan versi v0.1.2...\n"
    git checkout tags/v0.1.2
  else
    echo -e "\nVersi v0.1.2 tidak ditemukan, menggunakan branch main...\n"
    git checkout main
  fi

  make install
  cd ..
}

# Fungsi: Membuat dompet
setup_wallet() {
  echo -e "\n[3/6] Membuat dompet baru dengan Initia Weave...\n"
  weave gas-station setup
  echo -e "\nSimpan kata-kata kunci (seed phrase) dengan aman."
  echo -e "Ketik 'lanjutkan' untuk melanjutkan setelah mencatat seed phrase.\n"
}

# Fungsi: Inisialisasi dan jalankan node
start_node() {
  echo -e "\n[4/6] Memulai inisialisasi Weave...\n"
  weave init
  echo -e "\nPilih L1 node yang sesuai.\n"

  echo -e "\n[5/6] Membuka sesi screen untuk menjalankan node Initia...\n"
  screen -S initia -dm bash -c "weave initia start"
  echo -e "Node sedang berjalan di sesi screen bernama 'initia'.\n"
}

# Fungsi: Menampilkan saldo dompet
show_balance() {
  echo -e "\nMenampilkan saldo dompet...\n"
  weave gas-station show
}

# Menu utama
main() {
  print_header
  install_dependencies
  install_weave
  setup_wallet
  show_balance
  start_node

  echo -e "\n============================================================"
  echo -e "           INSTALASI DAN KONFIGURASI INITIA WEAVE           "
  echo -e "                SELESAI DENGAN SUKSES!                     "
  echo -e "                  Script By Airdrop Node                   "
  echo -e "============================================================\n"
}

# Jalankan fungsi utama
main
