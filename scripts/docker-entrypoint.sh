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
# Start the receive.py script in the background
echo "Starting receive.py script..."
python3 /ota-testing/receive.py &

# Start the Telnyx SMPP Bridge server in the background
echo "Starting Telnyx SMPP Bridge server..."
python3 /ota-testing/scripts/telnyx_smpp_server.py &

# Wait for the SMPP server to be ready
echo "Waiting for SMPP server to be ready on 127.0.0.1:2775..."
timeout=30
for i in $(seq $timeout); do
    if nc -z 127.0.0.1 2775 >/dev/null 2>&1; then
        echo "SMPP server is ready!"
        break
    fi
    if [ $i -eq $timeout ]; then
        echo "Error: SMPP server did not become ready within $timeout seconds."
        exit 1
    fi
    sleep 1
done

if [ "$1" = "bash" ] || [ "$1" = "shell" ]; then
    exec /bin/bash
else
    tail -f /dev/null
fi
