#!/bin/bash

# Hentikan eksekusi jika terjadi error
set -e

# Fungsi: Menampilkan header
print_header() {
  echo -e "\n============================================================"
  echo -e "               AUTO UPDATE INITIA WEAVE                     "
  echo -e "============================================================\n"
}

# Fungsi: Menghentikan node yang sedang berjalan
stop_node() {
  echo -e "\n[1/5] Menghentikan node Initia Weave...\n"
  screen -S initia -X quit || true
}

# Fungsi: Memeriksa versi terbaru dari GitHub
get_latest_version() {
  echo -e "\n[2/5] Memeriksa versi terbaru dari Initia Weave...\n"
  LATEST_VERSION=$(curl -s https://api.github.com/repos/initia-labs/weave/releases/latest | jq -r '.tag_name')
  echo "Versi terbaru: $LATEST_VERSION"
}

# Fungsi: Memperbarui dan menginstal dependensi
update_dependencies() {
  echo -e "\n[3/5] Memperbarui sistem dan dependensi...\n"
  sudo apt update -y && sudo apt upgrade -y
}

# Fungsi: Mengunduh dan menginstal versi terbaru Initia Weave
install_weave() {
  echo -e "\n[4/5] Menginstal versi terbaru Initia Weave...\n"

  # Hapus versi lama
  rm -rf weave

  # Clone dan install versi terbaru
  git clone https://github.com/initia-labs/weave.git
  cd weave
  git checkout tags/$LATEST_VERSION
  make install
  cd ..
}

# Fungsi: Memulai ulang node
start_node() {
  echo -e "\n[5/5] Memulai ulang node Initia Weave...\n"
  screen -S initia -dm bash -c "weave initia start"
  echo -e "Node sedang berjalan di sesi screen bernama 'initia'.\n"
}

# Fungsi utama
main() {
  print_header
  stop_node
  get_latest_version
  update_dependencies
  install_weave
  start_node

  echo -e "\n============================================================"
  echo -e "            AUTO UPDATE INITIA WEAVE SELESAI!               "
  echo -e "============================================================\n"
}

# Jalankan fungsi utama
main
