#!/bin/bash

echo "=== Quick UHD Build Fix ==="

# Stop any running containers
docker-compose down

# Clean up failed builds
docker system prune -f

# Use the optimized build approach
chmod +x scripts/optimize-uhd-build.sh
./scripts/optimize-uhd-build.sh

# Test the build
docker run --rm -it ota-testing:optimized /opt/uhd/verify_uhd.sh 