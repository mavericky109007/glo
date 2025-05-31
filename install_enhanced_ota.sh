#!/bin/bash

# Install Enhanced OTA Components
echo "=== Installing Enhanced OTA Components ==="

# The script was originally designed for a different directory structure.
# Adjusting to work from the current directory: /home/tetrixcorps/Desktop/glo

# Install additional Python dependencies for enhanced OTA
echo "Installing enhanced OTA dependencies..."
pip3 install smpplib pycrypto pyscard

# Install Java Card Development Kit for applet development
echo "Installing Java Card Development Kit..."
# Navigate to the repos directory which is now in the current location
cd repos
wget https://www.oracle.com/java/technologies/javacard-sdk-downloads.html
# Note: Manual download required due to Oracle licensing
# Navigate back to the main directory
cd ..

# Install additional SIM tools
echo "Installing additional SIM card tools..."
# Clone pysim into the current directory
git clone https://github.com/osmocom/pysim.git
# Navigate into the cloned pysim directory
cd pysim
pip3 install -r requirements.txt
pip3 install . --user
# Navigate back to the main directory
cd ..

echo "Enhanced OTA components installation complete!"
