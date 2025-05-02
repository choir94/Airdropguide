#!/bin/bash

# Kode Warna
RESET="\033[0m"
BOLD="\033[1m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
LIGHT_GREEN="\033[1;32m"
LIGHT_CYAN="\033[1;36m"
LIGHT_YELLOW="\033[1;33m"

# Fungsi untuk update apt
function update_apt() {
  sudo apt-get update -y
}

# Fungsi untuk menginstall Docker jika belum ada
function install_docker() {
  echo -e "${CYAN}Menginstall Docker...${RESET}"
  update_apt
  sudo apt-get upgrade -y
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null
  done

  sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
    echo -e "${RED}Gagal mengunduh kunci GPG Docker.${RESET}"
    exit 1
  }
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  update_apt
  sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl restart docker
  echo -e "${LIGHT_GREEN}Docker berhasil diinstall.${RESET}"
}

# Fungsi untuk install Aztec Node
function install_aztec_node() {
  echo -e "${CYAN}Menginstall dependensi tambahan...${RESET}"
  update_apt
  sudo apt-get install -y curl screen net-tools psmisc jq

  if [ -d "$HOME/.aztec/alpha-testnet" ]; then
    echo -e "${YELLOW}Menghapus direktori lama ~/.aztec/alpha-testnet...${RESET}"
    rm -rf "$HOME/.aztec/alpha-testnet"
  fi

  mkdir -p ~/.aztec/bin
  curl -fsSL https://install.aztec.network | bash
  echo 'export PATH=$PATH:$HOME/.aztec/bin' >> ~/.bashrc
  source ~/.bashrc
  export PATH="$PATH:$HOME/.aztec/bin"

  aztec-up alpha-testnet

  IP=$(curl -s https://api.ipify.org)

  read -p "Enter Sepolia Ethereum RPC URL: " L1_RPC_URL
  read -p "Enter Sepolia BEACON URL: " L1_CONSENSUS_URL
  read -p "Enter Private Key (0x...): " VALIDATOR_PRIVATE_KEY
  read -p "Enter Wallet Address (0x...): " COINBASE_ADDRESS

  cat <<EOF > ~/start_aztec_node.sh
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --port 8080 \\
  --l1-rpc-urls $L1_RPC_URL \\
  --l1-consensus-host-urls $L1_CONSENSUS_URL \\
  --sequencer.validatorPrivateKey $VALIDATOR_PRIVATE_KEY \\
  --sequencer.coinbase $COINBASE_ADDRESS \\
  --p2p.p2pIp $IP \\
  --p2p.maxTxPoolSize 10000
EOF

  chmod +x ~/start_aztec_node.sh

  echo -e "${LIGHT_GREEN}Menjalankan Aztec Node dalam screen session 'aztec'...${RESET}"
  screen -dmS aztec bash -c "~/start_aztec_node.sh"

  echo -e "${GREEN}Selesai! Gunakan 'screen -r aztec' untuk melihat log node.${RESET}"
  read -p "Tekan Enter untuk kembali ke menu utama..."
  main_menu
}

function check_block_number() {
  echo -e "${CYAN}Memeriksa block number setelah sinkronisasi...${RESET}"
  curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'
  read -p "Tekan Enter untuk kembali ke menu utama..."
  main_menu
}

function check_archive_sibling_path() {
  read -p "Masukkan block number: " block_number
  curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["'"$block_number"'","'"$block_number"'"],"id":67}' http://localhost:8080 | jq -r ".result"
  read -p "Tekan Enter untuk kembali ke menu utama..."
  main_menu
}

function add_validator() {
  read -p "Masukkan RPC URL Sepolia: " SEPOLIA_RPC_URL
  read -p "Masukkan Private Key Anda (0x...): " PRIVATE_KEY
  read -p "Masukkan Alamat Attester (Validator Address): " VALIDATOR_ADDRESS
  aztec add-l1-validator \
    --l1-rpc-urls "$SEPOLIA_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --attester "$VALIDATOR_ADDRESS" \
    --proposer-eoa "$VALIDATOR_ADDRESS" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111
  read -p "Tekan Enter untuk kembali ke menu utama..."
  main_menu
}

function check_logs() {
  echo -e "${CYAN}Masuk ke screen untuk melihat log...${RESET}"
  screen -r aztec
  read -p "Tekan Enter untuk kembali ke menu utama..."
  main_menu
}

function main_menu() {
  clear
  echo -e "${LIGHT_CYAN}===============================${RESET}"
  echo -e "${BOLD}${LIGHT_GREEN}  Script by Airdrop Node${RESET}"
  echo -e "${LIGHT_CYAN}===============================${RESET}"
  PS3="Pilih menu: "
  options=("Install Aztec Node" "Cek Block Number" "Cek Archive Sibling Path" "Tambah Validator" "Masuk ke Screen untuk Cek Logs" "Keluar")
  select opt in "${options[@]}"
  do
      case $opt in
          "Install Aztec Node")
              install_docker
              install_aztec_node
              break
              ;;
          "Cek Block Number")
              check_block_number
              break
              ;;
          "Cek Archive Sibling Path")
              check_archive_sibling_path
              break
              ;;
          "Tambah Validator")
              add_validator
              break
              ;;
          "Masuk ke Screen untuk Cek Logs")
              check_logs
              break
              ;;
          "Keluar")
              echo -e "${RED}Keluar dari program.${RESET}"
              break
              ;;
          *)
              echo -e "${RED}Pilihan tidak valid!${RESET}"
              ;;
      esac
  done
}

main_menu
