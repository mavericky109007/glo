#!/bin/bash

# Minimal installation focusing on core OTA functionality
echo "=== Minimal OTA Testing Environment Installation ==="

# Update system
sudo apt update

# Install only essential packages
echo "Installing essential packages only..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    python3-dev \
    python3-pip \
    libssl-dev \
    libusb-1.0-0-dev \
    pkg-config \
    autoconf \
    automake \
    libtool \
    tmux

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install --user smpplib pycrypto

# Create directory structure
mkdir -p ~/ota-testing/{repos,configs,scripts,logs}
cd ~/ota-testing/repos

# Clone only essential repositories
echo "Cloning essential repositories..."
git clone https://github.com/ryantheelder/OTAapplet.git
git clone https://github.com/herlesupreeth/sim-tools.git

echo "Minimal installation complete!"
echo "This provides basic OTA SMS functionality without full network simulation." 