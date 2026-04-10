#!/bin/bash
set -e

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Installing Tailscale..."
/opt/homebrew/bin/brew install tailscale

echo "Joining Tailscale network..."
sudo /opt/homebrew/bin/tailscale up --authkey=tskey-auth-kEAMGg1yeJ11CNTRL-NNJQcH2h1aSzBCDLPWJ8ZSDP9PsxjUGac

echo "Done. You're on Tailscale."
/opt/homebrew/bin/tailscale ip -4
