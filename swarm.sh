#!/bin/bash

# Perbarui Paket Sistem
echo "Memperbarui paket sistem..."
sudo apt-get update && sudo apt-get upgrade -y

# Pasang Utilitas dan Alat Umum
echo "Memeriksa dan memasang utilitas dan alat umum..."
if ! dpkg -l | grep -q build-essential; then
    sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev
else
    echo "Utilitas dan alat umum sudah terpasang"
fi

# Periksa dan Pasang Docker
echo "Memeriksa Docker..."
if ! command -v docker &> /dev/null; then
    echo "Memasang Docker..."
    sudo apt-get install -y docker.io
    sudo usermod -aG docker $USER
else
    echo "Docker sudah terpasang"
fi

# Periksa dan Pasang Python
echo "Memeriksa Python..."
if ! command -v python3 &> /dev/null || ! command -v pip3 &> /dev/null; then
    echo "Memasang Python..."
    sudo apt-get install -y python3 python3-pip python3.10-venv
else
    echo "Python sudah terpasang"
fi

# Periksa dan Pasang Node.js
echo "Memeriksa Node.js..."
if ! command -v node &> /dev/null; then
    echo "Memasang Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js sudah terpasang"
fi

# Periksa dan Pasang Yarn secara global melalui npm
echo "Memeriksa Yarn..."
if ! command -v yarn &> /dev/null; then
    echo "Memasang Yarn melalui npm..."
    sudo npm install -g yarn
else
    echo "Yarn sudah terpasang"
fi

# Periksa dan Pasang Yarn melalui script resmi (opsional, hanya jika belum ada)
if ! command -v yarn &> /dev/null; then
    echo "Memasang Yarn melalui script resmi..."
    curl -o- -L https://yarnpkg.com/install.sh | sh
    echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi

# Periksa dan Kloning repositori
echo "Memeriksa repositori rl-swarm..."
if [ ! -d "rl-swarm" ]; then
    echo "Mengkloning repositori dan menyiapkan..."
    git clone https://github.com/gensyn-ai/rl-swarm/
    cd rl-swarm
else
    echo "Repositori rl-swarm sudah ada"
    cd rl-swarm
fi

# Periksa dan Buat sesi screen serta siapkan lingkungan virtual
echo "Memeriksa dan membuat sesi screen..."
if ! screen -list | grep -q "swarm"; then
    echo "Membuat sesi screen dan menyiapkan lingkungan virtual..."
    screen -dmS swarm
    screen -S swarm -X stuff "python3 -m venv .venv\n"
    screen -S swarm -X stuff "source .venv/bin/activate\n"
    screen -S swarm -X stuff "./run_rl_swarm.sh\n"
else
    echo "Sesi screen 'swarm' sudah berjalan"
fi
