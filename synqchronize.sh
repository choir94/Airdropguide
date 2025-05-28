#!/bin/bash

# --- Start Script ---

# Function to display success messages
log_success() {
    echo -e "\n\033[0;32m[SUCCESS]\033[0m $1"
}

# Function to display info messages
log_info() {
    echo -e "\n\033[0;34m[INFO]\033[0m $1"
}

# Function to display warning messages
log_warn() {
    echo -e "\n\033[0;33m[WARNING]\033[0m $1"
}

# Function to display error messages and exit
log_error() {
    echo -e "\n\033[0;31m[ERROR]\033[0m $1"
    exit 1
}

# Ensure the script is run as root or with sudo
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo."
fi

echo "███████╗██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██████╗ ██╗███╗   ██╗██████╗ ███████╗"
echo "   #####   ##  ##   ##   ##  #####     ####   ##   ##  ######    #####   ##   ##   ####    #######  ####### ";
echo "  ##   ##  ##  ##   ###  ## ##   ##   ##  ##  ##   ##   ##  ##  ##   ##  ###  ##    ##     #   ##    ##   # ";
echo "  #        ##  ##   #### ## ##   ##  ##       ##   ##   ##  ##  ##   ##  #### ##    ##        ##     ## # ";
echo "   #####    ####    ## #### ##   ##  ##       #######   #####   ##   ##  ## ####    ##       ##      #### ";
echo "       ##    ##     ##  ### ##   ##  ##       ##   ##   ## ##   ##   ##  ##  ###    ##      ##       ## # ";
echo "  ##   ##    ##     ##   ## ##  ###   ##  ##  ##   ##   ##  ##  ##   ##  ##   ##    ##     ##    #   ##   # ";
echo "   #####    ####    ##   ##  #####     ####   ##   ##  #### ##   #####   ##   ##   ####    #######  ####### ";

echo "                      AIRDROP NODE                      "
echo "--------------------------------------------------------"
echo "        By Airdrop Node - Join our community!           "
echo "        Telegram: https://t.me/airdrop_node         "
echo "--------------------------------------------------------"
echo ""
log_info "Starting automatic Synqchronize (Airdrop Node) installation on your VPS."
log_info "Please ensure you are using an Ubuntu/Debian based distribution."

# --- Section 1: Docker Installation & Configuration ---
log_info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    log_success "Docker is already installed: $(docker --version)"
    log_info "Skipping Docker installation steps."
else
    log_info "Docker not found. Proceeding with Docker installation..."

    # Remove old Docker installations (if any)
    log_info "Removing old Docker installations (if any)..."
    apt-get remove docker docker-engine docker.io containerd runc -y >/dev/null 2>&1

    # Update package list and install dependencies
    log_info "Updating package list and installing necessary dependencies..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release >/dev/null 2>&1

    # Create keyring directory if it doesn't exist
    log_info "Creating /etc/apt/keyrings directory..."
    mkdir -p /etc/apt/keyrings >/dev/null 2>&1

    # Download Docker's official GPG key and save with correct permissions
    log_info "Downloading and adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository to APT sources
    log_info "Adding Docker repository to APT..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine, CLI, Containerd, and Docker Compose
    log_info "Installing Docker Engine, CLI, Containerd, and Docker Compose..."
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1

    # Verify Docker installation
    log_info "Verifying Docker installation..."
    if docker run hello-world >/dev/null 2>&1; then
        log_success "Docker installed and functioning correctly."
    else
        log_error "Failed to install Docker. Please check your internet connection or error logs."
    fi
fi

# Add current user (likely root if running this script directly) to the docker group
log_info "Adding current user to the 'docker' group..."
usermod -aG docker $USER
log_warn "After the installation is complete, you may need to LOGOUT and LOGIN AGAIN"
log_warn "for the 'docker' group changes to take effect, allowing you to run 'docker' without sudo."

# --- Section 2: Node.js & npm Installation (if not already present) ---
log_info "Checking Node.js installation..."
if command -v node &> /dev/null; then
    log_success "Node.js is already installed: $(node -v)"
else
    log_info "Node.js not found. Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs >/dev/null 2>&1
    if command -v node &> /dev/null; then
        log_success "Node.js $(node -v) and npm $(npm -v) successfully installed."
    else
        log_error "Failed to install Node.js. Please check your internet connection or error logs."
    fi
fi

# --- Section 3: Synqchronize Installation ---
log_info "Installing Synqchronize global package..."
npm install -g synqchronizer >/dev/null 2>&1
if command -v synqchronize &> /dev/null; then
    log_success "Synqchronize successfully installed globally."
else
    log_warn "Synqchronize is installed, but 'synqchronize' might not be immediately recognized as a command."
    log_warn "This is common if you're using NVM or a non-standard Node.js installation."
    # Ensure PATH is set, especially if NVM is used
    NPM_GLOBAL_BIN_PATH="$(npm config get prefix)/bin"
    if [[ ":$PATH:" != *":$NPM_GLOBAL_BIN_PATH:"* ]]; then
        log_info "Adding NPM global bin path to PATH..."
        echo "export PATH=\"$NPM_GLOBAL_BIN_PATH:\$PATH\"" >> ~/.bashrc
        source ~/.bashrc # Attempt to apply in this session
        log_success "PATH has been updated. 'synqchronize' should be discoverable now."
    fi
fi

# --- Section 4: Interactive Synqchronize Configuration ---
log_info "Starting Synqchronize configuration. Please enter your details when prompted."
synqchronize init

# --- Section 5: Setting up Systemd Service ---
log_info "Setting up Synqchronize as a Systemd service..."
synqchronize service

# Copy service file to Systemd directory
log_info "Copying Synqchronize service file to /etc/systemd/system/..."
cp "$(eval echo ~$USER)"/.synqchronizer/synqchronizer.service /etc/systemd/system/

# Reload Systemd daemon
log_info "Reloading Systemd daemon..."
systemctl daemon-reload

# Enable auto-start of the service on boot
log_info "Enabling Synqchronize service for auto-start on boot..."
systemctl enable synqchronizer

# Start the Synqchronize service
log_info "Starting Synqchronize service..."
systemctl start synqchronizer

# Verify service status
log_info "Verifying Synqchronize service status..."
if systemctl is-active --quiet synqchronizer; then
    log_success "Synqchronize service is running and installed for auto-start!"
else
    log_error "Synqchronize service failed to start. Please check logs with 'sudo journalctl -u synqchronizer -f'."
fi

# --- End Section ---
log_info "Synqchronize installation complete!"
log_warn "IMPORTANT: Port 3000 (for the web dashboard) is NOT automatically configured."
log_warn "You will need to manually open port 3000 in your VPS firewall if you want to access the dashboard from outside."
log_info "Your node should now be running as a Systemd service."
log_info "You can monitor it using:"
log_info "  - synqchronize status"
log_info "  - synqchronize web (then access http://<YOUR_VPS_IP>:3000 in your browser)"
log_warn "Remember to LOGOUT and LOGIN AGAIN for 'docker' group and PATH changes to take full effect."
log_info "Thank you for using the script by Airdrop Node!"
log_info "Telegram: https://t.me/airdrop_node"

# --- End Script ---
