#!/bin/bash

echo "=== Adding OTA Testing Environment to GitHub ==="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ] || [ ! -f "Dockerfile" ]; then
    echo "Error: Please run this script from the OTA testing environment directory"
    exit 1
fi

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [ -z "$GITHUB_USERNAME" ]; then
    echo "Error: GitHub username is required"
    exit 1
fi

# Initialize git repository if needed
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init -b main
else
    echo "Git repository already exists"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    echo "Creating .gitignore file..."
    cat > .gitignore << 'EOF'
# Logs
logs/
*.log

# Build directories  
build/
repos/*/build/
repos/*/install/

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.so

# Docker volumes
mongodb_data/

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Sensitive configuration files
configs/*key*
configs/*secret*
configs/*password*

# Large binary files
*.cap
*.jar
*.iso
*.img

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Node modules (if any)
node_modules/

# Environment variables
.env
.env.local
.env.production
EOF
fi

# Configure Git user (if not already configured)
if [ -z "$(git config user.name)" ]; then
    read -p "Enter your name for Git commits: " GIT_NAME
    git config user.name "$GIT_NAME"
fi

if [ -z "$(git config user.email)" ]; then
    read -p "Enter your email for Git commits: " GIT_EMAIL
    git config user.email "$GIT_EMAIL"
fi

# Add remote repository with username
echo "Adding GitHub remote..."
if ! git remote get-url origin &>/dev/null; then
    git remote add origin https://${GITHUB_USERNAME}@github.com/mavericky109007/glo.git
    echo "✓ Remote repository added"
else
    echo "✓ Remote repository already exists"
    # Update existing remote to include username
    git remote set-url origin https://${GITHUB_USERNAME}@github.com/mavericky109007/glo.git
fi

# Verify remote
echo "Verifying remote repository..."
git remote -v

# Stage all files
echo "Staging files..."
git add .

# Check what will be committed
echo "Files to be committed:"
git status --short

# Create commit
echo "Creating commit..."
git commit -m "Initial commit: Complete OTA SMS Testing Environment

Features:
- Docker-based setup with resolved dependencies
- Enhanced OTA client based on ryantheelder's implementation
- Full network simulation (srsRAN, Open5GS, Osmocom)  
- Security research and vulnerability testing tools
- Educational attack simulation capabilities
- Fixed package dependency issues
- Complete documentation and setup scripts

Components:
- UHD/USRP support with proper dependencies (mako, ruamel.yaml)
- Smart card libraries (pyscard) with system dependencies
- SMPP client for OTA SMS delivery
- Network simulation infrastructure
- Comprehensive test suites
- Docker containerization for reproducible environments

Based on research from:
- https://github.com/osmocom (Osmocom project components)
- https://gitea.osmocom.org/ (Official Osmocom repositories)
- https://github.com/ryantheelder/OTAapplet (OTA SMS implementation)

Usage:
1. docker-compose build --no-cache
2. docker-compose up -d  
3. docker-compose exec ota-testing bash
4. ./scripts/verify-build.sh"

# Push to GitHub
echo ""
echo "⚠️  AUTHENTICATION REQUIRED ⚠️"
echo "When prompted for password, use your GitHub Personal Access Token"
echo "NOT your GitHub account password!"
echo ""
echo "If you don't have a Personal Access Token:"
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Generate new token (classic)"
echo "3. Select 'repo' scope"
echo "4. Use the token as your password"
echo ""
read -p "Press Enter to continue with push..."

git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=== Repository Setup Complete! ==="
    echo "Your OTA testing environment has been pushed to:"
    echo "https://github.com/mavericky109007/glo"
    echo ""
    echo "Next steps:"
    echo "1. Visit the repository on GitHub"
    echo "2. Add a detailed README if needed"
    echo "3. Set up branch protection rules"
    echo "4. Add collaborators if working in a team"
else
    echo ""
    echo "❌ Push failed. Please check your authentication."
    echo "Make sure you're using a Personal Access Token, not your password."
fi 