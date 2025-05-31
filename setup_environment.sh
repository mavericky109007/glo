#!/bin/bash

# OTA SMS Testing Environment Setup Script
# This script sets up the complete environment for testing OTA applet installation/deletion

set -e

echo "=== OTA SMS Testing Environment Setup ==="
echo "This will install all components needed for the testing environment"

# Create base directory structure
mkdir -p ~/ota-testing/{repos,configs,scripts,logs}
cd ~/ota-testing

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y build-essential cmake autoconf libtool-bin \
    libpcsclite-dev libtalloc-dev libortp-dev libsctp-dev \
    libmnl-dev libdbi-dev libdbd-sqlite3 libsqlite3-dev sqlite3 libc-ares-dev \
    libfftw3-dev libmbedtls-dev libboost-program-options-dev \
    libconfig++-dev libsctp-dev git swig doxygen libboost-all-dev libtool \
    libusb-1.0-0 libusb-1.0-0-dev libudev-dev libncurses5-dev libfftw3-bin \
    libfftw3-dev libfftw3-doc libcppunit-dev libcppunit-doc \
    ncurses-bin cpufrequtils python3-numpy python3-scipy python3-docutils \
    libfontconfig1-dev libxrender-dev libpulse-dev g++ automake \
    python3-dev libgsl-dev python3-setuptools libxi-dev gtk2-engines-pixbuf \
    r-base-dev python3-tk liborc-0.4-0 liborc-0.4-dev libasound2-dev \
    libzmq3-dev libzmq5 python3-requests python3-sphinx libcomedi-dev \
    python3-zmq libgps-dev gpsd gpsd-clients python3-gps \
    python3-pip tmux

cd repos

echo "Setup complete! Proceeding with component installation..."
