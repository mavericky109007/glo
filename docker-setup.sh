#!/bin/bash

# Docker-based OTA Testing Environment Setup
echo "=== Docker-based OTA Testing Environment ==="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Please log out and log back in for Docker permissions to take effect"
    exit 1
fi

# Check if Docker Compose is installed (try both docker-compose and docker compose)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Determine which compose command to use
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: No working Docker Compose found"
    exit 1
fi

echo "Using compose command: $COMPOSE_CMD"

# Create directory structure
mkdir -p {configs,scripts,logs,applets}

# Stop any existing containers
echo "Stopping any existing containers..."
$COMPOSE_CMD down

# Build and start the environment
echo "Building Docker image..."
$COMPOSE_CMD build --no-cache

echo "Starting OTA testing environment..."
$COMPOSE_CMD up -d

echo "Waiting for services to start..."
sleep 15

# Check service status
echo "Checking service status..."
$COMPOSE_CMD ps

# Check logs if services aren't running
if ! $COMPOSE_CMD ps | grep -q "Up"; then
    echo "Some services may not be running. Checking logs..."
    $COMPOSE_CMD logs
fi

echo ""
echo "=== Docker Environment Setup Complete ==="
echo "To access the environment:"
echo "  $COMPOSE_CMD exec ota-testing bash"
echo ""
echo "To view logs:"
echo "  $COMPOSE_CMD logs -f ota-testing"
echo ""
echo "To stop the environment:"
echo "  $COMPOSE_CMD down"
echo ""
echo "To rebuild if needed:"
echo "  $COMPOSE_CMD build --no-cache" 