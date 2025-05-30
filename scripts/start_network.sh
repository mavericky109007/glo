#!/bin/bash

# Network startup script for OTA testing
echo "=== Starting OTA Testing Network ==="

# Create tmux session
tmux new-session -d -s ota-network

# Start Open5GS components
tmux new-window -t ota-network -n 'mme' '~/ota-testing/repos/open5gs/install/bin/open5gs-mmed -c ~/ota-testing/configs/mme.conf'
tmux new-window -t ota-network -n 'hss' '~/ota-testing/repos/open5gs/install/bin/open5gs-hssd'
tmux new-window -t ota-network -n 'pcrf' '~/ota-testing/repos/open5gs/install/bin/open5gs-pcrfd'
tmux new-window -t ota-network -n 'sgwc' '~/ota-testing/repos/open5gs/install/bin/open5gs-sgwcd'
tmux new-window -t ota-network -n 'sgwu' '~/ota-testing/repos/open5gs/install/bin/open5gs-sgwud'
tmux new-window -t ota-network -n 'smf' '~/ota-testing/repos/open5gs/install/bin/open5gs-smfd'
tmux new-window -t ota-network -n 'upf' '~/ota-testing/repos/open5gs/install/bin/open5gs-upfd'

# Start Osmocom components
tmux new-window -t ota-network -n 'msc' 'sudo osmo-msc -c ~/ota-testing/configs/osmo-msc.cfg'
tmux new-window -t ota-network -n 'hlr' 'sudo osmo-hlr'

echo "Network components started in tmux session 'ota-network'"
echo "Use 'tmux attach -t ota-network' to view"
echo "Use 'tmux list-windows -t ota-network' to see all components" 