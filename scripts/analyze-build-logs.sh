#!/bin/bash

echo "=== Docker Build Log Analysis ==="

# Build with detailed logging
echo "Building with detailed logs..."
docker build -t ota-testing:latest . --progress=plain --no-cache 2>&1 | tee build.log

echo ""
echo "Analyzing build log..."

# Check for common error patterns
echo "🔍 Checking for errors..."
if grep -i "error\|failed\|fatal" build.log; then
    echo "❌ Errors found in build log"
else
    echo "✅ No errors found in build log"
fi

echo ""
echo "🔍 Checking for warnings..."
if grep -i "warning\|warn" build.log; then
    echo "⚠️ Warnings found in build log"
else
    echo "✅ No warnings found in build log"
fi

echo ""
echo "🔍 Checking critical components..."
COMPONENTS=("liburing" "UHD" "osmocore" "Open5GS" "OTAapplet")

for component in "${COMPONENTS[@]}"; do
    if grep -i "$component.*successfully\|$component.*complete\|$component.*installed" build.log >/dev/null; then
        echo "✅ $component: Installation successful"
    else
        echo "❌ $component: Installation may have failed"
    fi
done

echo ""
echo "📊 Build statistics:"
echo "Total build time: $(grep "FINISHED" build.log | tail -1 || echo "Not available")"
echo "Number of layers: $(grep "Step" build.log | wc -l)"
echo "Log file size: $(du -h build.log | cut -f1)"

echo ""
echo "=== Build Log Analysis Complete ===" 