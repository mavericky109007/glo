#!/bin/bash

# OTA SMS Testing Environment Setup Script - Fixed Package Dependencies
# This script handles package variations across different Ubuntu versions

set -e

echo "=== OTA SMS Testing Environment Setup (Fixed Dependencies) ==="
echo "This will install all components with proper package alternatives"

# Create base directory structure
mkdir -p ~/ota-testing/{repos,configs,scripts,logs}
cd ~/ota-testing

# Update system and fix broken packages
echo "Updating system packages and fixing dependencies..."
sudo apt update
sudo apt --fix-broken install -y
sudo apt upgrade -y

# Function to try installing packages with alternatives
install_with_alternatives() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        if ! sudo apt install -y "$package"; then
            echo "Warning: Could not install $package, trying alternatives..."
        fi
    done
}

# Install core prerequisites that should work on all systems
echo "Installing core prerequisites..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    pkg-config \
    autoconf \
    automake \
    libtool \
    python3-dev \
    python3-pip \
    python3-setuptools \
    tmux

# Install development libraries with error handling
echo "Installing development libraries with alternatives..."

# Handle cppunit variations
echo "Installing cppunit..."
if ! sudo apt install -y libcppunit-dev; then
    echo "Trying alternative cppunit packages..."
    sudo apt install -y libcppunit-1.15-0 || \
    sudo apt install -y libcppunit-1.13-0 || \
    echo "Warning: Could not install cppunit - some tests may not work"
fi

# Handle GPS library variations  
echo "Installing GPS libraries..."
if ! sudo apt install -y libgps-dev; then
    echo "Trying alternative GPS packages..."
    sudo apt install -y libgps28 libgps-dev || \
    sudo apt install -y libgps22 libgps-dev || \
    echo "Warning: Could not install GPS libraries"
fi

# Install other dependencies with fallbacks
echo "Installing remaining dependencies..."
sudo apt install -y \
    libpcsclite-dev \
    libtalloc-dev \
    libortp-dev \
    libsctp-dev \
    libmnl-dev \
    libdbi-dev \
    libdbd-sqlite3 \
    libsqlite3-dev \
    sqlite3 \
    libc-ares-dev \
    libfftw3-dev \
    libmbedtls-dev \
    libboost-program-options-dev \
    libconfig++-dev \
    swig \
    doxygen \
    libboost-all-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libudev-dev \
    libfftw3-bin \
    libfftw3-doc \
    ncurses-bin \
    cpufrequtils \
    python3-numpy \
    python3-scipy \
    python3-docutils \
    libfontconfig1-dev \
    libxrender-dev \
    libpulse-dev \
    g++ \
    libgsl-dev \
    libxi-dev \
    gtk2-engines-pixbuf \
    r-base-dev \
    python3-tk \
    libasound2-dev \
    libzmq3-dev \
    libzmq5 \
    python3-requests \
    python3-sphinx \
    libcomedi-dev \
    python3-zmq

# Handle ncurses (system will auto-select appropriate version)
sudo apt install -y libncurses-dev || sudo apt install -y libncurses5-dev

# Handle orc library (system will auto-select appropriate version)  
sudo apt install -y liborc-0.4-dev || sudo apt install -y liborc-dev

# Install additional tools
echo "Installing additional development tools..."
sudo apt install -y \
    flex \
    bison \
    ninja-build \
    meson \
    expect

cd repos

echo "Setup complete! Package dependency issues resolved." 