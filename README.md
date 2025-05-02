# Aztec Network Alpha Testnet: Sequencer Node Setup

## Hardware Requirements

- **CPU**: 8+ cores
- **RAM**: 16GB minimum
- **Storage**: 100GB+ SSD
- **OS**: Ubuntu Linux

## Quick Start Guide

### 1. Base System Setup

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install essential tools
sudo apt install curl screen htop iptables build-essential git wget jq \
  make gcc nano tmux libssl-dev libleveldb-dev clang unzip -y
```

### 2. Docker Setup

```bash
# Clean existing Docker installations
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove $pkg -y
done

# Set up Docker repository
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Configure Docker service
sudo systemctl enable docker
sudo systemctl restart docker
```

### 3. Install Aztec CLI

```bash
# Install Aztec tools
bash -i <(curl -s https://install.aztec.network)
source ~/.bash_profile

# Verify installation
aztec

# Update to Alpha testnet
aztec-up alpha-testnet
```

### 4. Network Configuration

#### Required External Services

- Ethereum Sepolia RPC endpoint (from Ankr or Alchemy)
- Sepolia Beacon RPC endpoint (from Ankr or use `https://rpc.drpc.org/eth/sepolia/beacon`)
- Ethereum wallet with Sepolia ETH

### 5. Launch Sequencer

```bash
# Get server public IP
SERVER_IP=$(curl -s ipv4.icanhazip.com)
echo "Your server IP: $SERVER_IP"

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 40400/tcp
sudo ufw allow 8080/tcp
sudo ufw --force enable
```

```bash
# Create persistent session
screen -S aztec

# Start sequencer (replace placeholders with your actual values)
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls YOUR_SEPOLIA_RPC_URL \
  --l1-consensus-host-urls YOUR_BEACON_RPC_URL \
  --sequencer.validatorPrivateKey 0xYOUR_PRIVATE_KEY \
  --sequencer.coinbase 0xYOUR_ETH_ADDRESS \
  --p2p.p2pIp $SERVER_IP

# To detach from screen: Ctrl+A, D
# To reattach: screen -r aztec
```

### 6. Register as Validator

After your node is synced:

```bash
# Get latest proven block
BLOCK=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
  http://localhost:8080 | jq -r ".result.proven.number")
echo "Latest proven block: $BLOCK"

# Generate proof
PROOF=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"$BLOCK\",\"$BLOCK\"],\"id\":67}" \
  http://localhost:8080 | jq -r ".result")
echo "$PROOF"
```

### 7. Discord Registration

1. Join Aztec Network Discord [https://discord.gg/aztec]
2. Go to the `operators| start-here` channel
3. Run the command `/operator start`
4. Fill in required information:
   - Address: `0xYOUR_ETH_ADDRESS`
   - Block number: Value from the `$BLOCK` variable
   - Proof: Value from the `$PROOF` variable

### 8. On-Chain Registration

```bash
# Register as validator on-chain
aztec add-l1-validator \
  --l1-rpc-urls YOUR_SEPOLIA_RPC_URL \
  --private-key YOUR_PRIVATE_KEY \
  --attester 0xYOUR_ETH_ADDRESS \
  --proposer-eoa 0xYOUR_ETH_ADDRESS \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```


## Maintenance

- **Check node status:**

  ```bash
  screen -r aztec
  ```

- **Update Aztec tools:**
  ```bash
  aztec-up alpha-testnet
  ```
