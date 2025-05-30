#!/bin/bash

echo "=== Docker Compose Verification ==="

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found"
    exit 1
fi

echo "1. Validating docker-compose.yml..."
if docker-compose config >/dev/null 2>&1; then
    echo "✅ docker-compose.yml is valid"
else
    echo "❌ docker-compose.yml has errors"
    docker-compose config
    exit 1
fi

echo ""
echo "2. Building with docker-compose..."
if docker-compose build; then
    echo "✅ docker-compose build successful"
else
    echo "❌ docker-compose build failed"
    exit 1
fi

echo ""
echo "3. Testing service startup..."
docker-compose up -d

# Wait for services to start
sleep 10

echo ""
echo "4. Checking service status..."
docker-compose ps

echo ""
echo "5. Testing container accessibility..."
if docker-compose exec -T ota-testing echo "Container is accessible" >/dev/null 2>&1; then
    echo "✅ Container is accessible"
else
    echo "❌ Container is not accessible"
fi

echo ""
echo "6. Running verification inside container..."
docker-compose exec -T ota-testing /opt/verify_complete.sh

echo ""
echo "7. Cleaning up..."
docker-compose down

echo ""
echo "=== Docker Compose Verification Complete ===" 