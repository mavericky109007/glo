#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

echo "=== OTA Core Network Bootstrap (Production-Ready Script) ==="

# --- Configuration ---
CONFIG_SOURCE_DIR="/home/tetrixcorps/Desktop/glo/configs"
CONFIG_DEST_DIR="/usr/local/etc/open5gs"
SESSION_NAME="ota-network"
REQUIRED_CONFIGS=("mme.yaml" "sgwc.yaml" "sgwu.yaml" "smf.yaml" "upf.yaml" "nrf.yaml")

# --- Step 1: Clean Up Previous Session ---
echo "--> Stopping existing tmux session and Open5GS processes..."
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
# Use sudo and -9 to forcefully kill any orphaned processes
sudo pkill -9 -f open5gs- || true
sleep 2 # Allow time for ports to be released

# --- Step 2: Create Backup Directory and Validate/Copy Configs ---
echo "--> Backing up existing configurations and copying new ones..."
# Create the backup directory if it doesn't exist
BACKUP_DIR="$CONFIG_DEST_DIR/backup_$(date +%s)"
sudo mkdir -p "$BACKUP_DIR"
# Copy existing configs to the backup directory
sudo cp "$CONFIG_DEST_DIR"/*.yaml "$BACKUP_DIR/" 2>/dev/null || echo "No existing configs to back up."

# Validate and copy new configuration files
for config_file in "${REQUIRED_CONFIGS[@]}"; do
    if [[ ! -f "$CONFIG_SOURCE_DIR/$config_file" ]]; then
        echo "❌ ERROR: Required configuration file '$config_file' not found in '$CONFIG_SOURCE_DIR'."
        exit 1
    fi
    echo "Copying '$config_file'..."
    sudo cp "$CONFIG_SOURCE_DIR/$config_file" "$CONFIG_DEST_DIR/"
done

# --- Step 3: Start Services in Background ---
echo "--> Launching services in the background..."

sudo /usr/local/bin/open5gs-nrfd -c "$CONFIG_DEST_DIR/nrf.yaml" -D &
sleep 2

sudo /usr/local/bin/open5gs-sgwud -c "$CONFIG_DEST_DIR/sgwu.yaml" -D &
sleep 1
sudo /usr/local/bin/open5gs-upfd  -c "$CONFIG_DEST_DIR/upf.yaml"  -D &
sleep 1
sudo /usr/local/bin/open5gs-sgwcd -c "$CONFIG_DEST_DIR/sgwc.yaml" -D &
sleep 1
sudo /usr/local/bin/open5gs-smfd  -c "$CONFIG_DEST_DIR/smf.yaml"  -D &
sleep 1
sudo /usr/local/bin/open5gs-mmed  -c "$CONFIG_DEST_DIR/mme.yaml"  -D &

sleep 5 # Allow services to initialize

echo "✅ Success! All network components launched in the background."
echo "Use 'sudo pkill -9 -f open5gs-' to stop them."
