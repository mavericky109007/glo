#!/bin/bash

echo "=== Checking Build Dependencies ==="

# Check if liburing is available
echo "1. Checking liburing..."
if pkg-config --exists liburing; then
    VERSION=$(pkg-config --modversion liburing)
    echo "✅ liburing found: version $VERSION"
    
    # Check if version is >= 0.7
    if pkg-config --atleast-version=0.7 liburing; then
        echo "✅ liburing version is sufficient (>= 0.7)"
    else
        echo "⚠️  liburing version may be too old (need >= 0.7)"
    fi
else
    echo "❌ liburing not found"
    echo "Install with: sudo apt install liburing-dev"
fi

# Check other critical dependencies
echo ""
echo "2. Checking other dependencies..."

DEPS=("libtalloc-dev" "libpcsclite-dev" "libsctp-dev" "libgnutls28-dev")

for dep in "${DEPS[@]}"; do
    if dpkg -l | grep -q "^ii.*$dep"; then
        echo "✅ $dep installed"
    else
        echo "❌ $dep missing"
    fi
done

# Check Python dependencies
echo ""
echo "3. Checking Python dependencies..."
python3 -c "
import sys
modules = ['mako', 'ruamel.yaml', 'smpplib', 'smartcard']
for module in modules:
    try:
        __import__(module)
        print(f'✅ {module}')
    except ImportError:
        print(f'❌ {module} - install with: pip3 install {module}')
"

echo ""
echo "=== Dependency Check Complete ===" 