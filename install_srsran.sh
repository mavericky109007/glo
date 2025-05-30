#!/bin/bash

# Install srsRAN_4G
echo "=== Installing srsRAN_4G ==="

cd ~/ota-testing/repos

git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ..
make -j$(nproc)
make test
sudo make install
srsran_4g_install_configs.sh user

cd ~/ota-testing/repos
echo "srsRAN_4G installation complete!" 