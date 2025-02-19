#!/bin/bash

set -e

# Menentukan path file setup.rs
SETUP_FILE="$HOME/.nexus/network-api/clients/cli/src/setup.rs"

# Memastikan sistem diperbarui
echo "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y

# Menginstal dependensi yang diperlukan
echo "Menginstal dependensi..."
sudo apt install -y curl git build-essential libssl-dev pkg-config screen

# Memeriksa dan menginstal Rust jika belum ada
echo "Menginstal Rust dan Cargo..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi

# Menambahkan target Rust dan komponen rust-src
echo "Menambahkan target riscv32i-unknown-none-elf..."
rustup target add riscv32i-unknown-none-elf

echo "Menambahkan rust-src..."
rustup component add rust-src

# Memeriksa dan menginstal Nexus CLI
echo "Mengunduh dan menginstal Nexus CLI..."
if ! command -v nexus-cli &> /dev/null; then
    curl https://cli.nexus.xyz/ | sh
fi

# Menghapus setup.rs setelah menginstal Nexus CLI
echo "Menghapus file setup.rs lama..."
rm -f "$SETUP_FILE"

# Meminta pengguna memasukkan Node ID
read -p "Masukkan Node ID: " NODE_ID

# Membuat file setup.rs baru dengan Node ID yang telah dimasukkan
echo "Membuat file setup.rs baru dengan Node ID: $NODE_ID..."
mkdir -p "$(dirname "$SETUP_FILE")"

cat <<EOL > "$SETUP_FILE"
use colored::Colorize;
use directories::ProjectDirs;
use serde::{Deserialize, Serialize};
use std::fs;

pub enum SetupResult {
    Anonymous,
    Connected(String),
    Invalid,
}

#[derive(Serialize, Deserialize)]
pub struct UserConfig {
    pub node_id: String,
    pub user_id: Option<String>,
}

fn save_node_id(node_id: &str) -> std::io::Result<()> {
    let proj_dirs =
        ProjectDirs::from("xyz", "nexus", "cli").expect("Failed to determine config directory");
    let config_path = proj_dirs.config_dir().join("user.json");

    let config = UserConfig {
        node_id: node_id.to_string(),
        user_id: None,
    };

    fs::create_dir_all(proj_dirs.config_dir())?;
    fs::write(&config_path, serde_json::to_string_pretty(&config)?)?;

    println!("Node ID {} saved successfully!", node_id);
    Ok(())
}

pub async fn run_initial_setup() -> SetupResult {
    let proj_dirs =
        ProjectDirs::from("xyz", "nexus", "cli").expect("Failed to determine config directory");
    let config_path = proj_dirs.config_dir().join("user.json");

    // Cek apakah ada konfigurasi yang sudah tersimpan
    if config_path.exists() {
        println!("\nThis node is already connected to an account");

        match fs::read_to_string(&config_path) {
            Ok(content) => match serde_json::from_str::<UserConfig>(&content) {
                Ok(user_config) => {
                    println!("\nUsing existing node ID: {}", user_config.node_id);
                    return SetupResult::Connected(user_config.node_id);
                }
                Err(e) => {
                    println!("{}", format!("Failed to parse config file: {}", e).red());
                    return SetupResult::Invalid;
                }
            },
            Err(e) => {
                println!("{}", format!("Failed to read config file: {}", e).red());
                return SetupResult::Invalid;
            }
        }
    }

    // Menggunakan Node ID yang dimasukkan pengguna dalam skrip Bash
    let node_id = "$NODE_ID".to_string();
    println!("Using predefined node ID: {}", node_id);

    match save_node_id(&node_id) {
        Ok(_) => SetupResult::Connected(node_id),
        Err(e) => {
            println!("{}", format!("Failed to save node ID: {}", e).red());
            SetupResult::Invalid
        }
    }
}

pub fn clear_user_config() -> std::io::Result<()> {
    let proj_dirs =
        ProjectDirs::from("xyz", "nexus", "cli").expect("Failed to determine config directory");
    let config_path = proj_dirs.config_dir().join("user.json");
    
    if config_path.exists() {
        fs::remove_file(config_path)?;
        println!("User configuration cleared successfully!");
    }

    Ok(())
}
EOL

echo "File setup.rs berhasil dibuat dengan Node ID yang dimasukkan!"

# Menjalankan Nexus CLI dalam screen
echo "Menjalankan Nexus CLI dalam screen dengan nama 'nexus'..."
screen -dmS nexus bash -c "nexus-cli --start --beta | tee nexus.log"

echo "Instalasi selesai!"
echo "Untuk melihat proses Nexus CLI, gunakan perintah: screen -r nexus"
echo "Untuk keluar dari screen tanpa menghentikan proses, tekan Ctrl+A, lalu D."
