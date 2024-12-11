#!/bin/bash

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

# Pastikan figlet diinstal
if ! command -v figlet &> /dev/null; then
    echo "Installing figlet for large text output..."
    sudo apt install figlet -y
fi

show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

# Sambutan dengan teks besar
echo -e "${PINK}${BOLD}Welcome to the Nexus CLI installation by snoopfear!${NORMAL}"
sleep 3  # Pause 3 detik

# Gunakan figlet untuk teks besar
figlet -f slant "Nexus CLI"  # Menampilkan teks besar

echo -e "${PINK}${BOLD}Starting the installation process...\n${NORMAL}"

NEXUS_HOME="$HOME/.nexus"
PROVER_ID="Ylqcau8ZsKSYY0rpsApcc8RuGRe2"

# Pastikan direktori $NEXUS_HOME ada
if [ ! -d "$NEXUS_HOME" ]; then
    show "Creating Nexus home directory..." "progress"
    mkdir -p "$NEXUS_HOME"
fi

# Simpan prover-id di file
show "Saving Prover ID to $NEXUS_HOME/prover-id..." "progress"
echo "$PROVER_ID" > $NEXUS_HOME/prover-id
show "Prover ID saved to $NEXUS_HOME/prover-id."

# Update sistem dan instal dependensi
show "Updating and upgrading system..." "progress"
if ! sudo apt update && sudo apt upgrade -y; then
    show "Failed to update and upgrade system." "error"
    exit 1
fi

show "Installing essential packages..." "progress"
if ! sudo apt install build-essential pkg-config libssl-dev git-all -y; then
    show "Failed to install essential packages." "error"
    exit 1
fi

show "Installing protobuf compiler..." "progress"
if ! sudo apt install -y protobuf-compiler; then
    show "Failed to install protobuf compiler." "error"
    exit 1
fi

show "Installing cargo (Rust package manager)..." "progress"
if ! sudo apt install cargo -y; then
    show "Failed to install cargo." "error"
    exit 1
fi

# Periksa apakah rustup sudah terpasang
if ! command -v rustup &> /dev/null; then
    show "Installing Rust..." "progress"
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        show "Failed to install Rust." "error"
        exit 1
    fi
else
    show "Rust is already installed."
fi

# Setup Rust
source $HOME/.cargo/env
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
rustup update

show "Updating package list..." "progress"
if ! sudo apt update; then
    show "Failed to update package list." "error"
    exit 1
fi

if ! command -v git &> /dev/null; then
    show "Git is not installed. Installing git..." "progress"
    if ! sudo apt install git -y; then
        show "Failed to install git." "error"
        exit 1
    fi
else
    show "Git is already installed."
fi

# Clone repository Nexus-XYZ
if [ -d "$HOME/network-api" ]; then
    show "Deleting existing repository..." "progress"
    rm -rf "$HOME/network-api"
fi

sleep 3

show "Cloning Nexus-XYZ network API repository..." "progress"
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    show "Failed to clone the repository." "error"
    exit 1
fi

cd $HOME/network-api/clients/cli

show "Installing required dependencies..." "progress"
if ! sudo apt install pkg-config libssl-dev -y; then
    show "Failed to install dependencies." "error"
    exit 1
fi

show "Running Nexus manually in the background..." "progress"
nohup $HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz > nexus.log 2>&1 &

show "Nexus Prover installation complete and running in the background!"
sleep 3  # Pause 3 detik

# Tampilkan log
show "Displaying logs..." "progress"
tail -f nexus.log
