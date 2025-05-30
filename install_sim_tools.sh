#!/bin/bash

# Install SIM Tools and Java Card Development Kit
echo "=== Installing SIM Tools ==="

cd ~/ota-testing/repos

# Install Java Development Kit
sudo apt install -y default-jdk

# Clone sim-tools
git clone https://github.com/herlesupreeth/sim-tools.git

# Clone hello-stk sample applet
git clone https://gitea.osmocom.org/sim-card/hello-stk
cd hello-stk/hello-stk
make
cd ~/ota-testing/repos

# Install GlobalPlatformPro
echo "Installing GlobalPlatformPro..."
cd ~/ota-testing
wget https://github.com/martinpaljak/GlobalPlatformPro/releases/download/v21.05.25/gp.jar
echo '#!/bin/bash' > gp
echo 'java -jar '$PWD/gp.jar' "$@"' >> gp
chmod +x gp
sudo ln -s $PWD/gp /usr/local/bin/gp

# Install Python SMPP library
pip3 install smpplib

cd ~/ota-testing/repos
echo "SIM Tools installation complete!" 