#!/bin/bash

# Perbarui Paket Sistem
echo "Memperbarui paket sistem..."
sudo apt-get update && sudo apt-get upgrade -y

# Pasang Utilitas dan Alat Umum
echo "Memasang utilitas dan alat umum..."
sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev

# Periksa dan Pasang Docker
if ! command -v docker &> /dev/null; then
    echo "Memasang Docker..."
    sudo apt-get install -y docker.io
    sudo usermod -aG docker $USER
else
    echo "Docker sudah terpasang"
fi

# Pasang Python
echo "Memasang Python..."
sudo apt-get install -y python3 python3-pip python3.10-venv

# Pasang Node.js
echo "Memasang Node.js..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g yarn

# Pasang Yarn
echo "Memasang Yarn..."
curl -o- -L https://yarnpkg.com/install.sh | sh
echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Kloning repositori dan siapkan
echo "Mengkloning repositori dan menyiapkan..."
git clone https://github.com/gensyn-ai/rl-swarm/
cd rl-swarm

# Buat sesi screen dan siapkan lingkungan virtual
echo "Membuat sesi screen dan menyiapkan lingkungan virtual..."
screen -dmS swarm
screen -S swarm -X stuff "python3 -m venv .venv\n"
screen -S swarm -X stuff "source .venv/bin/activate\n"
screen -S swarm -X stuff "./run_rl_swarm.sh\n"

echo "Pemasangan selesai!"
echo ""
echo "Langkah selanjutnya:"
echo "1. Tunggu pesan 'Waiting for userData.json to be created...' di log"
echo "2. Buka halaman login:"
echo "   - PC Lokal: http://localhost:3000/"
echo "   - VPS: http://ServerIP:3000/"
echo "3. Jika menggunakan VPS dan tidak bisa login, lakukan port forwarding melalui PowerShell:"
echo "   ssh -L 3000:localhost:3000 root@Server_IP -p SSH_PORT"
echo "4. Setelah login, masukkan token akses HuggingFace Anda saat diminta"
