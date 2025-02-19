#!/bin/bash
# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
set -e

echo "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y

echo "Menginstal dependensi..."
sudo apt install -y curl git build-essential libssl-dev pkg-config screen

echo "Menginstal Rust dan Cargo..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "Menambahkan target riscv32i-unknown-none-elf..."
rustup target add riscv32i-unknown-none-elf

echo "Menambahkan rust-src..."
rustup component add rust-src

echo "Mengunduh Nexus CLI..."
mkdir -p ~/.nexus && cd ~/.nexus
git clone https://github.com/nexus-xyz/nexus-network.git network-api
cd network-api/clients/cli

echo "Membangun Nexus CLI..."
cargo build --release

# Meminta pengguna memasukkan Node ID
NODE_ID=""
read -p "Masukkan Node ID: " NODE_ID

# Pastikan direktori ada
SETUP_FILE="$HOME/.nexus/network-api/clients/cli/src/setup.rs"

echo "Menghapus file setup.rs lama..."
rm -f "$SETUP_FILE"

echo "Membuat file setup.rs baru..."
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

echo "File setup.rs berhasil dibuat dengan Node ID: $NODE_ID"

echo "Menjalankan Nexus CLI dalam screen dengan nama 'nexus'..."
screen -dmS nexus bash -c "cd ~/.nexus/network-api/clients/cli && cargo run --release -- --start --beta"

echo "Instalasi selesai!"
echo "Untuk melihat proses Nexus CLI, gunakan perintah: screen -r nexus"
echo "Untuk keluar dari screen tanpa menghentikan proses, tekan Ctrl+A, lalu D."
