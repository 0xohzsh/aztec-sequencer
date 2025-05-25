#!/bin/bash

# Interactive Aztec Sequencer Setup Script
# This script sets up an Aztec sequencer with Docker and interactive configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Banner function with ASCII art
show_banner() {
    echo -e "${CYAN}"
    echo "╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                             ║"
    echo "║    ██████╗ ██╗  ██╗ ██████╗ ██╗  ██╗███████╗███████╗██╗  ██╗                ║"
    echo "║   ██╔═████╗╚██╗██╔╝██╔═══██╗██║  ██║╚══███╔╝██╔════╝██║  ██║                ║"
    echo "║   ██║██╔██║ ╚███╔╝ ██║   ██║███████║  ███╔╝ ███████╗███████║                ║"
    echo "║   ████╔╝██║ ██╔██╗ ██║   ██║██╔══██║ ███╔╝  ╚════██║██╔══██║                ║"
    echo "║   ╚██████╔╝██╔╝ ██╗╚██████╔╝██║  ██║███████╗███████║██║  ██║                ║"
    echo "║    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝                ║"
    echo "║                                                                             ║"
    echo -e "║                      ${MAGENTA}🚀 Aztec Sequencer Setup 🚀${CYAN}                           ║"
    echo "║                                                                             ║"
    echo -e "║                     ${YELLOW}Follow us: https://x.com/0xohzsh${CYAN}                         ║"
    echo "║                                                                             ║"
    echo "║               Set up your Aztec sequencer with Docker & Web3               ║"
    echo "║                    One-click deployment, zero hassle                       ║"
    echo "║                                                                             ║"
    echo "╚═════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to prompt for user input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local value

    if [ -n "$default" ]; then
        echo -e "${CYAN}$prompt [default: $default]:${NC}"
    else
        echo -e "${CYAN}$prompt:${NC}"
    fi

    read -r value

    if [ -z "$value" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Detect operating system
detect_os() {
    if [[ -f /etc/debian_version ]] || command -v apt &> /dev/null; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]] || command -v yum &> /dev/null; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        print_status "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Install Docker if not present
install_docker() {
    if command -v docker &> /dev/null; then
        print_status "Docker is already installed"
        return 0
    fi

    print_header "Installing Docker"

    local os=$(detect_os)

    if [[ "$os" == "debian" ]]; then
        # Debian/Ubuntu installation
        print_status "Installing Docker on Debian/Ubuntu..."

        # Update package index
        sudo apt-get update

        # Install required packages
        sudo apt-get install -y ca-certificates curl

                # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings

        # Detect if Ubuntu or Debian and use appropriate GPG and repo
        if grep -qi ubuntu /etc/os-release; then
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        else
            sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
              $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi

        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    elif [[ "$os" == "redhat" ]]; then
        # RHEL/CentOS installation
        print_status "Installing Docker on RHEL/CentOS..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        print_error "Unsupported operating system for automatic Docker installation"
        print_status "Please install Docker manually: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Set Docker socket permissions
    print_status "Setting Docker socket permissions..."
    sudo chmod 666 /var/run/docker.sock

    # Add current user to docker group
    sudo usermod -aG docker $USER

    print_status "Docker installation completed!"
    print_warning "You may need to log out and log back in for group changes to take effect"
}

# Configure firewall if UFW is enabled
configure_firewall() {
    print_header "Configuring Firewall"

    # Check if UFW is installed and enabled
    if command -v ufw &> /dev/null; then
        local ufw_status=$(sudo ufw status | head -1)

        if [[ "$ufw_status" == *"Status: active"* ]]; then
            print_status "UFW firewall is active, configuring ports..."
            sudo ufw allow ssh
            # Allow required ports for Aztec sequencer
            print_status "Opening port 40400 (P2P TCP/UDP)..."
            sudo ufw allow 40400

            print_status "Opening port 40500 (Additional P2P)..."
            sudo ufw allow 40500

            print_status "Opening port 8080 (Aztec Node HTTP)..."
            sudo ufw allow 8080

            print_status "Firewall configuration completed!"

        elif [[ "$ufw_status" == *"Status: inactive"* ]]; then
            print_warning "UFW firewall is installed but inactive"
            echo -e "${CYAN}Do you want to enable UFW and configure ports? [y/N]:${NC}"
            read -r enable_ufw

            if [[ "$enable_ufw" =~ ^[Yy]$ ]]; then
                print_status "Enabling UFW and configuring ports..."
                sudo ufw --force enable
                sudo ufw allow 40400
                sudo ufw allow 40500
                sudo ufw allow 8080
                sudo ufw allow ssh
                print_status "UFW enabled and ports configured!"
            else
                print_warning "UFW not enabled. Make sure ports 40400, 40500, and 8080 are accessible."
            fi
        fi
    else
        print_warning "UFW not installed. Make sure ports 40400, 40500, and 8080 are accessible."
    fi
}

# Get server IP
get_server_ip() {
    local ip=$(hostname -I | awk '{print $1}')
    echo "$ip"
}

# Create Aztec sequencer directory and files
setup_aztec_sequencer() {
    print_header "Setting up Aztec Sequencer"

    # Create aztec-sequencer directory
    print_status "Creating aztec-sequencer directory..."
    mkdir -p aztec-sequencer
    cd aztec-sequencer

    # Get server IP for default P2P_IP
    local server_ip=$(get_server_ip)
    print_status "Detected server IP: $server_ip"

    print_header "Aztec Sequencer Configuration"
    echo -e "${YELLOW}Please provide the following configuration details:${NC}"
    echo ""

    # Interactive prompts for .env configuration
    ETHEREUM_RPC_URL=$(prompt_input "Enter Ethereum RPC URL (e.g., https://mainnet.infura.io/v3/YOUR_PROJECT_ID)")
    CONSENSUS_BEACON_URL=$(prompt_input "Enter Consensus Beacon URL (e.g., https://beacon-nd-123-456-789.p2pify.com)")
    VALIDATOR_PRIVATE_KEY=$(prompt_input "Enter Validator Private Key (with 0x prefix)")
    COINBASE=$(prompt_input "Enter Coinbase address (e.g., 0x1234...)")
    P2P_IP=$(prompt_input "Enter P2P IP address" "$server_ip")

    # Create .env file
    print_status "Creating .env file..."
    cat > .env << EOF
# Aztec Sequencer Configuration
ETHEREUM_RPC_URL=$ETHEREUM_RPC_URL
CONSENSUS_BEACON_URL=$CONSENSUS_BEACON_URL
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
COINBASE=$COINBASE
P2P_IP=$P2P_IP
EOF

    # Create docker-compose.yml file
    print_status "Creating docker-compose.yml file..."
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  aztec-node:
    container_name: aztec-sequencer
    network_mode: host
    image: aztecprotocol/aztec:latest
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: \${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: \${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /data
      VALIDATOR_PRIVATE_KEY: \${VALIDATOR_PRIVATE_KEY}
      COINBASE: \${COINBASE}
      P2P_IP: \${P2P_IP}
      LOG_LEVEL: info
      GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS: 0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
    volumes:
      - $HOME/.aztec/alpha-testnet/data/:/data
EOF

    print_status "Configuration files created successfully!"
    echo ""
    print_status "Created files:"
    echo "  ✓ .env - Environment configuration"
    echo "  ✓ docker-compose.yml - Docker services configuration"
    echo ""
}

# Start Aztec sequencer
start_sequencer() {
    print_header "Starting Aztec Sequencer"

    # Check if docker-compose.yml exists
    if [[ ! -f "docker-compose.yml" ]]; then
        print_error "docker-compose.yml not found. Please run setup first."
        exit 1
    fi

    # Pull latest images
    print_status "Pulling latest Aztec images..."
    docker compose pull

    # Start services
    print_status "Starting Aztec sequencer services..."
    docker compose up -d

    # Show status
    echo ""
    print_status "Aztec sequencer is starting up..."
    docker compose ps

    echo ""
    print_status "Sequencer URLs:"
    echo "  🌐 Aztec Node: http://localhost:8080"
    echo "  📊 P2P: ${P2P_IP}:40400"

    echo ""
    print_status "To view logs:"
    echo "  docker compose logs -f aztec-node"
    echo "  docker logs -f aztec-sequencer"

    echo ""
    print_status "To stop the sequencer:"
    echo "  docker compose down"
}

# Main execution
main() {
    # Clear screen and show banner
    clear
    show_banner

    # Check if running as root
    check_root

    # Install Docker if needed
    install_docker

    # Configure firewall
    configure_firewall

    # Setup Aztec sequencer
    setup_aztec_sequencer

    # Ask if user wants to start immediately
    echo ""
    echo -e "${CYAN}Do you want to start the Aztec sequencer now? [Y/n]:${NC}"
    read -r start_now

    if [[ -z "$start_now" || "$start_now" =~ ^[Yy]$ ]]; then
        start_sequencer

        print_header "Setup Complete!"
        print_status "🎉 Aztec sequencer setup completed successfully!"
        print_status "Your sequencer is now running and ready to validate transactions."
        print_warning "Make sure your firewall allows connections on the configured ports."
        echo ""
        print_status "Happy validating! 🚀"
    else
        print_header "Setup Complete!"
        print_status "🎉 Aztec sequencer setup completed successfully!"
        print_status "To start your sequencer later, run:"
        echo "  cd aztec-sequencer && docker compose up -d"
        echo ""
        print_status "Happy validating! 🚀"
    fi
}

# Run main function
main "$@"
