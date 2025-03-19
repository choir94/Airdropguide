#!/bin/bash

set -e  # Stop jika ada error

# Menampilkan logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

echo -e "\n🔹 \e[1;36mLayer Edge Light Node Installer\e[0m 🔹\n"

# Meminta Private Key secara interaktif
while true; do
    read -s -p "🔑 Masukkan Private Key Anda: " PRIVATE_KEY
    echo
    read -s -p "🔑 Konfirmasi Private Key: " PRIVATE_KEY_CONFIRM
    echo
    if [ "$PRIVATE_KEY" == "$PRIVATE_KEY_CONFIRM" ]; then
        echo -e "\n✅ \e[1;32mPrivate Key berhasil disimpan!\e[0m"
        break
    else
        echo -e "\n❌ \e[1;31mPrivate Key tidak cocok! Coba lagi.\e[0m"
    fi
done

echo -e "\n🔹 \e[1;34mMemeriksa dan menginstal dependencies...\e[0m\n"

# Update dan install paket dasar
apt update && apt install -y curl git screen jq

# Instal Go jika belum ada
if ! command -v go &> /dev/null; then
    echo -e "\n🔹 \e[1;33mMenginstal Go...\e[0m\n"
    curl -OL https://golang.org/dl/go1.18.10.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.18.10.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
fi

# Instal Rust jika belum ada
if ! command -v rustc &> /dev/null; then
    echo -e "\n🔹 \e[1;33mMenginstal Rust...\e[0m\n"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Instal RISC Zero Toolchain jika belum ada
if ! command -v rzup &> /dev/null; then
    echo -e "\n🔹 \e[1;33mMenginstal RISC Zero Toolchain...\e[0m\n"
    curl -L https://risczero.com/install | bash && rzup install || {
        echo -e "\n⚠️ Instalasi 'rzup' gagal, mencoba kembali...\n"
        source "$HOME/.bashrc"
        rzup install
    }
fi

# Konfigurasi Environment Variables
echo -e "\n🔹 \e[1;34mMengatur variabel lingkungan...\e[0m\n"
cat <<EOF > ~/.layeredge_env
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
export PRIVATE_KEY='$PRIVATE_KEY'
EOF
source ~/.layeredge_env

# Clone repositori jika belum ada
if [ ! -d "layer-edge-light-node" ]; then
    echo -e "\n🔹 \e[1;34mCloning Layer Edge Light Node repository...\e[0m\n"
    GIT_ASKPASS=/bin/echo git clone --depth=1 https://github.com/layeredge/light-node.git layer-edge-light-node
fi

if [ ! -d "risc0-merkle-service" ]; then
    echo -e "\n🔹 \e[1;34mCloning RISC0 Merkle Service repository...\e[0m\n"
    git clone --depth=1 https://github.com/risczero/merkle-service.git risc0-merkle-service
fi

# Build dan Jalankan RISC0 Merkle Service
echo -e "\n🔹 \e[1;34mMenjalankan Merkle Service...\e[0m\n"
screen -dmS risc0_merkle_service bash -c "cd risc0-merkle-service && cargo build && cargo run"

# Menunggu server RISC0 aktif
echo -e "\n⏳ \e[1;33mMenunggu RISC0 Merkle Service siap...\e[0m\n"
for i in {1..30}; do  # Cek maksimal 30 kali (sekitar 30 detik)
    if curl -s http://127.0.0.1:3001/health | jq .status | grep -q "ok"; then
        echo -e "\n✅ \e[1;32mRISC0 Merkle Service aktif!\e[0m\n"
        break
    fi
    sleep 1
done

# Jalankan Layer Edge Light Node hanya jika RISC0 aktif
if curl -s http://127.0.0.1:3001/health | jq .status | grep -q "ok"; then
    echo -e "\n🔹 \e[1;34mMenjalankan Light Node...\e[0m\n"
    screen -dmS layeredge_light_node bash -c "cd layer-edge-light-node && go build && ./light-node"
    echo -e "\n✅ \e[1;32mLayer Edge Light Node berjalan!\e[0m\n"
else
    echo -e "\n❌ \e[1;31mGagal menjalankan Layer Edge Light Node. RISC0 Merkle Service tidak aktif!\e[0m\n"
    exit 1
fi

# Menampilkan petunjuk monitoring
echo -e "\n✅ \e[1;32mSemua layanan sudah berjalan di dalam screen!\e[0m\n"
echo -e "Gunakan perintah berikut untuk melihat log:\n"
echo -e "  \e[1;33mscreen -r risc0_merkle_service\e[0m  # Untuk melihat Merkle Service"
echo -e "  \e[1;33mscreen -r layeredge_light_node\e[0m  # Untuk melihat Light Node"
