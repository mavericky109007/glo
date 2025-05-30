#!/bin/bash

echo "=== Verifying Git Push Status ==="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a Git repository"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Check remote URL
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -n "$REMOTE_URL" ]; then
    echo "Remote URL: $REMOTE_URL"
else
    echo "❌ No remote repository configured"
    exit 1
fi

# Check git status
echo ""
echo "=== Git Status ==="
git status

# Check if local is ahead/behind remote
echo ""
echo "=== Comparing Local vs Remote ==="
git fetch origin $CURRENT_BRANCH 2>/dev/null

LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH 2>/dev/null)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Local and remote are in sync"
    echo "Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)')"
else
    echo "⚠️  Local and remote are out of sync"
    echo "Local commit:  $LOCAL_COMMIT"
    echo "Remote commit: $REMOTE_COMMIT"
    
    # Check if local is ahead
    if git merge-base --is-ancestor origin/$CURRENT_BRANCH HEAD; then
        AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD)
        echo "📤 Local is $AHEAD commit(s) ahead of remote"
        echo "You may need to push: git push origin $CURRENT_BRANCH"
    fi
    
    # Check if local is behind
    if git merge-base --is-ancestor HEAD origin/$CURRENT_BRANCH; then
        BEHIND=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH)
        echo "📥 Local is $BEHIND commit(s) behind remote"
        echo "You may need to pull: git pull origin $CURRENT_BRANCH"
    fi
fi

# Check recent commits
echo ""
echo "=== Recent Commits ==="
echo "Local commits:"
git log --oneline -3

echo ""
echo "Remote commits:"
git log --oneline origin/$CURRENT_BRANCH -3 2>/dev/null || echo "Could not fetch remote commits"

# Test connectivity to GitHub
echo ""
echo "=== Testing GitHub Connectivity ==="
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection to GitHub working"
elif curl -s https://github.com >/dev/null; then
    echo "✅ HTTPS connection to GitHub working"
else
    echo "❌ Cannot connect to GitHub"
fi

# Check if files exist on remote
echo ""
echo "=== Checking Remote Repository Content ==="
if git ls-remote --heads origin $CURRENT_BRANCH >/dev/null 2>&1; then
    echo "✅ Remote branch '$CURRENT_BRANCH' exists"
    
    # List some key files that should be there
    KEY_FILES=("README.md" "Dockerfile" "docker-compose.yml" "setup-github-repo.sh")
    
    for file in "${KEY_FILES[@]}"; do
        if git cat-file -e origin/$CURRENT_BRANCH:$file 2>/dev/null; then
            echo "✅ $file exists on remote"
        else
            echo "❌ $file missing on remote"
        fi
    done
else
    echo "❌ Remote branch '$CURRENT_BRANCH' does not exist"
fi

echo ""
echo "=== Verification Complete ===" 