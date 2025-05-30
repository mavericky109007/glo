#!/bin/bash

echo "=== Quick Push of Latest Changes ==="

# Add all changes
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit"
    exit 0
fi

# Show what will be committed
echo "Changes to be committed:"
git diff --staged --name-status

# Commit with automatic message
git commit -m "Update: $(date '+%Y-%m-%d %H:%M') - Latest improvements

- Enhanced setup and verification scripts
- Improved error handling and user experience
- Added comprehensive push verification tools"

# Push
echo "Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ Push successful!"
    
    # Run verification if script exists
    if [ -f "verify-push.sh" ]; then
        echo "Running verification..."
        chmod +x verify-push.sh
        ./verify-push.sh
    fi
else
    echo "❌ Push failed"
fi 