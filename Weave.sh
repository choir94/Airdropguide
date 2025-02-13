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

# Fungsi: Memeriksa versi terbaru dari GitHub
get_latest_version() {
  echo -e "\n[2/6] Memeriksa versi terbaru dari Initia Weave...\n"
  LATEST_VERSION=$(curl -s https://api.github.com/repos/initia-labs/weave/releases/latest | jq -r '.tag_name')

  if [[ "$LATEST_VERSION" == "null" || -z "$LATEST_VERSION" ]]; then
    echo "Gagal mendapatkan versi terbaru, menggunakan versi default v0.1.4."
    LATEST_VERSION="v0.1.4"
  fi

  echo "Versi terbaru yang akan dipasang: $LATEST_VERSION"
}

# Fungsi: Memeriksa apakah Go sudah terinstal
check_go_installed() {
  if command -v go &> /dev/null; then
    echo -e "\n[3/6] Go sudah terinstal. Melewati instalasi Go...\n"
  else
    install_go
  fi
}

# Fungsi: Instal Go
install_go() {
  local GO_VERSION="1.23.0"
  echo -e "\n[3/6] Menginstal Go versi $GO_VERSION...\n"
  wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
  rm "go${GO_VERSION}.linux-amd64.tar.gz"

  # Konfigurasi PATH untuk Go
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
  mkdir -p ~/go/bin
}

# Fungsi: Clone dan instal Initia Weave versi terbaru
install_weave() {
  echo -e "\n[4/6] Mengunduh dan menginstal Initia Weave versi $LATEST_VERSION...\n"
  if [ -d "weave" ]; then
    rm -rf weave
  fi
  git clone https://github.com/initia-labs/weave.git
  cd weave
  git checkout tags/$LATEST_VERSION
  make install
  cd ..
}

# Fungsi: Membuat dompet
setup_wallet() {
  echo -e "\n[5/6] Membuat dompet baru dengan Initia Weave...\n"
  weave gas-station setup
  echo -e "\nSimpan kata-kata kunci (seed phrase) dengan aman."
  echo -e "Ketik 'lanjutkan' untuk melanjutkan setelah mencatat seed phrase.\n"
}

# Fungsi: Inisialisasi dan jalankan node
start_node() {
  echo -e "\n[6/6] Memulai inisialisasi Weave...\n"
  weave init
  echo -e "\nPilih L1 node yang sesuai.\n"

  echo -e "\n[6/6] Membuka sesi screen untuk menjalankan node Initia...\n"
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
  get_latest_version
  check_go_installed
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
