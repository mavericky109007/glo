#!/bin/bash

echo "=== Building OTA Environment with All Dependencies ==="

# Check and install dependencies first
echo "Step 1: Checking dependencies..."
chmod +x scripts/check-dependencies.sh
./scripts/check-dependencies.sh

# Install liburing if missing
if ! pkg-config --exists liburing; then
    echo "Step 2: Installing liburing..."
    chmod +x scripts/install-liburing.sh
    ./scripts/install-liburing.sh
fi

# Build Docker image
echo "Step 3: Building Docker image..."
docker build \
    --build-arg MAKEWIDTH=$(nproc) \
    --build-arg UHD_TAG=v4.6.0.0 \
    --progress=plain \
    -t ota-testing:complete .

# Verify the build
echo "Step 4: Verifying build..."
docker run --rm ota-testing:complete /opt/verify_complete.sh

echo "✅ Build complete with all dependencies!" 