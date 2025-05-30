#!/bin/bash

echo "=== Interactive Docker Build Verification ==="

IMAGE_NAME="ota-testing:latest"

# Check if image exists
if ! docker images | grep -q "ota-testing"; then
    echo "❌ Docker image not found. Please build first with:"
    echo "   docker build -t ota-testing:latest ."
    exit 1
fi

echo "✅ Docker image found. Starting interactive verification..."
echo ""
echo "Available verification options:"
echo "1. Quick verification (automated)"
echo "2. Full component check"
echo "3. Interactive shell access"
echo "4. Build logs analysis"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "Running quick verification..."
        docker run --rm "$IMAGE_NAME" /opt/verify_complete.sh
        ;;
    2)
        echo "Running full component check..."
        ./scripts/verify-components.sh
        ;;
    3)
        echo "Starting interactive shell..."
        echo "Type 'exit' to return to host"
        docker run --rm -it "$IMAGE_NAME" /bin/bash
        ;;
    4)
        echo "Analyzing recent build logs..."
        docker history "$IMAGE_NAME" --no-trunc
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac 