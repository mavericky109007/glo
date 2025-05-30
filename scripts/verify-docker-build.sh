#!/bin/bash

echo "=== Docker Build Verification ==="

# Check if the image was built successfully
IMAGE_NAME="ota-testing"
echo "1. Checking if Docker image exists..."

if docker images | grep -q "$IMAGE_NAME"; then
    echo "✅ Docker image '$IMAGE_NAME' found"
    
    # Get image details
    IMAGE_ID=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | grep "$IMAGE_NAME")
    echo "📋 Image details:"
    echo "$IMAGE_ID"
else
    echo "❌ Docker image '$IMAGE_NAME' not found"
    echo "Build may have failed or image name is different"
    exit 1
fi

# Check image size (should be reasonable, not too small)
IMAGE_SIZE=$(docker images --format "{{.Size}}" "$IMAGE_NAME:latest" 2>/dev/null)
echo "📏 Image size: $IMAGE_SIZE"

# Verify image can start
echo ""
echo "2. Testing if container can start..."
if docker run --rm "$IMAGE_NAME:latest" echo "Container startup test successful" >/dev/null 2>&1; then
    echo "✅ Container can start successfully"
else
    echo "❌ Container failed to start"
    exit 1
fi

echo ""
echo "3. Running comprehensive verification..."
# Run the built-in verification script
docker run --rm "$IMAGE_NAME:latest" /opt/verify_complete.sh

echo ""
echo "=== Docker Build Verification Complete ===" 