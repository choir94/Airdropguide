#!/bin/bash

# Fortytwo CPU Node Installer & Auto-Updater
# By Airdrop Node – https://t.me/airdrop_node

animate_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep 0.005
    done
    echo
}

clear
echo ""
echo "┌────────────────────────────────────────────────────────────┐"
echo "│       🚀 Fortytwo CPU Node Setup – Airdrop Node            │"
echo "├────────────────────────────────────────────────────────────┤"
echo "│ ⚙️  Telegram: https://t.me/airdrop_node                    │"
echo "│ 💻  Min Spec: 4 vCPU / 8 GB RAM                           │"
echo "└────────────────────────────────────────────────────────────┘"
echo ""

animate_text "Welcome to Fortytwo CPU Node Setup!"

# ──────────────── Check curl ────────────────
if ! command -v curl &> /dev/null; then
    animate_text "Installing curl..."
    sudo apt update && sudo apt install -y curl
fi

# ──────────────── Directory setup ────────────────
PROJECT_DIR="$HOME/FortytwoNode"
PROJECT_DEBUG_DIR="$PROJECT_DIR/debug"
PROJECT_MODEL_CACHE_DIR="$PROJECT_DIR/model_cache"
CAPSULE_EXEC="$PROJECT_DIR/FortytwoCapsule"
PROTOCOL_EXEC="$PROJECT_DIR/FortytwoProtocol"
UTILS_EXEC="$PROJECT_DIR/FortytwoUtils"
ACCOUNT_PRIVATE_KEY_FILE="$PROJECT_DIR/.account_private_key"
MODEL_CONFIG_FILE="$PROJECT_DIR/.model_config"

mkdir -p "$PROJECT_DEBUG_DIR" "$PROJECT_MODEL_CACHE_DIR"

# ──────────────── Download Fortytwo Utils ────────────────
UTILS_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/latest")
curl -L -o "$UTILS_EXEC" "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/v$UTILS_VERSION/FortytwoUtilsLinux"
chmod +x "$UTILS_EXEC"

# ──────────────── Identity Setup ────────────────
if [[ -f "$ACCOUNT_PRIVATE_KEY_FILE" ]]; then
    ACCOUNT_PRIVATE_KEY=$(cat "$ACCOUNT_PRIVATE_KEY_FILE")
    animate_text "✓ Private key loaded."
else
    echo -e "\nChoose identity method:"
    echo "[1] Create new identity with activation code"
    echo "[2] Recover existing identity with seed phrase"
    read -rp "Select option [1-2]: " IDENTITY_OPTION

    if [[ "$IDENTITY_OPTION" == "2" ]]; then
        while true; do
            read -rp "Enter your recovery phrase: " ACCOUNT_SEED_PHRASE
            ACCOUNT_PRIVATE_KEY=$("$UTILS_EXEC" --phrase "$ACCOUNT_SEED_PHRASE")
            if [[ "$ACCOUNT_PRIVATE_KEY" == 0x* ]]; then
                echo "$ACCOUNT_PRIVATE_KEY" > "$ACCOUNT_PRIVATE_KEY_FILE"
                animate_text "✓ Private key recovered and saved."
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
        animate_text "✓ New identity created."
    fi
fi

# ──────────────── Model Selection ────────────────
if [[ ! -f "$MODEL_CONFIG_FILE" ]]; then
    echo ""
    echo "Choose model to run on this CPU node:"
    echo "  [1] TinyLlama‑1.1B‑Chat – ultra‑light (≈1.1 GB RAM)"
    echo "  [2] Qwen3‑1.7B – smarter model (≈1.7 GB RAM)"
    read -rp "Select model [1-2] (default 1): " MODEL_OPTION
    MODEL_OPTION=${MODEL_OPTION:-1}

    if [[ "$MODEL_OPTION" == "2" ]]; then
        LLM_HF_REPO="unsloth/Qwen3-1.7B-GGUF"
        LLM_HF_MODEL_NAME="Qwen3-1.7B-Q4_K_M.gguf"
        NODE_NAME="Qwen 3 1.7B Q4"
    else
        LLM_HF_REPO="TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
        LLM_HF_MODEL_NAME="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        NODE_NAME="TinyLlama 1.1B Chat Q4"
    fi

    # Save model config
    cat <<EOF > "$MODEL_CONFIG_FILE"
LLM_HF_REPO="$LLM_HF_REPO"
LLM_HF_MODEL_NAME="$LLM_HF_MODEL_NAME"
NODE_NAME="$NODE_NAME"
EOF

    animate_text "Fetching model (this may take a few minutes)..."
    "$UTILS_EXEC" --hf-repo "$LLM_HF_REPO" --hf-model-name "$LLM_HF_MODEL_NAME" --model-cache "$PROJECT_MODEL_CACHE_DIR"
else
    source "$MODEL_CONFIG_FILE"
    animate_text "✓ Using previously selected model: $NODE_NAME"
fi

# ──────────────── Update Capsule ────────────────
animate_text "🔄 Updating Capsule..."
CAPSULE_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/latest")
curl -L -o "$CAPSULE_EXEC" "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/v$CAPSULE_VERSION/FortytwoCapsule-linux-amd64"
chmod +x "$CAPSULE_EXEC"

# ──────────────── Update Protocol ────────────────
animate_text "🔄 Updating Protocol Node..."
PROTOCOL_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/latest")
curl -L -o "$PROTOCOL_EXEC" "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/v$PROTOCOL_VERSION/FortytwoProtocolNode-linux-amd64"
chmod +x "$PROTOCOL_EXEC"

# ──────────────── Start Capsule ────────────────
animate_text "🚀 Launching Capsule..."
"$CAPSULE_EXEC" \
    --llm-hf-repo "$LLM_HF_REPO" \
    --llm-hf-model-name "$LLM_HF_MODEL_NAME" \
    --model-cache "$PROJECT_MODEL_CACHE_DIR" &
CAPSULE_PID=$!

CAPSULE_READY_URL="http://0.0.0.0:42442/ready"
animate_text "⏳ Waiting for Capsule to be ready..."
while true; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CAPSULE_READY_URL")
    [[ "$STATUS" == "200" ]] && break
    sleep 5
    if ! kill -0 "$CAPSULE_PID" 2>/dev/null; then
        echo "❌ Capsule exited unexpectedly."
        exit 1
    fi
done

# ──────────────── Start Protocol ────────────────
animate_text "🚀 Launching Protocol Node..."
"$PROTOCOL_EXEC" \
    --account-private-key "$ACCOUNT_PRIVATE_KEY" \
    --db-folder "$PROJECT_DEBUG_DIR/db" &
PROTOCOL_PID=$!

# ──────────────── Keep Alive ────────────────
trap "kill $CAPSULE_PID $PROTOCOL_PID 2>/dev/null; exit 0" SIGINT SIGTERM
wait
