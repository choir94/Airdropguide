#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

echo "==============================================="
echo "        🔹 Menghentikan Layanan DCDND 🔹       "
echo "==============================================="
systemctl stop dcdnd && systemctl disable dcdnd
echo "✅ Layanan DCDND berhasil dihentikan."
echo

echo "==============================================="
echo "     📁 Membuat Folder Konfigurasi Node 📁     "
echo "==============================================="
mkdir -p $HOME/pipenetwork-v2
echo "✅ Folder '$HOME/pipenetwork-v2' telah dibuat."
echo

echo "==============================================="
echo "  🔗 Masukkan Link Unduhan Binary v2 (HTTPS)  "
echo "==============================================="
read -r binary_url

if [[ $binary_url == https* ]]; then
    echo
    echo "📥 Mengunduh file binary..."
    wget -O $HOME/pipenetwork-v2/pop "$binary_url"
    chmod +x $HOME/pipenetwork-v2/pop
    echo "✅ Binary berhasil diunduh dan diberikan izin eksekusi."
else
    echo "❌ URL tidak valid. Pastikan link dimulai dengan 'https'."
    exit 1
fi
echo

echo "==============================================="
echo "       💾 Konfigurasi Sumber Daya Node        "
echo "==============================================="
read -p "🔹 Masukkan jumlah RAM yang akan dibagikan (Minimal 4GB): " RAM
if [ "$RAM" -lt 4 ]; then
  echo "❌ RAM harus minimal 4GB. Keluar..."
  exit 1
fi

read -p "🔹 Masukkan kapasitas maksimal penyimpanan (Minimal 100GB): " DISK
if [ "$DISK" -lt 100 ]; then
  echo "❌ Penyimpanan harus minimal 100GB. Keluar..."
  exit 1
fi

read -p "🔹 Masukkan Public Key Anda: " PUBKEY
echo

echo "==============================================="
echo "      ⚙️  Membuat Layanan Systemd Node       "
echo "==============================================="
SERVICE_FILE="/etc/systemd/system/pipe.service"

cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$HOME/pipenetwork-v2/pop \
    --ram=$RAM \
    --pubKey $PUBKEY \
    --max-disk $DISK \
    --cache-dir $HOME/pipenetwork-v2/download_cache \
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$HOME/pipenetwork-v2

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Layanan systemd berhasil dibuat: $SERVICE_FILE"
echo

echo "==============================================="
echo "  🔄 Memulai dan Mengaktifkan Layanan Node    "
echo "==============================================="
sudo systemctl daemon-reload
sudo systemctl enable pipe
sudo systemctl restart pipe
echo "✅ Layanan pipe telah dimulai."
echo

echo "==============================================="
echo "     📜 Menampilkan Log Layanan Secara Live   "
echo "==============================================="
journalctl -u pipe -fo cat
