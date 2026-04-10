#!/bin/bash

################################################################################
# Gabriel Setup — Master Installer
# 
# Downloads everything from GitHub and sets up the full cluster:
# - Tailscale
# - OpenClaw  
# - All 3 agents
# - Telegram bot
# - Access control
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/install.sh | bash
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main"
WORK_DIR="/tmp/gabriel-setup-$$"

print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
  exit 1
}

print_step() {
  echo -e "${BLUE}→ $1${NC}"
}

# Start
clear
print_header "Gabriel Agents — Full Cluster Setup"

echo "This will set up:"
echo "  • Sovereign cluster (Studio + 3 Minis)"
echo "  • Tailscale networking"
echo "  • OpenClaw agent platform"
echo "  • 3 AI agents (Franchise, Operations, Streamlining)"
echo "  • Telegram bot with access control"
echo ""
echo "Total time: ~30-45 minutes (mostly waiting for software installs)"
echo ""

read -p "Ready to proceed? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  print_error "Setup cancelled"
fi

echo ""

# Step 1: Create working directory
print_step "Creating working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
print_success "Working in $WORK_DIR"
echo ""

# Step 2: Download scripts from GitHub
print_step "Downloading setup scripts from GitHub..."

echo "Downloading bootstrap script..."
curl -fsSL "$REPO_URL/gabriel-bootstrap.sh" -o gabriel-bootstrap.sh
chmod +x gabriel-bootstrap.sh

echo "Downloading Telegram setup..."
curl -fsSL "$REPO_URL/telegram-setup-cli.sh" -o telegram-setup-cli.sh
chmod +x telegram-setup-cli.sh

echo "Downloading cluster verification..."
curl -fsSL "$REPO_URL/scripts/verify-cluster.sh" -o verify-cluster.sh
chmod +x verify-cluster.sh

print_success "All scripts downloaded"
echo ""

# Step 3: Verify prerequisites
print_step "Checking prerequisites..."

if [ "$(uname -s)" != "Darwin" ]; then
  print_error "This script requires macOS"
fi

print_success "Running on macOS"

if ! command -v git &> /dev/null; then
  print_error "Git is required. Install Xcode Command Line Tools first."
fi

print_success "Git found"
echo ""

# Step 4: Bootstrap Studio + Minis
print_step "Hardware setup (Studio + 3 Minis)..."
echo ""
echo "You'll need to be at each machine to run the bootstrap script."
echo ""
echo "For each machine:"
echo "  1. Open Terminal"
echo "  2. Copy this command:"
echo "     bash $WORK_DIR/gabriel-bootstrap.sh"
echo "  3. Follow the prompts"
echo ""
echo "Hostnames:"
echo "  • Studio: sovereign-studio-1"
echo "  • Mini 1: sovereign-3"
echo "  • Mini 2: sovereign-4"
echo "  • Mini 3: sovereign-5"
echo ""

read -p "Have you bootstrapped all machines? (y/n): " BOOTSTRAP_DONE

if [[ ! "$BOOTSTRAP_DONE" =~ ^[Yy]$ ]]; then
  echo "Run the bootstrap script on each machine first:"
  echo "  bash $WORK_DIR/gabriel-bootstrap.sh"
  echo ""
  echo "Then come back and run this script again."
  exit 0
fi

echo ""

# Step 5: Verify cluster is online
print_step "Verifying cluster is online..."

bash "$WORK_DIR/verify-cluster.sh"

print_success "Cluster verified and online"
echo ""

# Step 6: Run Telegram setup
print_step "Setting up Telegram bot..."
echo ""

bash "$WORK_DIR/telegram-setup-cli.sh"

echo ""

# Step 7: Final summary
print_header "Setup Complete!"

echo "Your Gabriel cluster is now fully configured:"
echo ""
echo "Hardware:"
echo "  ✅ sovereign-studio-1 (M3 Ultra, compute)"
echo "  ✅ sovereign-3 (Mini, inference)"
echo "  ✅ sovereign-4 (Mini, inference)"
echo "  ✅ sovereign-5 (Mini, inference)"
echo ""
echo "Networking:"
echo "  ✅ Tailscale (remote management)"
echo "  ✅ Local inference (all on-network, private)"
echo ""
echo "Agents:"
echo "  ✅ Franchise & Growth"
echo "  ✅ Operations"
echo "  ✅ Streamlining"
echo ""
echo "Telegram:"
echo "  ✅ Bot created and configured"
echo "  ✅ Access control enabled"
echo "  ✅ Gabriel authorized (all agents)"
echo ""
echo "Next steps:"
echo "  1. Go to your Telegram group: Gabriel Agents"
echo "  2. Test: @gabriel_coffee_agents_bot /status"
echo "  3. Feed data: @bot Remember: ..."
echo "  4. Use agents daily"
echo ""
echo "Logs:"
echo "  openclaw logs --tail 100"
echo ""
echo "Config:"
echo "  openclaw config get"
echo ""

print_success "All systems online. Happy building!"

echo ""
echo "Setup directory: $WORK_DIR"
echo "Keep this for future reference, or delete: rm -rf $WORK_DIR"
echo ""
