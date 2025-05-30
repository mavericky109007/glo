#!/bin/bash

# Setup subscriber in both HSS and HLR
echo "=== Setting up test subscriber ==="

IMSI=${1:-123456789012345}
MSISDN=${2:-12345678900}

echo "Setting up subscriber with IMSI: $IMSI, MSISDN: $MSISDN"

# Setup in Open5GS HSS (via web interface or direct DB)
echo "Please setup subscriber in Open5GS HSS via web interface at http://localhost:3000"
echo "IMSI: $IMSI"
echo "MSISDN: $MSISDN"

# Setup in OsmoHLR
echo "Setting up in OsmoHLR..."
expect << EOF
spawn telnet 127.0.0.1 4258
expect "OsmoHLR>"
send "enable\r"
expect "OsmoHLR#"
send "subscriber imsi $IMSI create\r"
expect "OsmoHLR#"
send "subscriber imsi $IMSI update msisdn $MSISDN\r"
expect "OsmoHLR#"
send "show subscribers all\r"
expect "OsmoHLR#"
send "exit\r"
EOF

echo "Subscriber setup complete!" 