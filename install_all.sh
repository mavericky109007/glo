#!/bin/bash

# Master installation script - Enhanced with ryantheelder's components
echo "=== Enhanced OTA SMS Testing Environment - Complete Setup ==="

# Make all scripts executable
chmod +x setup_environment.sh install_*.sh scripts/*.sh scripts/*.py

# Run installations in order
./setup_environment.sh
./install_uhd.sh
./install_srsran.sh
./install_osmocom.sh
./install_open5gs.sh
./install_sim_tools.sh
./install_enhanced_ota.sh

echo "=== Enhanced Installation Complete! ==="
echo ""
echo "This environment now includes:"
echo "• Comprehensive network simulation (srsRAN, Open5GS, Osmocom)"
echo "• Enhanced OTA client based on ryantheelder's implementation"
echo "• Security testing and vulnerability research tools"
echo "• Educational attack simulation capabilities"
echo ""
echo "Next steps:"
echo "1. Start the network: ./scripts/start_network.sh"
echo "2. Setup subscribers: ./scripts/setup_subscriber.sh [IMSI] [MSISDN]"
echo "3. Test basic OTA: python3 scripts/enhanced_ota_client.py test [MSISDN]"
echo "4. Run comprehensive tests: python3 scripts/comprehensive_ota_test.py [MSISDN]"
echo ""
echo "⚠️  REMEMBER: This is for educational and authorized testing only!" 