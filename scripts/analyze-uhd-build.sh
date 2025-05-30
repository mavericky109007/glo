#!/bin/bash

echo "=== UHD Repository Build Analysis ==="

# Test git clone speed
echo "Testing git clone speed..."
start_time=$(date +%s)

# Test shallow clone first (faster)
timeout 3600 git clone --depth 1 https://github.com/EttusResearch/uhd.git /tmp/uhd-test-shallow 2>&1 | tee /tmp/clone-log.txt

shallow_end_time=$(date +%s)
shallow_duration=$((shallow_end_time - start_time))

echo "Shallow clone completed in: ${shallow_duration} seconds"

# Test full clone
start_time=$(date +%s)
timeout 3600 git clone https://github.com/EttusResearch/uhd.git /tmp/uhd-test-full 2>&1 | tee -a /tmp/clone-log.txt

full_end_time=$(date +%s)
full_duration=$((full_end_time - start_time))

echo "Full clone completed in: ${full_duration} seconds"

# Repository size analysis
if [ -d "/tmp/uhd-test-full" ]; then
    repo_size=$(du -sh /tmp/uhd-test-full | cut -f1)
    echo "Repository size: ${repo_size}"
    
    file_count=$(find /tmp/uhd-test-full -type f | wc -l)
    echo "File count: ${file_count}"
fi

# Network speed test
echo "Testing network connectivity to GitHub..."
ping -c 5 github.com

# Cleanup
rm -rf /tmp/uhd-test-*

echo ""
echo "=== Analysis Results ==="
echo "Shallow clone time: ${shallow_duration}s"
echo "Full clone time: ${full_duration}s"
echo "Repository size: ${repo_size:-"Unknown"}"

if [ $shallow_duration -gt 3600 ]; then
    echo "⚠️  WARNING: Shallow clone took over 1 hour"
fi

if [ $full_duration -gt 3600 ]; then
    echo "⚠️  WARNING: Full clone took over 1 hour"
fi 