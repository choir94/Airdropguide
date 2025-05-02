#!/bin/bash

# Warna
NC='\033[0m'       # No Color
RED='\033[0;31m'    # Red
GREEN='\033[0;32m'  # Green
YELLOW='\033[0;33m' # Yellow
BLUE='\033[0;34m'   # Blue
CYAN='\033[0;36m'   # Cyan
WHITE='\033[1;37m'  # White

# Fungsi untuk memperbarui daftar paket APT sekali saja
function update_apt() {
  if [[ ! -f /tmp/apt_updated ]]; then
    echo -e "${YELLOW}Memperbarui daftar paket...${NC}"
    sudo apt-get update
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}Gagal memperbarui daftar paket APT.${NC}"
      exit 1
    fi
    touch /tmp/apt_updated
  fi
}

# Fungsi untuk memeriksa apakah Docker sudah terinstall
function check_docker() {
  echo -e "${BLUE}Cek apakah Docker sudah terinstall...${NC}"
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker tidak ditemukan, menginstall Docker...${NC}"
    install_docker
  else
    echo -e "${GREEN}Docker sudah terinstall.${NC}"
  fi
}

# Fungsi untuk menginstall dependensi yang diperlukan
function install_dependencies() {
  echo -e "${YELLOW}Menginstall dependensi...${NC}"
  update_apt
  sudo apt-get upgrade -y
  sudo apt-get install -y --no-install-recommends \
    curl iptables build-essential git wget lz4 jq make gcc nano \
    automake autoconf tmux htop nvme-cli libgbm1 pkg-config \
    libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Gagal menginstall dependensi.${NC}"
    exit 1
  fi
}

# Fungsi untuk menginstall Docker jika belum ada
function install_docker() {
  echo -e "${YELLOW}Menginstall Docker...${NC}"
  update_apt
  sudo apt-get upgrade -y
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null
  done

  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
    echo -e "${RED}Gagal mengunduh kunci GPG Docker.${NC}"
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
    echo -e "${RED}Gagal menjalankan tes Docker.${NC}"
    exit 1
  }
}

# Fungsi untuk menginstall Aztec tools
function install_aztec_tools() {
  echo -e "${CYAN}Menginstall Aztec tools...${NC}"
  bash -i <(curl -s https://install.aztec.network)
}

# Fungsi untuk update Aztec
function update_aztec() {
  echo -e "${CYAN}Mengupdate Aztec ke alpha-testnet...${NC}"
  aztec-up alpha-testnet
}

# Fungsi untuk menjalankan Sequencer Node
function start_sequencer_node() {
  echo -e "${GREEN}Menjalankan Sequencer Node...${NC}"
  echo -e "${BLUE}Panduan: RPC URL adalah endpoint L1, misalnya https://sepolia.infura.io/v3/YOUR_API_KEY${NC}"
  read -p "$(echo -e ${CYAN}Masukkan RPC URL:${NC} )" RPC_URL
  
  echo -e "${BLUE}Panduan: Beacon URL adalah endpoint untuk konsensus, misalnya http://beacon.aztec.network${NC}"
  read -p "$(echo -e ${CYAN}Masukkan BEACON URL:${NC} )" BEACON_URL
  
  echo -e "${BLUE}Panduan: Private Key adalah kunci heksadesimal 64 karakter dengan prefix 0x${NC}"
  read -s -p "$(echo -e ${CYAN}Masukkan Private Key (0xYourPrivateKey):${NC} )" PRIVATE_KEY
  echo
  
  echo -e "${BLUE}Panduan: Public Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x${NC}"
  read -p "$(echo -e ${CYAN}Masukkan Public Address (0xYourAddress):${NC} )" PUBLIC_ADDRESS
  
  echo -e "${BLUE}Panduan: Masukkan IP publik server Anda${NC}"
  read -p "$(echo -e ${CYAN}Masukkan IP Server:${NC} )" IP

  screen -S aztec
  aztec start --node --archiver --sequencer \
    --network alpha-testnet \
    --l1-rpc-urls "$RPC_URL" \
    --l1-consensus-host-urls "$BEACON_URL" \
    --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
    --sequencer.coinbase "$PUBLIC_ADDRESS" \
    --p2p.p2pIp "$IP"
}

# Fungsi untuk memeriksa sinkronisasi node
function check_sync() {
  echo -e "${YELLOW}Cek sinkronisasi node...${NC}"
  curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
  http://localhost:8080 | jq -r ".result.proven.number"
}

# Fungsi untuk klaim role di Discord
function claim_role() {
  echo -e "${GREEN}Mengklaim role di Discord...${NC}"
  echo -e "${BLUE}Panduan: Validator Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x${NC}"
  read -p "$(echo -e ${CYAN}Masukkan validator address:${NC} )" VALIDATOR_ADDRESS
  echo -e "${BLUE}Panduan: Block Number adalah nomor blok L2 dari cek sinkronisasi${NC}"
  read -p "$(echo -e ${CYAN}Masukkan block number:${NC} )" BLOCK_NUMBER
  echo -e "${BLUE}Panduan: Sync Proof adalah bukti sinkronisasi dari node Anda${NC}"
  read -p "$(echo -e ${CYAN}Masukkan sync proof:${NC} )" SYNC_PROOF

  curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"operator_start","params":["'$VALIDATOR_ADDRESS'", "'$BLOCK_NUMBER'", "'$SYNC_PROOF'"],"id":67}' \
  http://localhost:8080
}

# Fungsi untuk register validator
function register_validator() {
  echo -e "${YELLOW}Mendaftarkan validator...${NC}"
  echo -e "${BLUE}Panduan: RPC URL adalah endpoint L1, misalnya https://sepolia.infura.io/v3/YOUR_API_KEY${NC}"
  read -p "$(echo -e ${CYAN}Masukkan RPC URL:${NC} )" RPC_URL
  
  echo -e "${BLUE}Panduan: Validator Address adalah alamat Ethereum Anda, 42 karakter dengan prefix 0x${NC}"
  read -p "$(echo -e ${CYAN}Masukkan Validator Address:${NC} )" VALIDATOR_ADDRESS
  
  echo -e "${BLUE}Panduan: Private Key adalah kunci heksadesimal 64 karakter dengan prefix 0x${NC}"
  read -s -p "$(echo -e ${CYAN}Masukkan Private Key:${NC} )" PRIVATE_KEY
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
    echo -e "${GREEN}=========== AZTEC SEQUENCER SETUP BY AIRDROP NODE ===========${NC}"
    echo -e "${WHITE}Skrip ini dibuat oleh t.me/airdrop_node untuk mempermudah setup node Aztec.${NC}"
    echo -e "${BLUE}Dokumentasi resmi: https://docs.aztec.network${NC}"
    echo -e "${YELLOW}1. Install Aztec (Full Setup)${NC} - Install dependensi, tools, update, dan jalankan sequencer."
    echo -e "${YELLOW}2. Cek Sinkronisasi${NC} - Periksa status sinkronisasi node dengan RPC."
    echo -e "${YELLOW}3. Klaim Role Discord${NC} - Klaim role di Discord untuk validator."
    echo -e "${YELLOW}4. Register Validator${NC} - Daftarkan validator baru di jaringan Aztec."
    echo -e "${RED}0. Keluar${NC} - Hentikan skrip."
    echo -e "${GREEN}===========================================================${NC}"
    read -p "$(echo -e ${CYAN}Pilih opsi [0-4]:${NC} )" choice
    case $choice in
      1) 
        install_dependencies
        check_docker
        install_aztec_tools
        update_aztec
        start_sequencer_node
        read -p "$(echo -e ${CYAN}Tekan Enter untuk kembali ke menu...${NC})"
        ;;
      2) 
        check_sync
        read -p "$(echo -e ${CYAN}Tekan Enter untuk kembali ke menu...${NC})"
        ;;
      3) 
        claim_role
        read -p "$(echo -e ${CYAN}Tekan Enter untuk kembali ke menu...${NC})"
        ;;
      4) 
        register_validator
        read -p "$(echo -e ${CYAN}Tekan Enter untuk kembali ke menu...${NC})"
        ;;
      0) 
        echo -e "${GREEN}Keluar dari skrip. Terima kasih!${NC}"
        exit 0
        ;;
      *) 
        echo -e "${RED}Pilihan tidak valid. Silakan pilih 0-4.${NC}"
        sleep 2
        ;;
    esac
  done
}

# Menjalankan menu utama
main_menu
