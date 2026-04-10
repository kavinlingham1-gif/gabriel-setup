#!/bin/bash

################################################################################
# Gabriel Setup — Master Installer (Non-Interactive)
# 
# Just run it. It downloads everything and guides you through each step.
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

echo "This will download and configure everything for your cluster."
echo ""

# Create working directory
print_step "Creating working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
print_success "Working in $WORK_DIR"
echo ""

# Download scripts from GitHub
print_step "Downloading setup scripts from GitHub..."

echo "  • Downloading bootstrap script..."
curl -fsSL "$REPO_URL/gabriel-bootstrap.sh" -o gabriel-bootstrap.sh 2>/dev/null
chmod +x gabriel-bootstrap.sh

echo "  • Downloading Telegram setup..."
curl -fsSL "$REPO_URL/telegram-setup-cli.sh" -o telegram-setup-cli.sh 2>/dev/null
chmod +x telegram-setup-cli.sh

echo "  • Downloading verification script..."
curl -fsSL "$REPO_URL/scripts/verify-cluster.sh" -o verify-cluster.sh 2>/dev/null
chmod +x verify-cluster.sh

print_success "All scripts downloaded to $WORK_DIR"
echo ""

# Verify prerequisites
print_step "Checking prerequisites..."

if [ "$(uname -s)" != "Darwin" ]; then
  print_error "This requires macOS"
fi

print_success "macOS detected"

if ! command -v git &> /dev/null; then
  print_error "Git not found. Install Xcode Command Line Tools first."
fi

print_success "Git installed"
echo ""

# Instructions
print_header "Next: Bootstrap Your Hardware"

echo "You have 4 machines to set up:"
echo ""
echo "1. STUDIO (sovereign-studio-1)"
echo "   Command: bash $WORK_DIR/gabriel-bootstrap.sh"
echo "   Time: ~20 min"
echo ""
echo "2. MINI 1 (sovereign-3)"
echo "   Command: bash $WORK_DIR/gabriel-bootstrap.sh"
echo "   Time: ~20 min"
echo ""
echo "3. MINI 2 (sovereign-4)"
echo "   Command: bash $WORK_DIR/gabriel-bootstrap.sh"
echo "   Time: ~20 min"
echo ""
echo "4. MINI 3 (sovereign-5)"
echo "   Command: bash $WORK_DIR/gabriel-bootstrap.sh"
echo "   Time: ~20 min"
echo ""
echo "====="
echo ""
echo "After bootstrapping all 4 machines, come back here and run:"
echo ""
echo "  bash $WORK_DIR/telegram-setup-cli.sh"
echo ""
echo "====="
echo ""

print_success "Setup ready. Copy the bootstrap command to each machine."
echo ""
echo "Bootstrap command:"
echo "  bash $WORK_DIR/gabriel-bootstrap.sh"
echo ""
echo "When all machines are done, run Telegram setup:"
echo "  bash $WORK_DIR/telegram-setup-cli.sh"
echo ""
