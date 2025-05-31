#!/bin/bash
echo "=== Starting OTA Network Components (Fixed) ==="

# Step 1: Kill ALL existing Open5GS processes
echo "Stopping existing Open5GS processes..."
pkill -f open5gs-nrfd
pkill -f open5gs-mmed
pkill -f open5gs-sgwcd
pkill -f open5gs-sgwud
pkill -f open5gs-smfd
pkill -f open5gs-upfd

# Wait for processes to fully terminate
sleep 5

# Step 2: Verify no processes are running
echo "Verifying cleanup..."
REMAINING=$(ps aux | grep open5gs | grep -v grep | wc -l)
if [ $REMAINING -gt 0 ]; then
    echo "Force killing remaining processes..."
    pkill -9 -f open5gs
    sleep 2
fi

# Step 3: Start services in correct order
echo "Starting Open5GS NRF..."
/usr/local/bin/open5gs-nrfd -c /usr/local/etc/open5gs/nrf.yaml -D &
sleep 2

echo "Starting Open5GS SGW-U..."
/usr/local/bin/open5gs-sgwud -c /usr/local/etc/open5gs/sgwu.yaml -D &
sleep 1

echo "Starting Open5GS UPF..."
/usr/local/bin/open5gs-upfd -c /usr/local/etc/open5gs/upf.yaml -D &
sleep 1

echo "Starting Open5GS SGW-C..."
/usr/local/bin/open5gs-sgwcd -c /usr/local/etc/open5gs/sgwc.yaml -D &
sleep 1

echo "Starting Open5GS SMF..."
/usr/local/bin/open5gs-smfd -c /usr/local/etc/open5gs/smf.yaml -D &
sleep 2

echo "Starting Open5GS MME..."
/usr/local/bin/open5gs-mmed -c /usr/local/etc/open5gs/mme.yaml -D &

sleep 3
echo "Network components started successfully!"
echo "=== Checking Running Processes ==="
ps aux | grep open5gs | grep -v grep
