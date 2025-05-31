#!/bin/bash

# Docker troubleshooting script
echo "=== Docker Environment Troubleshooting ==="

# Determine compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: No Docker Compose found"
    exit 1
fi

echo "Using compose command: $COMPOSE_CMD"

# Check Docker status
echo "1. Checking Docker status..."
if systemctl is-active --quiet docker; then
    echo "✓ Docker service is running"
else
    echo "✗ Docker service is not running"
    echo "Try: sudo systemctl start docker"
fi

# Check Docker permissions
echo ""
echo "2. Checking Docker permissions..."
if docker ps &> /dev/null; then
    echo "✓ Docker permissions OK"
else
    echo "✗ Docker permission denied"
    echo "Try: sudo usermod -aG docker $USER && newgrp docker"
fi

# Check compose file
echo ""
echo "3. Checking compose file..."
if [ -f "docker-compose.yml" ]; then
    echo "✓ docker-compose.yml found"
    if $COMPOSE_CMD config &> /dev/null; then
        echo "✓ docker-compose.yml is valid"
    else
        echo "✗ docker-compose.yml has errors:"
        $COMPOSE_CMD config
    fi
else
    echo "✗ docker-compose.yml not found"
fi

# Check container status
echo ""
echo "4. Checking container status..."
$COMPOSE_CMD ps

# Check logs
echo ""
echo "5. Recent logs:"
$COMPOSE_CMD logs --tail=20

# Check disk space
echo ""
echo "6. Checking disk space..."
df -h

# Check available memory
echo ""
echo "7. Checking memory..."
free -h

echo ""
echo "=== Troubleshooting Complete ===" 