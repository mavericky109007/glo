#!/bin/bash

echo "=== Complete Build and Verification Pipeline ==="

# Build the Docker image
echo "Step 1: Building Docker image..."
if docker build -t ota-testing:latest . --progress=plain; then
    echo "✅ Docker build completed successfully"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Verify the build
echo ""
echo "Step 2: Verifying build..."
./scripts/verify-docker-build.sh

# Test specific functionality
echo ""
echo "Step 3: Testing specific functionality..."
./scripts/verify-components.sh

# Performance check
echo ""
echo "Step 4: Performance check..."
echo "Image size:"
docker images ota-testing:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo "Container resource usage test:"
docker run --rm ota-testing:latest bash -c "
echo 'CPU cores available:' \$(nproc)
echo 'Memory available:' \$(free -h | grep Mem | awk '{print \$2}')
echo 'Disk space in /opt:' \$(df -h /opt | tail -1 | awk '{print \$4}')
"

echo ""
echo "=== Build and Verification Pipeline Complete ===" 