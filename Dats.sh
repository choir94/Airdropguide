#!/bin/bash
# Memperbarui sistem dan menginstal paket yang diperlukan
sudo apt update && sudo apt upgrade -y
sudo apt install ubuntu-desktop xrdp docker.io unzip screen -y

# Mengatur XRDP
sudo adduser xrdp ssl-cert
sudo systemctl start gdm
sudo systemctl restart xrdp

# Mengatur Docker
sudo systemctl start docker
sudo systemctl enable docker

# Mengunduh dan menginstal DATS Node
wget https://dl.datsproject.io/evm-linux-deb -O dats-node.deb

# Memeriksa apakah file yang diunduh ada sebelum menginstalnya
if [ -f "dats-node.deb" ]; then  
    sudo dpkg -i dats-node.deb  
else  
    echo "Kesalahan: File DATS Node tidak ditemukan!"  
    exit 1  
fi  

# Menginstal dependensi yang diperlukan
sudo apt update
sudo apt install -y desktop-file-utils libgbm1 libasound2
sudo apt install -f
sudo dpkg --configure -a

# Membuat skrip untuk menjalankan DATS Node
cat > /usr/local/bin/start-dats << 'EOF'
#!/bin/bash
if screen -ls | grep -q "dats"; then
    screen -r dats
else
    screen -dmS dats bash -c 'dats-node --no-sandbox | tee /var/log/dats-node.log'
fi
EOF

chmod +x /usr/local/bin/start-dats

echo "Instalasi selesai. Jalankan node dengan perintah: start-dats"
