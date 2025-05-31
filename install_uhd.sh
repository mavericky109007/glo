#!/bin/bash

# Install UHD for USRP B210
echo "=== Installing UHD ==="

cd ~/ota-testing/repos

# Clone and build UHD
git clone https://github.com/EttusResearch/uhd
cd uhd/host
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
sudo ldconfig

# Test installation
echo "Testing UHD installation..."
sudo uhd_find_devices

cd ~/ota-testing/repos
echo "UHD installation complete!" 