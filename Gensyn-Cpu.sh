#!/bin/bash

# Define colors for a more vibrant and modern look
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
            cd $HOME && git clone https://github.com/choir94/rl-swarm.git > /dev/null 2>&1

            mv "$HOME_DIR/swarm.pem" rl-swarm/
            mv "$HOME_DIR/userData.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            mv "$HOME_DIR/userApiKey.json" rl-swarm/modal-login/temp-data/ 2>/dev/null
            break
        elif [ "$choice" == "2" ]; then
            echo -e "${BOLD}${GREEN}[✓] Removing existing folder and starting fresh...${NC}"
            rm -rf "$SWARM_DIR"
            sleep 2
            cd $HOME && git clone https://github.com/choir94/rl-swarm.git > /dev/null 2>&1
            break
        else
            echo -e "\n${BOLD}${RED}[✗] Invalid choice. Please enter 1 or 2.${NC}"
        fi
    done
else
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${GREEN}[✓] No existing swarm.pem found. Cloning repository...${NC}"
    cd $HOME && [ -d rl-swarm ] && rm -rf rl-swarm; git clone https://github.com/choir94/rl-swarm.git > /dev/null 2>&1
fi

cd rl-swarm || { echo -e "${BOLD}${RED}[✗] Failed to enter rl-swarm directory. Exiting.${NC}"; exit 1; }

echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${GREEN}[✓] Running rl-swarm...${NC}"
./run_rl_swarm.sh
