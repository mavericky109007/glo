#!/bin/bash

# Setup TUN interface for Open5GS
# This script creates and configures the TUN interface used by Open5GS

echo "Setting up TUN interface for Open5GS..."

# Create TUN interface
ip tuntap add name ogstun mode tun

# Configure IPv4 address
ip addr add 10.45.0.1/16 dev ogstun

# Configure IPv6 address  
ip addr add 2001:db8:cafe::1/48 dev ogstun

# Bring interface up
ip link set ogstun up

echo "TUN interface 'ogstun' configured successfully"
echo "IPv4: 10.45.0.1/16"
echo "IPv6: 2001:db8:cafe::1/48"

# Verify interface is up
ip addr show ogstun
