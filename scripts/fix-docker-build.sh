#!/bin/bash

echo "=== Fixing Docker Build Issues ==="

# Check if OTAapplet directory exists
if [ ! -d "OTAapplet" ]; then
    echo "Creating OTAapplet directory..."
    mkdir -p OTAapplet
    echo "# OTA Applet Directory" > OTAapplet/README.md
    echo "Place your OTA applet implementations here" >> OTAapplet/README.md
    echo "✅ OTAapplet directory created"
else
    echo "✅ OTAapplet directory already exists"
fi

# Clean up any failed builds
echo "Cleaning up Docker build cache..."
docker system prune -f

# Rebuild with the fixed Dockerfile
echo "Building with fixed Dockerfile..."
docker build --no-cache -t ota-testing:fixed .

echo "✅ Docker build fix complete!" 