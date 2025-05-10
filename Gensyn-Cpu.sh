#!/bin/bash

# Define colors for a vibrant and modern look
BOLD="\e[1m"
CYAN="\e[36m"
PURPLE="\e[35m"
GREEN="\e[92m"
RED="\e[91m"
YELLOW="\e[93m"
NC="\e[0m"

SWARM_DIR="$HOME/rl-swarm"
TEMP_DATA_PATH="$SWARM_DIR/modal-login/temp-data"
HOME_DIR="$HOME"

# Function to check if a command is installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install dependencies if not already installed
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${GREEN}[✓] Checking and installing dependencies...${NC}"

# Update package lists
echo -e "${BOLD}${YELLOW}[✓] Updating package lists...${NC}"
apt update || { echo -e "${BOLD}${RED}[✗] Failed to update package lists. Exiting.${NC}"; exit 1; }

# Install sudo if not present
if ! command_exists sudo; then
    echo -e "${BOLD}${YELLOW}[✓] Installing sudo...${NC}"
    apt install -y sudo || { echo -e "${BOLD}${RED}[✗] Failed to install sudo. Exiting.${NC}"; exit 1; }
else
    echo -e "${BOLD}${GREEN}[✓] sudo is already installed.${NC}"
fi

# Update package lists with sudo
echo -e "${BOLD}${YELLOW}[✓] Updating package lists with sudo...${NC}"
sudo apt update || { echo -e "${BOLD}${RED}[✗] Failed to update package lists with sudo. Exiting.${NC}"; exit 1; }

# List of apt packages to install
APT_PACKAGES="python3 python3-venv python3-pip curl wget screen git lsof nano unzip"

# Check and install each apt package
for pkg in $APT_PACKAGES; do
    if ! command_exists "$pkg"; then
        echo -e "${BOLD}${YELLOW}[✓] Installing $pkg...${NC}"
        sudo apt install -y "$pkg" || { echo -e "${BOLD}${RED}[✗] Failed to install $pkg. Exiting.${NC}"; exit 1; }
    else
        echo -e "${BOLD}${GREEN}[✓] $pkg is already installed.${NC}"
    fi
done

# Install Node.js if not present
if ! command_exists node; then
    echo -e "${BOLD}${YELLOW}[✓] Setting up Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs || { echo -e "${BOLD}${RED}[✗] Failed to install Node.js. Exiting.${NC}"; exit 1; }
else
    echo -e "${BOLD}${GREEN}[✓] Node.js is already installed.${NC}"
fi

echo -e "${BOLD}${CYAN}============================================================${NC}"

# Proceed with the original script
cd $HOME

if [ -f "$SWARM_DIR/swarm.pem" ]; then
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${YELLOW}You already have an existing ${GREEN}swarm.pem${YELLOW} file.${NC}"
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${PURPLE}Please choose an option:${NC}"
    echo -e "${BOLD}${GREEN}1) Use the existing swarm.pem${NC}"
    echo -e "${BOLD}${RED}2) Delete existing swarm.pem and start fresh${NC}"

    while true; do
        read -p $'\e[1m\e[93mEnter your choice (1 or 2): \e[0m' choice
        if [ "$choice" == "1" ]; then
            echo -e "\n${BOLD}${GREEN}[✓] Using existing swarm.pem...${NC}"
            mv "$SWARM_DIR/swarm.pem" "$HOME_DIR/"
            mv "$TEMP_DATA_PATH/userData.json" "$HOME_DIR/" 2>/dev/null
            mv "$TEMP_DATA_PATH/userApiKey.json" "$HOME_DIR/" 2>/dev/null

            rm -rf "$SWARM_DIR"

            echo -e "${BOLD}${GREEN}[✓] Cloning fresh repository...${NC}"
            cd $HOME && git clone https://github.com/choir94/rl-swarm.git
            mv "$HOME_DIR/swarm.pem" rl-swarm/
            mv "$HOME_DIR/userData.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            mv "$HOME_DIR/userApiKey.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            break
        elif [ "$choice" == "2" ]; then
            echo -e "${BOLD}${GREEN}[✓] Removing existing folder and starting fresh...${NC}"
            rm -rf "$SWARM_DIR"
            sleep 2
            cd $HOME && git clone https://github.com/choir94/rl-swarm.git
            break
        else
            echo -e "\n${BOLD}${RED}[✗] Invalid choice. Please enter 1 or 2.${NC}"
        fi
    done
else
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${GREEN}[✓] No existing swarm.pem found. Cloning repository...${NC}"
    cd $HOME && [ -d rl-swarm ] && rm -rf rl-swarm; git clone https://github.com/choir94/rl-swarm.git
fi

cd rl-swarm || { echo -e "${BOLD}${RED}[✗] Failed to enter rl-swarm directory. Exiting.${NC}"; exit 1; }

echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${GREEN}[✓] Running rl-swarm...${NC}"
./run_rl_swarm.sh
