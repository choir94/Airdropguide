#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna
NC='\033[0m'  # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'

echo -e "\n${CYAN}${BOLD}Mempersiapkan sistem...${NC}\n"

echo -e "${YELLOW}Menonaktifkan layanan DCDND...${NC}"
systemctl stop dcdnd && systemctl disable dcdnd

echo -e "\n${BLUE}Membuat folder di $HOME/pipe-devnet2...${NC}"
mkdir -p $HOME/pipe-devnet2

echo -e "${GREEN}Mengunduh file program pop...${NC}"
wget -O $HOME/pipe-devnet2/pop https://dl.pipecdn.app/v0.2.0/pop
chmod +x $HOME/pipe-devnet2/pop

echo -e "\n${CYAN}Berapa jumlah RAM yang ingin dibagikan? (minimal 4GB): ${NC}"
read -p "RAM: " RAM
if [ "$RAM" -lt 4 ]; then
  echo -e "${RED}RAM harus minimal 4GB. Proses dibatalkan.${NC}"
  exit 1
fi

echo -e "\n${CYAN}Berapa besar ruang disk yang ingin digunakan? (minimal 100GB): ${NC}"
read -p "Disk: " DISK
if [ "$DISK" -lt 100 ]; then
  echo -e "${RED}Ruang disk harus minimal 100GB. Proses dibatalkan.${NC}"
  exit 1
fi

echo -e "\n${CYAN}Masukkan kunci publik Anda: ${NC}"
read -p "Kunci Publik: " PUBKEY

SERVICE_FILE="/etc/systemd/system/pipe-devnet2.service"
echo -e "\n${BLUE}Membuat file layanan di $SERVICE_FILE...${NC}"

cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Layanan Pipe POP untuk Devnet2
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pipe-devnet2/pop \
    --ram=$RAM \
    --pubKey $PUBKEY \
    --max-disk $DISK \
    --cache-dir $HOME/pipe-devnet2/download_cache
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$HOME/pipe-devnet2

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n${GREEN}Memuat ulang konfigurasi systemd dan memulai layanan Pipe...${NC}"
sudo systemctl daemon-reload && \
sudo systemctl enable pipe-devnet2 && \
sudo systemctl restart pipe-devnet2 && \
journalctl -u pipe-devnet2 -fo cat

echo -e "\n${CYAN}${BOLD}Proses selesai! Layanan Pipe Devnet2 sekarang aktif.${NC}"
