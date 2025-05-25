# 🚀 Aztec Sequencer - One-Click Setup

```
╔═════════════════════════════════════════════════════════════════════════════╗
║                                                                             ║
║    ██████╗ ██╗  ██╗ ██████╗ ██╗  ██╗███████╗███████╗██╗  ██╗                ║
║   ██╔═████╗╚██╗██╔╝██╔═══██╗██║  ██║╚══███╔╝██╔════╝██║  ██║                ║
║   ██║██╔██║ ╚███╔╝ ██║   ██║███████║  ███╔╝ ███████╗███████║                ║
║   ████╔╝██║ ██╔██╗ ██║   ██║██╔══██║ ███╔╝  ╚════██║██╔══██║                ║
║   ╚██████╔╝██╔╝ ██╗╚██████╔╝██║  ██║███████╗███████║██║  ██║                ║
║    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝                ║
║                                                                             ║
║                      🚀 Aztec Sequencer Setup 🚀                           ║
║                                                                             ║
║                     Follow us: https://x.com/0xohzsh                       ║
║                                                                             ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

**Automated Aztec Alpha Testnet Sequencer deployment with Docker**

**Follow us on X (Twitter): [@0xohzsh](https://x.com/0xohzsh)**

## ✨ One-Click Installation

```bash
curl -fsSL https://raw.githubusercontent.com/0xohzsh/aztec-sequencer/main/setup.sh | bash
```

## 📋 Requirements

- **Ubuntu/Debian** server with sudo access
- **8+ CPU cores**, **8GB+ RAM**, **100GB+ SSD**
- **Ethereum Sepolia RPC** (Ankr/Alchemy/Infura/Own)
- **Beacon Chain RPC** (Ex: `https://rpc.drpc.org/eth/sepolia/beacon`)
- **Validator private key** with Sepolia ETH

## 🚀 Quick Start

1. **Run the setup script** (interactive prompts will guide you)
2. **Provide required details:**

   - Ethereum RPC URL
   - Beacon chain URL
   - Validator private key (with 0x prefix)
   - Coinbase address
   - P2P IP (auto-detected)

3. **Script automatically:**
   - Installs Docker if needed
   - Creates `aztec-sequencer` directory
   - Generates `.env` and `docker-compose.yml`
   - Starts the sequencer

## 🔧 Management Commands

```bash
# View logs
docker logs -f aztec-sequencer

# View validator-specific logs
sudo docker logs $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1) 2>&1 | grep -i validator

# Stop sequencer
cd aztec-sequencer && docker compose down

# Start sequencer
cd aztec-sequencer && docker compose up -d

# Check status
docker compose ps
```

## 📊 Sequencer & Validator Registration

After your node syncs, register as a validator:

1. **Join Discord**: [https://discord.gg/aztec](https://discord.gg/aztec)
2. **Run**: `/operator start` in `operators|start-here` channel
3. **Get proof data**:

   ```bash
   # Get proven block and sync proof
   PROVEN_BLOCK=$(curl -s -X POST -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
     http://localhost:8080 | jq -r ".result.proven.number")

   if [[ -z "$PROVEN_BLOCK" || "$PROVEN_BLOCK" == "null" ]]; then
     echo "Failed to retrieve the proven L2 block number."
   else
     echo "Proven L2 Block Number: $PROVEN_BLOCK"
     echo "Fetching Sync Proof..."
     SYNC_PROOF=$(curl -s -X POST -H 'Content-Type: application/json' \
       -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"$PROVEN_BLOCK\",\"$PROVEN_BLOCK\"],\"id\":68}" \
       http://localhost:8080 | jq -r ".result")

     echo "Sync Proof:"
     echo "$SYNC_PROOF"
   fi
   ```

4. **Validator Registration**:
   ```bash
   # Register as validator on Sepolia testnet
   aztec add-l1-validator \
     --l1-rpc-urls RPC_URL \
     --private-key your-private-key \
     --attester your-validator-address \
     --proposer-eoa your-validator-address \
     --proposer-eoa your-validator-address \
     --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
     --l1-chain-id 11155111
   ```

---

**One command. Complete setup. Start validating! 🚀**
