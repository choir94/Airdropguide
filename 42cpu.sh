#!/bin/bash
# Fortytwo Node – CPU‑only edition with selectable lightweight GGUF models
# Compatible with ~4 CPU / 8 GB RAM VPS

animate_text() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep 0.006
    done
    echo
}

animate_text "\nWelcome to ::|| Fortytwo CPU Node Setup"

# ─────────────────────────────────────────────────────────────
# 0. Ensure curl is present
# ─────────────────────────────────────────────────────────────
if ! command -v curl >/dev/null 2>&1; then
    animate_text "curl not found – installing…"
    sudo apt update && sudo apt install -y curl
fi

# ─────────────────────────────────────────────────────────────
# 1. Define directories & executables
# ─────────────────────────────────────────────────────────────
PROJECT_DIR="${HOME}/FortytwoNode"
PROJECT_DEBUG_DIR="${PROJECT_DIR}/debug"
PROJECT_MODEL_CACHE_DIR="${PROJECT_DIR}/model_cache"
CAPSULE_EXEC="${PROJECT_DIR}/FortytwoCapsule"
PROTOCOL_EXEC="${PROJECT_DIR}/FortytwoProtocol"
UTILS_EXEC="${PROJECT_DIR}/FortytwoUtils"
ACCOUNT_PRIVATE_KEY_FILE="${PROJECT_DIR}/.account_private_key"

mkdir -p "${PROJECT_DEBUG_DIR}" "${PROJECT_MODEL_CACHE_DIR}"

# ─────────────────────────────────────────────────────────────
# 2. Download Fortytwo utilities (wallet helper)
# ─────────────────────────────────────────────────────────────
UTILS_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/latest")
UTILS_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/utilities/v${UTILS_VERSION}/FortytwoUtilsLinux"
curl -L -o "${UTILS_EXEC}" "${UTILS_URL}"
chmod +x "${UTILS_EXEC}"

# ─────────────────────────────────────────────────────────────
# 3. Identity management – load / recover / create
# ─────────────────────────────────────────────────────────────
if [[ -f "${ACCOUNT_PRIVATE_KEY_FILE}" ]]; then
    ACCOUNT_PRIVATE_KEY=$(cat "${ACCOUNT_PRIVATE_KEY_FILE}")
    animate_text "✓ Private key loaded – continuing setup."
else
    echo -e "\nChoose identity method:"
    echo "[1] Create new identity with activation code (default)"
    echo "[2] Recover existing identity with seed phrase"
    read -rp "Select option [1-2] (default 1): " ID_OPTION
    ID_OPTION=${ID_OPTION:-1}

    if [[ "${ID_OPTION}" == "2" ]]; then
        while true; do
            read -rp "Enter your recovery phrase: " ACCOUNT_SEED_PHRASE
            ACCOUNT_PRIVATE_KEY=$("${UTILS_EXEC}" --phrase "${ACCOUNT_SEED_PHRASE}")
            if [[ "${ACCOUNT_PRIVATE_KEY}" == 0x* ]]; then
                echo "${ACCOUNT_PRIVATE_KEY}" > "${ACCOUNT_PRIVATE_KEY_FILE}"
                animate_text "✓ Private key recovered & saved."
                break
            else
                echo "Invalid phrase – try again."
            fi
        done
    else
        "${UTILS_EXEC}" --check-drop-service || exit 1
        read -rp "Enter activation code: " INVITE_CODE
        "${UTILS_EXEC}" --create-wallet "${ACCOUNT_PRIVATE_KEY_FILE}" --drop-code "${INVITE_CODE}"
        ACCOUNT_PRIVATE_KEY=$(<"${ACCOUNT_PRIVATE_KEY_FILE}")
        animate_text "✓ New identity created."
    fi
fi

# ─────────────────────────────────────────────────────────────
# 4. Model menu – choose 1 of 3 lightweight options
# ─────────────────────────────────────────────────────────────
cat <<EOF
\nChoose model for CPU‑only node (enter number and press Enter):
  [1] Gemma‑2B‑IT  – balanced multilingual (≈2.6 GB RAM)
  [2] TinyLlama‑1.1B‑Chat – ultra‑light (≈1.1 GB RAM)
  [3] Mistral‑7B‑Instruct – most powerful (≈4 GB RAM, may be slower)
Default (1) will be used if empty.
EOF
read -rp "Model [1-3]: " MODEL_OPTION
MODEL_OPTION=${MODEL_OPTION:-1}

case "${MODEL_OPTION}" in
    2)
        LLM_HF_REPO="TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
        LLM_HF_MODEL_NAME="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        NODE_NAME="TinyLlama 1.1B Chat Q4"
        ;;
    3)
        LLM_HF_REPO="TheBloke/Mistral-7B-Instruct-v0.1-GGUF"
        LLM_HF_MODEL_NAME="mistral-7b-instruct-v0.1.Q4_K_M.gguf"
        NODE_NAME="Mistral 7B Instruct Q4"
        ;;
    *)
        LLM_HF_REPO="TheBloke/gemma-2b-it-GGUF"
        LLM_HF_MODEL_NAME="gemma-2b-it.Q4_K_M.gguf"
        NODE_NAME="Gemma 2B IT Q4"
        ;;
esac

animate_text "Selected model: ${NODE_NAME}"

# ─────────────────────────────────────────────────────────────
# 5. Download model GGUF (cached if already exists)
# ─────────────────────────────────────────────────────────────
animate_text "Fetching model (first run may take several minutes)…"
"${UTILS_EXEC}" --hf-repo "${LLM_HF_REPO}" --hf-model-name "${LLM_HF_MODEL_NAME}" --model-cache "${PROJECT_MODEL_CACHE_DIR}"

# ─────────────────────────────────────────────────────────────
# 6. Download Fortytwo Capsule & Protocol (CPU binaries)
# ─────────────────────────────────────────────────────────────
CAPSULE_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/latest")
CAPSULE_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/v${CAPSULE_VERSION}/FortytwoCapsule-linux-amd64"
curl -L -o "${CAPSULE_EXEC}" "${CAPSULE_URL}"
chmod +x "${CAPSULE_EXEC}"

PROTOCOL_VERSION=$(curl -s "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/latest")
PROTOCOL_URL="https://fortytwo-network-public.s3.us-east-2.amazonaws.com/protocol/v${PROTOCOL_VERSION}/FortytwoProtocolNode-linux-amd64"
curl -L -o "${PROTOCOL_EXEC}" "${PROTOCOL_URL}"
chmod +x "${PROTOCOL_EXEC}"

# ─────────────────────────────────────────────────────────────
# 7. Launch Capsule
# ─────────────────────────────────────────────────────────────
animate_text "Launching Capsule…"
"${CAPSULE_EXEC}" --llm-hf-repo "${LLM_HF_REPO}" --llm-hf-model-name "${LLM_HF_MODEL_NAME}" --model-cache "${PROJECT_MODEL_CACHE_DIR}" &
CAPSULE_PID=$!

CAPSULE_READY_URL="http://0.0.0.0:42442/ready"
animate_text "Waiting for Capsule readiness…"
while true; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${CAPSULE_READY_URL}")
    [[ "${STATUS}" == "200" ]] && break
    sleep 5
    if ! kill -0 "${CAPSULE_PID}" 2>/dev/null; then
        echo "Capsule exited unexpectedly."; exit 1
    fi
done

# ─────────────────────────────────────────────────────────────
# 8. Launch Protocol Node
# ─────────────────────────────────────────────────────────────
animate_text "Starting Protocol node…"
"${PROTOCOL_EXEC}" --account-private-key "${ACCOUNT_PRIVATE_KEY}" --db-folder "${PROJECT_DEBUG_DIR}/db" &
PROTOCOL_PID=$!

# ─────────────────────────────────────────────────────────────
# 9. Keep processes alive & graceful shutdown
# ─────────────────────────────────────────────────────────────
trap "kill ${CAPSULE_PID} ${PROTOCOL_PID} 2>/dev/null; exit 0" SIGINT SIGTERM
wait
