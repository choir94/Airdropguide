#!/bin/bash
# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Fungsi untuk menampilkan pesan
function echo_msg() {
    echo -e "\n>>> $1\n"
}

# Memeriksa apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo_msg "Docker tidak ditemukan, menginstal Docker..."
    sudo apt update && sudo apt install -y docker.io docker-compose jq sed
    # Memulai Docker daemon
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo_msg "Docker sudah terinstal, melewati instalasi Docker."
fi

# Menambahkan user ke grup Docker
echo_msg "Menambahkan user ke grup Docker..."
sudo usermod -aG docker $USER
newgrp docker

# Meminta input untuk nama node dan password user
read -p "Masukkan nama node Anda: " NODE_NAME
read -sp "Masukkan password untuk user zkverify: " USER_PASS
echo

# Membuat user zkverify dan menambahkannya ke grup Docker
echo_msg "Membuat user zkverify dan menambahkannya ke grup Docker..."
sudo useradd -m -s /bin/bash zkverify
echo "zkverify:$USER_PASS" | sudo chpasswd
sudo usermod -aG docker zkverify

# Pindah ke user zkverify
echo_msg "Pindah ke user zkverify..."
su - zkverify <<EOF
cd ~

# Clone repository ZKVerify
echo_msg "Cloning repository ZKVerify..."
git clone https://github.com/zkVerify/compose-zkverify-simplified.git
cd compose-zkverify-simplified

# Menjalankan skrip init.sh
echo_msg "Menjalankan skrip init.sh..."
./scripts/init.sh <<ANSWER
Validator Node
Testnet
Yes
$NODE_NAME
No
No
ANSWER

# Menjalankan node
echo_msg "Menjalankan node..."
./scripts/start.sh <<ANSWER
Validator Node
Testnet
ANSWER

# Menjalankan docker-compose untuk mengaktifkan node
docker compose -f /home/zkverify/compose-zkverify-simplified/deployments/validator-node/testnet/docker-compose.yml up -d

# Cek log node
echo_msg "Menunggu log node..."
docker logs -f validator-node
EOF

echo_msg "Proses instalasi selesai. Node Anda sekarang sedang berjalan!"
