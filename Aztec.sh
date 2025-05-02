#!/bin/bash

# Fungsi untuk memperbarui daftar paket APT sekali saja
function update_apt() {
  if [[ ! -f /tmp/apt_updated ]]; then
    echo "Memperbarui daftar paket..."
    sudo apt-get update
    if [[ $? -ne 0 ]]; then
      echo "Gagal memperbarui daftar paket APT."
      exit 1
    fi
    touch /tmp/apt_updated
  fi
}

# Fungsi untuk memeriksa apakah Docker sudah terinstall
function check_docker() {
  echo "Cek apakah Docker sudah terinstall..."
  if ! command -v docker &> /dev/null; then
    echo "Docker tidak ditemukan, menginstall Docker..."
    install_docker
  else
    echo "Docker sudah terinstall."
  fi
}

# Fungsi untuk menginstall dependensi yang diperlukan
function install_dependencies() {
  echo "Menginstall dependensi..."
  update_apt
  sudo apt-get upgrade -y
  sudo apt-get install -y --no-install-recommends \
    curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config \
    libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
  if [[ $? -ne 0 ]]; then
    echo "Gagal menginstall dependensi."
    exit 1
  fi
}

# Fungsi untuk menginstall Docker jika belum ada
function install_docker() {
  echo "Menginstall Docker..."
  update_apt
  sudo apt-get upgrade -y
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null
  done

  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
    echo "Gagal mengunduh kunci GPG Docker."
    exit 1
  }
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  update_apt
  sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl restart docker

  # Test Docker
  sudo docker run hello-world || {
    echo "Gagal menjalankan tes Docker."
    exit 1
  }
}

# Fungsi untuk menginstall Aztec tools
function install_aztec_tools() {
  echo "Menginstall Aztec tools..."
  bash -i <(curl -s https://install.aztec.network)
}

# Fungsi untuk update Aztec
function update_aztec() {
  echo "Mengupdate Aztec ke alpha-testnet..."
  aztec-up alpha-testnet
}

# Fungsi untuk menjalankan Sequencer Node
function start_sequencer_node() {
  echo "Menjalankan Sequencer Node..."
  echo "Panduan: RPC URL adalah endpoint L1, misalnya https://sepolia.infura.io/v3/YOUR_API_KEY"
  read -p "Masukkan RPC URL: " RPC_URL
  
  echo "Panduan: Beacon URL adalah endpoint untuk konsensus, misalnya http://beacon.aztec.network"
  read -p "Masukkan BEACON URL: " BEACON_URL
  
  echo "Panduan: Private Key adalah kunci heksadesimal 64 karakter dengan prefix 0x"
  read -s -p "Masukkan Private Key (0xYourPrivateKey): " PRIVATE_KEY
  echo
  
  echo "Panduan: Public Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x"
  read -p "Masukkan Public Address (0xYourAddress): " PUBLIC_ADDRESS
  
  echo "Panduan: Masukkan IP publik server Anda"
  read -p "Masukkan IP Server: " IP

  # Periksa apakah sesi screen 'aztec' sudah ada
  if screen -list | grep -q "aztec"; then
    echo "Sesi screen 'aztec' sudah ada."
    echo "Panduan: Gunakan 'screen -r aztec' untuk melihat sesi, atau hentikan sesi lama dengan 'screen -X -S aztec quit'."
    read -p "Hentikan sesi lama dan buat baru? [y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
      screen -X -S aztec quit
      echo "Sesi lama dihentikan."
    else
      echo "Dibatalkan. Silakan kelola sesi screen secara manual."
      return 1
    fi
  fi

  # Buat sesi screen baru di latar belakang
  echo "Membuat sesi screen baru bernama 'aztec' di latar belakang..."
  echo "Panduan: Gunakan 'screen -r aztec' untuk melihat sesi, atau pilih opsi 'Cek Sesi Screen' di menu utama."
  screen -S aztec -d -m bash -c "aztec start --node --archiver --sequencer \
    --network alpha-testnet \
    --l1-rpc-urls \"$RPC_URL\" \
    --l1-consensus-host-urls \"$BEACON_URL\" \
    --sequencer.validatorPrivateKey \"$PRIVATE_KEY\" \
    --sequencer.coinbase \"$PUBLIC_ADDRESS\" \
    --p2p.p2pIp \"$IP\"; exec bash"
  sleep 2
  if screen -list | grep -q "aztec"; then
    echo "Sesi screen 'aztec' berhasil dibuat dan node berjalan di latar belakang."
    echo "Kembali ke menu utama..."
  else
    echo "Gagal membuat sesi screen 'aztec'. Silakan periksa log atau coba lagi."
    return 1
  fi
}

# Fungsi untuk memeriksa sesi screen
function check_screen() {
  echo "Memeriksa sesi screen 'aztec'..."
  if screen -list | grep -q "aztec"; then
    echo "Sesi screen 'aztec' sedang berjalan."
    echo "Panduan: Gunakan 'screen -r aztec' untuk melihat sesi, atau 'screen -X -S aztec quit' untuk menghentikan."
    read -p "Apakah Anda ingin menghentikan sesi screen 'aztec'? [y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
      screen -X -S aztec quit
      echo "Sesi screen 'aztec' telah dihentikan."
    else
      echo "Sesi screen tetap berjalan."
    fi
  else
    echo "Tidak ada sesi screen 'aztec' yang berjalan."
    echo "Panduan: Jalankan opsi 'Install Aztec (Full Setup)' untuk memulai node."
  fi
}

# Fungsi untuk memeriksa sinkronisasi node
function check_sync() {
  echo "Cek sinkronisasi node..."
  curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
  http://localhost:8080 | jq -r ".result.proven.number"
}

# Fungsi untuk klaim role di Discord
function claim_role() {
  echo "Mengklaim role di Discord..."
  echo "Panduan: Validator Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x"
  read -p "Masukkan validator address: " VALIDATOR_ADDRESS
  echo "Panduan: Block Number adalah nomor blok L2 dari cek sinkronisasi"
  read -p "Masukkan block number: " BLOCK_NUMBER
  echo "Panduan: Sync Proof adalah bukti sinkronisasi dari node Anda"
  read -p "Masukkan sync proof: " SYNC_PROOF

  curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"operator_start","params":["'$VALIDATOR_ADDRESS'", "'$BLOCK_NUMBER'", "'$SYNC_PROOF'"],"id":67}' \
  http://localhost:8080
}

# Fungsi untuk register validator
function register_validator() {
  echo "Mendaftarkan validator..."
  echo "Panduan: RPC URL adalah endpoint L1, misalnya https://sepolia.infura.io/v3/YOUR_API_KEY"
  read -p "Masukkan RPC URL: " RPC_URL
  
  echo "Panduan: Validator Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x"
  read -p "Masukkan Validator Address: " VALIDATOR_ADDRESS
  
  echo "Panduan: Private Key adalah kunci heksadesimal 64 karakter dengan prefix 0x"
  read -s -p "Masukkan Private Key: " PRIVATE_KEY
  echo

  aztec add-l1-validator \
    --l1-rpc-urls "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --attester "$VALIDATOR_ADDRESS" \
    --proposer-eoa "$VALIDATOR_ADDRESS" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111
}

# Fungsi untuk menampilkan menu utama
function main_menu() {
  while true; do
    clear
    echo "=========== AZTEC SEQUENCER SETUP BY AIRDROP NODE ==========="
    echo "Skrip ini dibuat oleh t.me/airdrop_node untuk mempermudah setup node Aztec."
    echo "Dokumentasi resmi: https://docs.aztec.network"
    echo "1. Install Aztec (Full Setup) - Install dependensi, tools, update, dan jalankan sequencer."
    echo "2. Cek Sinkronisasi - Periksa status sinkronisasi node dengan RPC."
    echo "3. Klaim Role Discord - Klaim role di Discord untuk validator."
    echo "4. Register Validator - Daftarkan validator baru di jaringan Aztec."
    echo "5. Cek Sesi Screen - Periksa status sesi screen 'aztec'."
    echo "0. Keluar - Hentikan skrip."
    echo "==========================================================="
    read -p "Pilih opsi [0-5]: " choice
    case $choice in
      1) 
        install_dependencies
        check_docker
        install_aztec_tools
        update_aztec
        start_sequencer_node
        read -p "Tekan Enter untuk kembali ke menu..."
        ;;
      2) 
        check_sync
        read -p "Tekan Enter untuk kembali ke menu..."
        ;;
      3) 
        claim_role
        read -p "Tekan Enter untuk kembali ke menu..."
        ;;
      4) 
        register_validator
        read -p "Tekan Enter untuk kembali ke menu..."
        ;;
      5) 
        check_screen
        read -p "Tekan Enter untuk kembali ke menu..."
        ;;
      0) 
        echo "Keluar dari skrip. Terima kasih!"
        exit 0
        ;;
      *) 
        echo "Pilihan tidak valid. Silakan pilih 0-5."
        sleep 2
        ;;
    esac
  done
}

# Menjalankan menu utama
main_menu
