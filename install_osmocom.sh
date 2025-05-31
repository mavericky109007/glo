#!/bin/bash

# Install Osmocom components
echo "=== Installing Osmocom Components ==="

cd ~/ota-testing/repos

# Install libosmocore
echo "Installing libosmocore..."
git clone https://gitea.osmocom.org/osmocom/libosmocore.git
cd libosmocore
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install libosmo-abis
echo "Installing libosmo-abis..."
git clone https://gitea.osmocom.org/osmocom/libosmo-abis.git
cd libosmo-abis
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install libosmo-netif
echo "Installing libosmo-netif..."
git clone https://github.com/osmocom/libosmo-netif.git
cd libosmo-netif
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install libosmo-sccp
echo "Installing libosmo-sccp..."
git clone https://github.com/osmocom/libosmo-sccp.git
cd libosmo-sccp
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install OsmoHLR
echo "Installing OsmoHLR..."
git clone https://github.com/osmocom/osmo-hlr.git
cd osmo-hlr
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install libsmpp34
echo "Installing libsmpp34..."
git clone https://github.com/osmocom/libsmpp34.git
cd libsmpp34
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install libasn1c
echo "Installing libasn1c..."
git clone https://github.com/osmocom/libasn1c.git
cd libasn1c
autoreconf -i
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

# Install OsmoMSC
echo "Installing OsmoMSC..."
git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-msc
cd osmo-msc
autoreconf -i
./configure --enable-smpp
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

echo "Osmocom components installation complete!" 