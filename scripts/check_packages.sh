#!/bin/bash

# Package availability checker
echo "=== Checking Package Availability ==="

# Function to check if package exists
check_package() {
    local package=$1
    if apt-cache show "$package" >/dev/null 2>&1; then
        echo "✓ $package - Available"
        return 0
    else
        echo "✗ $package - Not found"
        return 1
    fi
}

# Function to find alternatives
find_alternatives() {
    local search_term=$1
    echo "Searching for alternatives to $search_term:"
    apt-cache search "$search_term" | head -5
    echo ""
}

echo "Checking problematic packages..."

# Check cppunit
if ! check_package "libcppunit-1.14-0"; then
    find_alternatives "cppunit"
fi

# Check GPS libraries
if ! check_package "libgps23"; then
    find_alternatives "libgps"
fi

# Check ncurses
if ! check_package "libncurses5-dev"; then
    find_alternatives "ncurses"
fi

# Check orc
if ! check_package "liborc-0.4-0"; then
    find_alternatives "liborc"
fi

echo "=== System Information ==="
echo "Ubuntu Version:"
lsb_release -a 2>/dev/null || cat /etc/os-release

echo ""
echo "Architecture:"
dpkg --print-architecture

echo ""
echo "Available Repositories:"
grep -h "^deb " /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null | sort -u 