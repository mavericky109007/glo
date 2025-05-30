#!/bin/bash

echo "=== Optimizing UHD Build Process ==="

# Check Docker version for IPv6 support
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "Docker version: $DOCKER_VERSION"

# Check if Docker supports IPv6 (version 26.0.0+)
if [ "$(printf '%s\n' "26.0.0" "$DOCKER_VERSION" | sort -V | head -n1)" = "26.0.0" ]; then
    echo "✅ Docker version supports IPv6"
else
    echo "⚠️  Docker version may have IPv6 issues. Consider upgrading to 26.0.0+"
fi

# Pre-download UHD images to avoid timeout during build
echo "Pre-downloading UHD images..."
mkdir -p ./uhd-images
cd ./uhd-images

# Download common USRP images
wget -c https://files.ettus.com/e3xx_e310_fpga_default-g6bea23dc.zip || echo "E310 image download failed"
wget -c https://files.ettus.com/usrp_n200_fpga_default-g6bea23dc.zip || echo "N200 image download failed"
wget -c https://files.ettus.com/usrp_n210_fpga_default-g6bea23dc.zip || echo "N210 image download failed"

cd ..

# Build with optimizations
echo "Building with optimizations..."
docker build \
    --build-arg MAKEWIDTH=$(nproc) \
    --build-arg UHD_TAG=v4.6.0.0 \
    --network=host \
    --progress=plain \
    -t ota-testing:optimized . 