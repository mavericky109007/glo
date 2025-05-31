#!/bin/bash
echo "=== Starting OTA Testing Environment ==="
echo "Setting up TUN interface..."
if command -v ip >/dev/null 2>&1; then
    if ! ip tuntap list | grep -q ogstun; then
        ip tuntap add name ogstun mode tun
    fi
    ip addr add 10.45.0.1/16 dev ogstun || true
    ip addr add 2001:db8:cafe::1/48 dev ogstun || true
    ip link set ogstun up
    echo "TUN interface configured successfully"
    ip addr show ogstun
else
    echo "Warning: ip command not found"
fi
echo "Waiting for MongoDB to be ready..."
while ! mongosh --host ota-mongodb --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    echo "Waiting for MongoDB connection..."
    sleep 2
done
echo "MongoDB is ready!"
echo "Environment ready!"
echo "Available commands:"
echo "  /ota-testing/scripts/start_network.sh    - Start network components"
echo "  /ota-testing/scripts/setup-subscriber.sh - Setup test subscriber"
if [ "$1" = "bash" ] || [ "$1" = "shell" ]; then
    exec /bin/bash
else
    tail -f /dev/null
fi
