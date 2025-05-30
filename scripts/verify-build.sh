#!/bin/bash

# Build verification script
echo "=== Verifying OTA Testing Environment Build ==="

# Check Python dependencies
echo "1. Checking Python dependencies..."
python3 -c "
import sys
modules = ['smartcard', 'smpplib', 'mako', 'ruamel.yaml', 'Crypto']
for module in modules:
    try:
        __import__(module)
        print(f'✓ {module}')
    except ImportError:
        print(f'✗ {module} - MISSING')
        sys.exit(1)
"

# Check system binaries
echo ""
echo "2. Checking system binaries..."
binaries=("cmake" "make" "git" "tmux" "java" "swig")
for binary in "${binaries[@]}"; do
    if command -v "$binary" &> /dev/null; then
        echo "✓ $binary"
    else
        echo "✗ $binary - MISSING"
    fi
done

# Check UHD installation
echo ""
echo "3. Checking UHD installation..."
if command -v uhd_find_devices &> /dev/null; then
    echo "✓ UHD binaries found"
    uhd_find_devices 2>/dev/null && echo "✓ UHD working" || echo "⚠ UHD installed but no devices found (normal)"
else
    echo "✗ UHD not found"
fi

# Check Open5GS installation
echo ""
echo "4. Checking Open5GS installation..."
if command -v open5gs-mmed &> /dev/null; then
    echo "✓ Open5GS MME found"
else
    echo "✗ Open5GS MME not found"
fi

# Check Osmocom installation
echo ""
echo "5. Checking Osmocom installation..."
if command -v osmo-msc &> /dev/null; then
    echo "✓ OsmoMSC found"
else
    echo "✗ OsmoMSC not found"
fi

if command -v osmo-hlr &> /dev/null; then
    echo "✓ OsmoHLR found"
else
    echo "✗ OsmoHLR not found"
fi

echo ""
echo "=== Build Verification Complete ===" 