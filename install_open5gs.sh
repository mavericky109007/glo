#!/bin/bash

# Install Open5GS
echo "=== Installing Open5GS ==="

cd ~/ota-testing/repos

# Install MongoDB
echo "Installing MongoDB..."
sudo apt-get install gnupg -y
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
   sudo gpg --yes -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Setup TUN device
echo "Setting up TUN device..."
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip addr add 2001:db8:cafe::1/48 dev ogstun
sudo ip link set ogstun up

# Install Open5GS dependencies
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build \
    build-essential flex bison git cmake libsctp-dev libgnutls28-dev \
    libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev \
    libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libtins-dev libtalloc-dev meson

# Build Open5GS
git clone https://github.com/open5gs/open5gs
cd open5gs
meson build --prefix=`pwd`/install
ninja -C build
cd build
meson test -v
ninja install

cd ~/ota-testing/repos
echo "Open5GS installation complete!"
