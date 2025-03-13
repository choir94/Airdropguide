const { ethers } = require("ethers");
const readline = require("readline");
require("dotenv").config();

// Inisialisasi readline untuk input pengguna
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Variabel konfigurasi
let RPC_URL, CONTRACT_ADDRESS, PRIVATE_KEY, NUMBER_OF_TOKENS, MERKLE_PROOF;

// ABI kontrak dengan event NFTMinted
const ABI = [
    "function whitelistSaleActive() view returns (bool)",
    "function publicSaleActive() view returns (bool)",
    "function whitelistStartTime() view returns (uint256)",
    "function publicStartTime() view returns (uint256)",
    "function mintWhitelist(uint256 numberOfTokens, bytes32[] calldata merkleProof) payable",
    "function mintPublic(uint256 numberOfTokens) payable",
    "event NFTMinted(address indexed minter, uint256 tokenId, bool isWhitelist)"
];

// Fungsi untuk meminta input pengguna
function askQuestion(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

// Validasi input
function validateInput(input, type) {
    if (!input) throw new Error(`${type} tidak boleh kosong!`);
    if (type === "RPC_URL" && !input.startsWith("http")) throw new Error("RPC URL harus valid (http/https)!");
    if (type === "CONTRACT_ADDRESS" && !ethers.utils.isAddress(input)) throw new Error("Alamat kontrak tidak valid!");
    if (type === "NUMBER_OF_TOKENS" && (isNaN(input) || input <= 0)) throw new Error("Jumlah NFT harus angka positif!");
}

// Inisialisasi konfigurasi dari input pengguna
async function initializeConfig() {
    console.log("\n=====================================");
    console.log(" NFT Minting Bot by Airdrop Node");
    console.log(" Join Telegram: https://t.me/airdrop_node");
    console.log("=====================================\n");

    RPC_URL = await askQuestion("Masukkan RPC URL (contoh: https://mainnet.infura.io/v3/YOUR_KEY): ");
    validateInput(RPC_URL, "RPC_URL");

    CONTRACT_ADDRESS = await askQuestion("Masukkan alamat smart contract: ");
    validateInput(CONTRACT_ADDRESS, "CONTRACT_ADDRESS");

    PRIVATE_KEY = process.env.PRIVATE_KEY || await askQuestion("Masukkan private key (disarankan simpan di .env): ");
    if (!PRIVATE_KEY || !ethers.utils.isHexString(PRIVATE_KEY, 32)) {
        throw new Error("Private key tidak valid!");
    }
    if (!process.env.PRIVATE_KEY) {
        console.log("(!) Untuk keamanan, simpan PRIVATE_KEY di file .env!");
    }

    const numInput = await askQuestion("Masukkan jumlah NFT yang ingin di-mint: ");
    NUMBER_OF_TOKENS = parseInt(numInput);
    validateInput(NUMBER_OF_TOKENS, "NUMBER_OF_TOKENS");

    const proofInput = await askQuestion("Masukkan Merkle Proof (kosongkan jika tidak ada, format JSON array): ");
    MERKLE_PROOF = proofInput ? JSON.parse(proofInput) : [];

    console.log("\n--- Konfigurasi ---");
    console.log(`RPC URL          : ${RPC_URL}`);
    console.log(`Contract Address : ${CONTRACT_ADDRESS}`);
    console.log(`Number of Tokens : ${NUMBER_OF_TOKENS}`);
    console.log(`Merkle Proof     : ${MERKLE_PROOF.length > 0 ? MERKLE_PROOF.join(", ") : "Tidak ada"}`);
    console.log("------------------\n");
}

// Setup provider dan wallet
let provider, wallet, contract;
async function setupContract() {
    try {
        provider = new ethers.providers.JsonRpcProvider(RPC_URL);
        await provider.getNetwork();
        wallet = new ethers.Wallet(PRIVATE_KEY, provider);
        contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);
        await contract.whitelistSaleActive();
        console.log("Koneksi ke kontrak berhasil!");
    } catch (error) {
        throw new Error(`Gagal setup kontrak: ${error.message}`);
    }
}

// Fungsi untuk cek status sale
async function checkSaleStatus() {
    try {
        const whitelistActive = await contract.whitelistSaleActive();
        const publicActive = await contract.publicSaleActive();
        const whitelistStart = await contract.whitelistStartTime();
        const publicStart = await contract.publicStartTime();
        const currentTime = Math.floor(Date.now() / 1000);

        return {
            whitelist: whitelistActive && currentTime >= whitelistStart.toNumber(),
            public: publicActive && currentTime >= publicStart.toNumber()
        };
    } catch (error) {
        throw new Error(`Gagal cek status sale: ${error.message}`);
    }
}

// Fungsi untuk mint dengan retry dan hasil parsing
async function mintNFT(isWhitelist = false, retries = 3) {
    const price = isWhitelist ? 0.03 : 0.05;
    const value = ethers.utils.parseEther((price * NUMBER_OF_TOKENS).toString());

    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            console.log(`\n>>> Memulai minting ${NUMBER_OF_TOKENS} NFT (Percobaan ${attempt}/${retries}) <<<`);
            console.log(`Harga total: ${ethers.utils.formatEther(value)} ETH`);

            const gasEstimate = await (isWhitelist
                ? contract.estimateGas.mintWhitelist(NUMBER_OF_TOKENS, MERKLE_PROOF, { value })
                : contract.estimateGas.mintPublic(NUMBER_OF_TOKENS, { value })
            );
            const gasLimit = gasEstimate.mul(12).div(10);

            let tx;
            if (isWhitelist) {
                tx = await contract.mintWhitelist(NUMBER_OF_TOKENS, MERKLE_PROOF, { value, gasLimit });
            } else {
                tx = await contract.mintPublic(NUMBER_OF_TOKENS, { value, gasLimit });
            }

            console.log(`Transaction Hash: ${tx.hash}`);
            console.log("Menunggu konfirmasi...");

            const receipt = await tx.wait();

            // Parsing Token IDs dari event
            const tokenIds = [];
            receipt.logs.forEach(log => {
                try {
                    const parsedLog = contract.interface.parseLog(log);
                    if (parsedLog.name === "NFTMinted") {
                        tokenIds.push(parsedLog.args.tokenId.toString());
                    }
                } catch (e) {}
            });

            // Tampilkan hasil
            console.log("\n--- Hasil Minting ---");
            console.log(`Status          : ${receipt.status === 1 ? "Sukses" : "Gagal"}`);
            console.log(`Block Number    : ${receipt.blockNumber}`);
            console.log(`Gas Used        : ${ethers.utils.formatUnits(receipt.gasUsed, "gwei")} Gwei`);
            console.log(`Transaction Fee : ${ethers.utils.formatEther(receipt.gasUsed.mul(tx.gasPrice))} ETH`);
            console.log(`Token IDs       : ${tokenIds.length > 0 ? tokenIds.join(", ") : "Tidak terdeteksi (cek kontrak)"}`);
            console.log("--------------------");

            return receipt.status === 1;
        } catch (error) {
            console.log(`(!) Mint gagal (Percobaan ${attempt}): ${error.message}`);
            if (attempt === retries) {
                console.log("(!) Semua percobaan gagal!");
                return false;
            }
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }
}

// Monitoring dan mint
async function monitorAndMint() {
    console.log("\nStarting monitor...");
    while (true) {
        try {
            const status = await checkSaleStatus();
            
            if (status.whitelist && MERKLE_PROOF.length > 0) {
                console.log(">>> Whitelist sale active! Minting...");
                const success = await mintNFT(true);
                if (success) break;
            } else if (status.public) {
                console.log(">>> Public sale active! Minting...");
                const success = await mintNFT(false);
                if (success) break;
            } else {
                console.log(`Waiting for sale to start... (Checked at: ${new Date().toLocaleTimeString()})`);
                await new Promise(resolve => setTimeout(resolve, 5000));
            }
        } catch (error) {
            console.log(`(!) Error in monitoring: ${error.message}`);
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }
}

// Fungsi utama
async function main() {
    try {
        await initializeConfig();
        await setupContract();
        await monitorAndMint();
        console.log("\n=====================================");
        console.log(" Script ini dibuat oleh Airdrop Node");
        console.log(" Join Telegram: https://t.me/airdrop_node");
        console.log("=====================================");
    } catch (error) {
        console.log(`(!) Error: ${error.message}`);
    } finally {
        rl.close();
    }
}

// Jalankan
main();
