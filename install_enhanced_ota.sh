#!/bin/bash

# Install Enhanced OTA Components
echo "=== Installing Enhanced OTA Components ==="

cd ~/ota-testing/repos

# Clone ryantheelder's OTA implementation for reference
echo "Cloning ryantheelder's OTA implementation..."
git clone https://github.com/ryantheelder/OTAapplet.git
cd OTAapplet

# Copy useful configurations
cp -r configs/* ~/ota-testing/configs/
cp -r smppClient/* ~/ota-testing/scripts/

cd ~/ota-testing

# Install additional Python dependencies for enhanced OTA
echo "Installing enhanced OTA dependencies..."
pip3 install smpplib pycrypto pyscard

# Install Java Card Development Kit for applet development
echo "Installing Java Card Development Kit..."
cd repos
wget https://www.oracle.com/java/technologies/javacard-sdk-downloads.html
# Note: Manual download required due to Oracle licensing

# Install additional SIM tools
echo "Installing additional SIM card tools..."
git clone https://github.com/osmocom/pysim.git
cd pysim
pip3 install -r requirements.txt
python3 setup.py install --user

cd ~/ota-testing/repos
echo "Enhanced OTA components installation complete!" 