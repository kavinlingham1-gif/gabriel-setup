#!/bin/bash

################################################################################
# Gabriel Mini — Fresh Start (Zero to Tailscale)
#
# Run on a completely fresh Mac Mini with nothing installed.
# Installs everything needed and joins Tailscale network.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/join-tailscale-fresh.sh | bash
#
################################################################################

set -e

AUTHKEY="tskey-auth-kEAMGg1yeJ11CNTRL-NNJQcH2h1aSzBCDLPWJ8ZSDP9PsxjUGac"

echo ""
echo "=================================================="
echo "Gabriel Mini — Fresh Setup"
echo "=================================================="
echo ""

# Step 1: Install Homebrew (if not present)
echo "Step 1: Installing Homebrew..."

if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for this session
  export PATH="/opt/homebrew/bin:$PATH"
  
  echo "✅ Homebrew installed"
else
  echo "✅ Homebrew already installed"
fi

echo ""

# Step 2: Install Tailscale via Homebrew
echo "Step 2: Installing Tailscale..."

brew install tailscale

echo "✅ Tailscale installed"
echo ""

# Step 3: Join Tailscale network with auth key
echo "Step 3: Joining Tailscale network..."

sudo /opt/homebrew/bin/tailscale up --authkey=$AUTHKEY

echo ""
echo "✅ Connected to Tailscale!"
echo ""

# Step 4: Verify connection
sleep 2

TAILSCALE_IP=$(/opt/homebrew/bin/tailscale ip -4 2>/dev/null || echo "pending")
HOSTNAME=$(hostname -s)

if [ "$TAILSCALE_IP" != "pending" ]; then
  echo "=================================================="
  echo "Setup Complete!"
  echo "=================================================="
  echo ""
  echo "Machine:       $HOSTNAME"
  echo "Tailscale IP:  $TAILSCALE_IP"
  echo ""
  echo "Now on Tailscale network. Ready for:"
  echo "  1. Agent role selection"
  echo "  2. Remote OpenClaw setup by Jarvis"
  echo "  3. Agent configuration"
  echo "  4. Telegram integration"
  echo ""
  echo "Next: Tell Jarvis 'All 4 machines on Tailscale'"
  echo ""
else
  echo "⚠️  Waiting for Tailscale connection..."
  sleep 5
  TAILSCALE_IP=$(/opt/homebrew/bin/tailscale ip -4)
  echo "✅ Connected! IP: $TAILSCALE_IP"
  echo ""
fi

echo "=================================================="
