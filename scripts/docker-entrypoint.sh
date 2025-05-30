#!/bin/bash

# Docker container entry point for OTA testing
echo "=== Starting OTA Testing Environment ==="

# Setup TUN interface
echo "Setting up TUN interface..."
/usr/local/bin/setup-tun.sh

# Start MongoDB if not running
if ! pgrep mongod > /dev/null; then
    echo "Starting MongoDB..."
    mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db
fi

# Initialize Open5GS database
echo "Initializing Open5GS database..."
cd /ota-testing/repos/open5gs && \
./misc/db/open5gs-dbctl.py --db_uri=mongodb://mongodb:27017/open5gs add_ue_with_slice \
    001010123456789 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA \
    --slice_num=1 --default_slice

echo "Environment ready!"
echo "Available commands:"
echo "  start-network.sh    - Start all network components"
echo "  setup-subscriber.sh - Setup test subscriber"
echo "  test-ota.py        - Run OTA tests"

# Keep container running
exec "$@" 