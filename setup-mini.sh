#!/bin/bash

################################################################################
# Gabriel Mini Setup — Agent Configuration
#
# Run on each Mac Mini (sovereign-3, sovereign-4, sovereign-5)
# Studio is already configured. This just sets up each Mini with its agent role.
#
# Prompts you to choose which agent this Mini will run:
#  1. Franchise & Growth
#  2. Operations
#  3. Streamlining
#
# Usage:
#   bash setup-mini.sh
#
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
  echo -e "${RED}❌ $1${NC}"
  exit 1
}

# Start
clear
print_header "Gabriel Mini Setup"

HOSTNAME=$(hostname -s)
echo "Machine: $HOSTNAME"
echo ""

# Check if on Tailscale
print_step "Verifying Tailscale connection..."

if ! tailscale status &> /dev/null; then
  print_error "Not on Tailscale yet. Run join-tailscale.sh first."
fi

TAILSCALE_IP=$(tailscale ip -4)
print_success "On Tailscale: $TAILSCALE_IP"
echo ""

# Check if can reach Studio
print_step "Verifying connection to Studio..."

if ! ping -c 1 sovereign-studio-1 &> /dev/null; then
  print_error "Cannot reach sovereign-studio-1. Check Tailscale connection."
fi

print_success "Can reach sovereign-studio-1"
echo ""

# Choose agent role
print_header "Choose Agent Role"

echo "This Mini will run one of three agents:"
echo ""
echo "  1) Franchise & Growth"
echo "     → Market modeling, contracts, expansion"
echo ""
echo "  2) Operations"
echo "     → Daily performance, staffing, inventory"
echo ""
echo "  3) Streamlining"
echo "     → Cost optimization, efficiency, profitability"
echo ""

read -p "Enter 1, 2, or 3: " AGENT_CHOICE

case $AGENT_CHOICE in
  1)
    AGENT_NAME="Franchise"
    AGENT_ROLE="franchise"
    ;;
  2)
    AGENT_NAME="Operations"
    AGENT_ROLE="operations"
    ;;
  3)
    AGENT_NAME="Streamlining"
    AGENT_ROLE="streamlining"
    ;;
  *)
    print_error "Invalid choice. Enter 1, 2, or 3."
    ;;
esac

echo ""
print_success "Selected: $AGENT_NAME"
echo ""

# Summary
print_header "Setup Summary"

echo "Machine:      $HOSTNAME"
echo "Tailscale IP: $TAILSCALE_IP"
echo "Agent Role:   $AGENT_NAME"
echo "Studio:       sovereign-studio-1"
echo ""

read -p "Ready to configure? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  print_error "Setup cancelled"
fi

echo ""

# Setup steps (would be automated by Jarvis)
print_header "Setup Ready"

echo "Configuration:"
echo "  • OpenClaw will be installed"
echo "  • Pointed at Studio for inference"
echo "  • Agent role: $AGENT_ROLE"
echo "  • Ready for Telegram integration"
echo ""

print_success "Mini is ready for Jarvis remote setup"

echo ""
echo "Next: Tell Jarvis all 4 machines are on Tailscale"
echo "  'All 4 machines are on Tailscale'"
echo ""
echo "Jarvis will then:"
echo "  1. Install OpenClaw on all Minis"
echo "  2. Configure with their chosen agent role"
echo "  3. Point to Studio for inference"
echo "  4. Set up Telegram bot"
echo "  5. Test everything"
echo ""

print_success "Mini configuration locked in"
