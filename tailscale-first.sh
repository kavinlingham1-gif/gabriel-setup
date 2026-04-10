#!/bin/bash

################################################################################
# Gabriel Setup — Tailscale First (Remote Everything)
#
# Get all 4 machines on Tailscale, then we automate the rest remotely.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/tailscale-first.sh | bash
#
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

print_step() {
  echo -e "${BLUE}→ $1${NC}"
}

clear
print_header "Gabriel Setup — Tailscale First"

echo "Step 1: Install Tailscale on this machine"
echo ""

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
  print_step "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
  print_success "Tailscale installed"
else
  print_success "Tailscale already installed"
fi

echo ""

# Check if connected
if ! tailscale status &> /dev/null; then
  print_step "Connecting to Tailscale..."
  echo ""
  echo "Opening browser for Tailscale login..."
  echo "You'll authenticate with your Tailscale account."
  echo ""
  
  sudo tailscale up
  
  print_success "Connected to Tailscale"
else
  print_success "Already connected to Tailscale"
fi

echo ""

# Get Tailscale IP
TAILSCALE_IP=$(tailscale ip -4)

echo "Your Tailscale IP: $TAILSCALE_IP"
echo ""

print_header "Step 2: Get Other Machines on Tailscale"

echo "For each of the other 3 machines (sovereign-3, sovereign-4, sovereign-5):"
echo ""
echo "  1. SSH into the machine:"
echo "     ssh admin@sovereign-X.local"
echo ""
echo "  2. Install and connect Tailscale:"
echo "     curl -fsSL https://tailscale.com/install.sh | sh"
echo "     sudo tailscale up"
echo ""
echo "  3. Follow the browser link to authenticate"
echo ""
echo "After all 4 machines are on Tailscale, come back here."
echo ""

read -p "Press Enter when all 4 machines are on Tailscale..."

echo ""

print_header "Step 3: Verify All Machines Online"

print_step "Checking Tailscale network..."

echo "Pinging all machines:"
echo ""

MACHINES=("sovereign-studio-1" "sovereign-3" "sovereign-4" "sovereign-5")
ALL_UP=true

for machine in "${MACHINES[@]}"; do
  if ping -c 1 "$machine" &> /dev/null; then
    echo -e "${GREEN}✅${NC} $machine online"
  else
    echo -e "${YELLOW}⚠️${NC} $machine offline (will retry)"
    ALL_UP=false
  fi
done

if [ "$ALL_UP" = false ]; then
  echo ""
  echo "Some machines not responding yet. Waiting 10 seconds..."
  sleep 10
  
  for machine in "${MACHINES[@]}"; do
    if ping -c 1 "$machine" &> /dev/null; then
      echo -e "${GREEN}✅${NC} $machine online"
    else
      echo -e "${YELLOW}❌${NC} $machine still offline"
    fi
  done
fi

echo ""

print_header "Step 4: Remote Bootstrap All Machines"

print_step "Bootstrapping sovereign-studio-1..."

ssh admin@sovereign-studio-1 << 'STUDIO'
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/gabriel-bootstrap.sh | bash
STUDIO

print_success "Studio bootstrapped"

echo ""
print_step "Bootstrapping sovereign-3..."

ssh admin@sovereign-3 << 'MINI3'
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/gabriel-bootstrap.sh | bash
MINI3

print_success "Mini 3 bootstrapped"

echo ""
print_step "Bootstrapping sovereign-4..."

ssh admin@sovereign-4 << 'MINI4'
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/gabriel-bootstrap.sh | bash
MINI4

print_success "Mini 4 bootstrapped"

echo ""
print_step "Bootstrapping sovereign-5..."

ssh admin@sovereign-5 << 'MINI5'
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/gabriel-bootstrap.sh | bash
MINI5

print_success "Mini 5 bootstrapped"

echo ""

print_header "Step 5: Setup Telegram Bot"

print_step "Running Telegram setup..."

curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/telegram-setup-cli.sh | bash

echo ""

print_header "✅ Complete!"

echo "Your Gabriel cluster is fully deployed and online:"
echo ""
echo "  ✅ sovereign-studio-1 (compute brain)"
echo "  ✅ sovereign-3 (inference)"
echo "  ✅ sovereign-4 (inference)"
echo "  ✅ sovereign-5 (inference)"
echo "  ✅ Tailscale (remote management)"
echo "  ✅ All 3 agents (Franchise, Operations, Streamlining)"
echo "  ✅ Telegram bot (with access control)"
echo ""
echo "Next: Go to your Telegram group and test:"
echo "  @gabriel_coffee_agents_bot /status"
echo ""
