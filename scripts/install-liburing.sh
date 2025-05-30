#!/bin/bash

echo "=== Installing liburing dependency ==="

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
echo "Ubuntu version: $UBUNTU_VERSION"

# Try package manager first
if apt-cache show liburing-dev >/dev/null 2>&1; then
    echo "Installing liburing-dev from package manager..."
    sudo apt update
    sudo apt install -y liburing-dev
else
    echo "liburing-dev not available in repositories, building from source..."
    
    # Install build dependencies
    sudo apt update
    sudo apt install -y build-essential git
    
    # Clone and build liburing
    cd /tmp
    git clone https://github.com/axboe/liburing.git
    cd liburing
    
    # Configure and build
    ./configure --prefix=/usr/local
    make -j$(nproc)
    sudo make install
    
    # Update library cache
    sudo ldconfig
    
    # Create pkg-config file
    sudo tee /usr/local/lib/pkgconfig/liburing.pc > /dev/null << EOF
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: liburing
Description: Linux-native io_uring I/O access library
Version: 2.4
Libs: -L\${libdir} -luring
Cflags: -I\${includedir}
EOF
    
    # Update PKG_CONFIG_PATH
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
    echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
    
    cd /
    rm -rf /tmp/liburing
fi

# Verify installation
echo ""
echo "Verifying liburing installation..."
if pkg-config --exists liburing; then
    echo "✅ liburing successfully installed: $(pkg-config --modversion liburing)"
else
    echo "❌ liburing installation failed"
    exit 1
fi 