#!/bin/bash
set -ex

echo "=== Installing Homebrew ==="
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/opt/homebrew/bin:$PATH"

echo "=== Installing Tailscale ==="
brew install tailscale

echo "=== Verifying Tailscale ==="
which tailscale
tailscale version

echo "=== Starting Tailscale daemon ==="
# Kill any existing tailscaled
sudo pkill -f tailscaled || true
sleep 1

# Start fresh daemon and keep it running
sudo nohup /opt/homebrew/bin/tailscaled > /tmp/tailscaled.log 2>&1 &
sleep 5

echo "=== Checking daemon status ==="
ps aux | grep tailscaled | grep -v grep || echo "Daemon check failed"

echo "=== Joining Tailscale network ==="
sudo tailscale up --authkey=tskey-auth-kEAMGg1yeJ11CNTRL-NNJQcH2h1aSzBCDLPWJ8ZSDP9PsxjUGac

sleep 3

echo "=== Verifying connection ==="
tailscale status
echo ""
echo "=== Your Tailscale IP ==="
tailscale ip -4
echo ""
echo "Done!"
