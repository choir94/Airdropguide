#!/bin/bash

# CPU-ONLY VERSION OF FORTYTWO NODE SETUP

animate_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep 0.006
    done
    echo
}

# BANNER
animate_text "\nWelcome to ::|| Fortytwo, CPU Node Setup"

# Check for curl
if ! command -v curl &> /dev/null; then
    animate_text "Installing curl..."
    sudo apt update && sudo apt install -y curl
fi

# Set directories
PROJECT_DIR="./FortytwoNode"
PROJECT_DEBUG_DIR="$PROJECT_DIR/debug"
PROJECT_MODEL_CACHE_DIR="$PROJECT_DIR/model_cache"
CAPSULE_EXEC="$PROJECT_DIR/FortytwoCapsule"
PROTOCOL_EXEC="$PROJECT_DIR/FortytwoProtocol"
UTILS_EXEC="$PROJECT_DIR/FortytwoUtils"
ACCOUNT_PRIVATE_KEY_FILE="$PROJECT_DIR/.account_private_key"

# Create dirs if missing
mkdir -p "$PROJECT_DEBUG_DIR" "$PROJECT_MODEL_CACHE_DIR"

# Download utilities
UTILS_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/latest")
UTILS_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/v$UTILS_VERSION/FortytwoUtilsLinux"
curl -L -o "$UTILS_EXEC" "$UTILS_URL"
chmod +x "$UTILS_EXEC"

# Prompt recovery or new
if [[ -f "$ACCOUNT_PRIVATE_KEY_FILE" ]]; then
    ACCOUNT_PRIVATE_KEY=$(cat "$ACCOUNT_PRIVATE_KEY_FILE")
    animate_text "Private key loaded. Continuing setup."
else
    echo -e "\nChoose identity method:"
    echo "[1] Create new identity with activation code"
    echo "[2] Recover existing identity with phrase"
    read -rp "Select option [1-2]: " IDENTITY_OPTION

    if [[ "$IDENTITY_OPTION" == "2" ]]; then
        while true; do
            read -rp "Enter your recovery phrase (12/18/24 words): " ACCOUNT_SEED_PHRASE
            ACCOUNT_PRIVATE_KEY=$("$UTILS_EXEC" --phrase "$ACCOUNT_SEED_PHRASE")
            if [[ "$ACCOUNT_PRIVATE_KEY" == 0x* ]]; then
                echo "$ACCOUNT_PRIVATE_KEY" > "$ACCOUNT_PRIVATE_KEY_FILE"
                animate_text "Private key recovered and saved."
                break
            else
                echo "Invalid phrase. Try again."
            fi
        done
    else
        "$UTILS_EXEC" --check-drop-service || exit 1
        read -rp "Enter activation code: " INVITE_CODE
        "$UTILS_EXEC" --create-wallet "$ACCOUNT_PRIVATE_KEY_FILE" --drop-code "$INVITE_CODE"
        ACCOUNT_PRIVATE_KEY=$(<"$ACCOUNT_PRIVATE_KEY_FILE")
        animate_text "New identity created."
    fi
fi

# Auto model (Qwen3-1.7B for CPU)
LLM_HF_REPO="unsloth/Qwen3-1.7B-GGUF"
LLM_HF_MODEL_NAME="Qwen3-1.7B-Q4_K_M.gguf"
NODE_NAME="Qwen 3 1.7B Q4"

# Download model
animate_text "Downloading and preparing model..."
"$UTILS_EXEC" --hf-repo "$LLM_HF_REPO" --hf-model-name "$LLM_HF_MODEL_NAME" --model-cache "$PROJECT_MODEL_CACHE_DIR"

# Download Fortytwo Protocol and Capsule (CPU ONLY)
CAPSULE_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/latest")
CAPSULE_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/v$CAPSULE_VERSION/FortytwoCapsule-linux-amd64"
curl -L -o "$CAPSULE_EXEC" "$CAPSULE_URL"
chmod +x "$CAPSULE_EXEC"

PROTOCOL_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/latest")
PROTOCOL_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/v$PROTOCOL_VERSION/FortytwoProtocolNode-linux-amd64"
curl -L -o "$PROTOCOL_EXEC" "$PROTOCOL_URL"
chmod +x "$PROTOCOL_EXEC"

# Start node
animate_text "Launching node..."
"$CAPSULE_EXEC" --llm-hf-repo "$LLM_HF_REPO" --llm-hf-model-name "$LLM_HF_MODEL_NAME" --model-cache "$PROJECT_MODEL_CACHE_DIR" &
CAPSULE_PID=$!

# Wait until capsule is ready
animate_text "Waiting for capsule..."
CAPSULE_READY_URL="http://0.0.0.0:42442/ready"
while true; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CAPSULE_READY_URL")
    [[ "$STATUS" == "200" ]] && break
    sleep 5
    if ! kill -0 "$CAPSULE_PID" 2>/dev/null; then
        echo "Capsule exited unexpectedly."
        exit 1
    fi
done

animate_text "Starting protocol node..."
"$PROTOCOL_EXEC" --account-private-key "$ACCOUNT_PRIVATE_KEY" --db-folder "$PROJECT_DEBUG_DIR/db" &
PROTOCOL_PID=$!

# Keep alive
trap "kill $CAPSULE_PID $PROTOCOL_PID 2>/dev/null; exit 0" SIGINT SIGTERM
wait
