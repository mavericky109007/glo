#!/bin/bash

# Start network components in Docker environment
echo "=== Starting Network Components ==="

# Create tmux session
tmux new-session -d -s ota-network

# Start Open5GS components
tmux new-window -t ota-network -n 'mme' 'open5gs-mmed'
tmux new-window -t ota-network -n 'hss' 'open5gs-hssd'
tmux new-window -t ota-network -n 'pcrf' 'open5gs-pcrfd'
tmux new-window -t ota-network -n 'sgwc' 'open5gs-sgwcd'
tmux new-window -t ota-network -n 'sgwu' 'open5gs-sgwud'
tmux new-window -t ota-network -n 'smf' 'open5gs-smfd'
tmux new-window -t ota-network -n 'upf' 'open5gs-upfd'

# Start Osmocom components
tmux new-window -t ota-network -n 'msc' 'osmo-msc -c /ota-testing/configs/osmo-msc.cfg'
tmux new-window -t ota-network -n 'hlr' 'osmo-hlr'

echo "Network components started in tmux session 'ota-network'"
echo "Use 'tmux attach -t ota-network' to view" 