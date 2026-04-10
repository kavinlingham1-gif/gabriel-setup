#!/bin/bash

################################################################################
# Gabriel Agents — Telegram Setup CLI
# 
# Full interactive setup. Just run:
#   bash telegram-setup-cli.sh
#
# Then answer the prompts. Everything else is automatic.
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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
}

print_info() {
  echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_step() {
  echo -e "${BLUE}→ $1${NC}"
}

# Start
clear
print_header "Gabriel Agents — Telegram Setup"

echo "This will set up your Telegram bot for Black Sheep Coffee agents."
echo "Takes about 5 minutes."
echo ""

# Step 1: Check prerequisites
print_step "Checking prerequisites..."

if ! command -v openclaw &> /dev/null; then
  print_error "OpenClaw is not installed or not in PATH"
  echo "Install it first: https://docs.openclaw.ai"
  exit 1
fi

print_success "OpenClaw found"

if ! openclaw status &> /dev/null; then
  print_error "OpenClaw is not running"
  echo "Start it with: openclaw gateway start"
  exit 1
fi

print_success "OpenClaw is running"
echo ""

# Step 2: Get bot token
print_step "Telegram Bot Token"
echo ""
echo "You need a Telegram bot token. Here's how to get one:"
echo ""
echo "  1. Open Telegram"
echo "  2. Search for: @BotFather"
echo "  3. Send: /newbot"
echo "  4. BotFather asks for bot name: Gabriel Coffee Agents"
echo "  5. BotFather asks for username: gabriel_coffee_agents_bot"
echo "  6. BotFather gives you a TOKEN (starts with numbers and :)"
echo ""
echo "Example token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyzABCdeFGHi"
echo ""

read -p "Paste your bot token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
  print_error "Token is required"
  exit 1
fi

if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
  print_error "Token format looks invalid. Should be: numbers:text"
  exit 1
fi

print_success "Token saved: ${BOT_TOKEN:0:10}...${BOT_TOKEN: -10}"
echo ""

# Step 3: Verify bot token works
print_step "Verifying bot token..."

VERIFY=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")

if echo "$VERIFY" | grep -q '"ok":true'; then
  BOT_NAME=$(echo "$VERIFY" | grep -o '"first_name":"[^"]*' | cut -d'"' -f4)
  BOT_USERNAME=$(echo "$VERIFY" | grep -o '"username":"[^"]*' | cut -d'"' -f4)
  print_success "Bot verified: @$BOT_USERNAME ($BOT_NAME)"
else
  print_error "Bot token is invalid. Please check and try again."
  exit 1
fi
echo ""

# Step 4: Create Telegram group
print_step "Telegram Group Setup"
echo ""
echo "You need a private Telegram group for agents. Instructions:"
echo ""
echo "  1. Open Telegram"
echo "  2. Create NEW GROUP"
echo "  3. Name it: Gabriel Agents"
echo "  4. Search for your bot: @$BOT_USERNAME"
echo "  5. Add bot to the group"
echo "  6. Click group name → Settings"
echo "  7. Link → Turn OFF 'Add members via link' (make it private)"
echo "  8. Permissions → Only admins can send messages (optional)"
echo ""
echo "✅ Group is created and bot is added?"
echo ""

read -p "Press Enter when done, then send a message in the group so we can detect it"
echo ""

# Step 5: Get group ID
print_step "Detecting group ID..."

# Wait for message and get updates
sleep 2
UPDATES=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

# Try to find group ID from recent messages
GROUP_ID=$(echo "$UPDATES" | grep -o '"chat":{"id":-[0-9]*' | head -1 | grep -o '\-[0-9]*' | head -1)

if [ -z "$GROUP_ID" ]; then
  print_error "Could not auto-detect group. Asking manually..."
  echo ""
  echo "To find your group ID:"
  echo "  1. Forward any message from Gabriel Agents group to @userinfobot"
  echo "  2. Bot shows you the group chat ID (negative number like -1001234567890)"
  echo ""
  read -p "Paste your group ID: " GROUP_ID
  
  if [ -z "$GROUP_ID" ]; then
    print_error "Group ID is required"
    exit 1
  fi
fi

print_success "Group detected: $GROUP_ID"
echo ""

# Step 6: Get Gabriel's user ID
print_step "Gabriel's Telegram User ID"
echo ""
echo "To get your user ID:"
echo "  1. Send a message in the Gabriel Agents group"
echo "  2. Forward your message to @userinfobot"
echo "  3. Bot shows you your user ID (positive number)"
echo ""

read -p "Paste your Telegram user ID: " GABRIEL_ID

if [ -z "$GABRIEL_ID" ]; then
  print_error "User ID is required"
  exit 1
fi

if ! [[ "$GABRIEL_ID" =~ ^[0-9]+$ ]]; then
  print_error "User ID should be a number"
  exit 1
fi

print_success "Gabriel ID saved: $GABRIEL_ID"
echo ""

# Step 7: Optional additional users
print_step "Additional Users (Optional)"
echo ""
echo "You can add more users now (ops manager, finance manager, etc.)"
echo "Or add them later. Your choice."
echo ""

read -p "Add additional users now? (y/n): " ADD_USERS

ADDITIONAL_USERS=""

if [[ "$ADD_USERS" =~ ^[Yy]$ ]]; then
  
  while true; do
    echo ""
    read -p "Enter user ID (or press Enter to skip): " USER_ID
    
    if [ -z "$USER_ID" ]; then
      break
    fi
    
    if ! [[ "$USER_ID" =~ ^[0-9]+$ ]]; then
      print_error "User ID should be a number"
      continue
    fi
    
    read -p "Enter user name: " USER_NAME
    
    if [ -z "$USER_NAME" ]; then
      print_error "Name is required"
      continue
    fi
    
    echo "Which agents can this user access? (comma-separated)"
    echo "  Options: franchise, operations, streamlining"
    read -p "Agents: " USER_AGENTS
    
    if [ -z "$USER_AGENTS" ]; then
      USER_AGENTS="operations,streamlining"
    fi
    
    echo "Which permissions? (comma-separated)"
    echo "  Options: read, write, schedule"
    read -p "Permissions: " USER_PERMS
    
    if [ -z "$USER_PERMS" ]; then
      USER_PERMS="read"
    fi
    
    # Format agents and permissions as JSON arrays
    AGENTS_JSON=$(echo "$USER_AGENTS" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
    PERMS_JSON=$(echo "$USER_PERMS" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
    
    ADDITIONAL_USERS="$ADDITIONAL_USERS,
          {
            \"telegramId\": $USER_ID,
            \"name\": \"$USER_NAME\",
            \"agents\": $AGENTS_JSON,
            \"permissions\": $PERMS_JSON
          }"
    
    print_success "Added: $USER_NAME ($USER_ID)"
  done
fi

echo ""

# Step 8: Summary
print_header "Summary"
echo ""
echo "Bot Token:      ${BOT_TOKEN:0:10}...${BOT_TOKEN: -10}"
echo "Bot Name:       @$BOT_USERNAME"
echo "Group ID:       $GROUP_ID"
echo "Gabriel ID:     $GABRIEL_ID (all agents)"
if [ -n "$ADDITIONAL_USERS" ]; then
  echo "Additional:     Yes"
fi
echo ""

read -p "Ready to deploy? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  print_error "Setup cancelled"
  exit 1
fi

echo ""

# Step 9: Configure OpenClaw
print_step "Configuring OpenClaw..."

# Build allowed users JSON
ALLOWED_USERS='[
          {
            "telegramId": '$GABRIEL_ID',
            "name": "Gabriel Shohet",
            "agents": ["franchise", "operations", "streamlining"],
            "permissions": ["read", "write", "schedule"]
          }'

if [ -n "$ADDITIONAL_USERS" ]; then
  ALLOWED_USERS="$ALLOWED_USERS$ADDITIONAL_USERS"
fi

ALLOWED_USERS="$ALLOWED_USERS"']'

# Apply configuration
openclaw config patch <<EOF
{
  "plugins": {
    "telegram": {
      "enabled": true,
      "token": "$BOT_TOKEN",
      "groupId": "$GROUP_ID",
      "accessControl": {
        "enabled": true,
        "mode": "whitelist",
        "allowedUsers": $ALLOWED_USERS,
        "deniedActions": [
          "delete_memory",
          "export_data",
          "modify_config"
        ]
      }
    }
  }
}
EOF

if [ $? -eq 0 ]; then
  print_success "OpenClaw configured"
else
  print_error "Failed to configure OpenClaw"
  exit 1
fi

echo ""

# Step 10: Restart OpenClaw
print_step "Restarting OpenClaw..."

openclaw gateway restart
sleep 5

print_success "OpenClaw restarted"
echo ""

# Step 11: Test connection
print_step "Testing Telegram connection..."

TEST=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")

if echo "$TEST" | grep -q '"ok":true'; then
  print_success "Bot is live and responding"
else
  print_error "Connection test failed"
  echo "Check logs: openclaw logs --tail 50"
  exit 1
fi

echo ""

# Step 12: Summary and next steps
print_header "Setup Complete!"
echo ""
echo "Your Telegram bot is configured and ready."
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Go to your Telegram group: Gabriel Agents"
echo ""
echo "2. Test the bot:"
echo "   @gabriel_coffee_agents_bot /status"
echo ""
echo "3. Agent should respond with:"
echo "   'Gabriel Agents — Status Online'"
echo "   'Agents online: 3'"
echo ""
echo "4. Load Black Sheep Coffee data:"
echo "   @bot Remember: We have 3 locations. Domain does \$450K/mo revenue with 12 staff. Sixth & Guad does \$380K/mo with 10 staff. SoCo does \$320K/mo with 9 staff."
echo ""
echo "5. Test each agent:"
echo ""
echo "   FRANCHISE AGENT:"
echo "   @bot franchise: Model out a Tampa location launch. Show me the financial model."
echo ""
echo "   OPERATIONS AGENT:"
echo "   @bot ops: Which location is overstaffed for its revenue?"
echo ""
echo "   STREAMLINING AGENT:"
echo "   @bot streamline: SoCo labor is 30% of revenue. That's above our 28% target. What should we do?"
echo ""
echo "6. Verify access control works:"
echo "   @bot What's our customer acquisition cost?"
echo "   (Should respond: 'I don't know' — it wasn't in memory)"
echo ""
echo "DONE! Your agents are live. Use them daily, they get smarter."
echo ""
echo "More help:"
echo "  - Check logs: openclaw logs --tail 50"
echo "  - Agent status: openclaw agent status"
echo "  - Add users later: See TELEGRAM_ACCESS_CONTROL.md"
echo ""

print_success "All set!"
