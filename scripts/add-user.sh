#!/bin/bash
echo "Add new Telegram user to Gabriel agents"
echo ""
echo "Step 1: Get their Telegram user ID"
echo "  1. Have them send a message in Gabriel Agents group"
echo "  2. Forward their message to @userinfobot"
echo "  3. Copy the user ID shown"
echo ""
read -p "Paste their user ID: " USER_ID

if [ -z "$USER_ID" ]; then
  echo "User ID required"
  exit 1
fi

read -p "Enter their name: " USER_NAME
echo "Agents: franchise, operations, streamlining"
read -p "Which agents? (comma-separated, e.g., operations,streamlining): " USER_AGENTS
echo "Permissions: read, write, schedule"
read -p "Which permissions? (comma-separated, e.g., read,write): " USER_PERMS

echo ""
echo "Adding $USER_NAME (ID: $USER_ID)..."
echo ""

# Format agents and perms as JSON arrays
AGENTS_JSON=$(echo "$USER_AGENTS" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
PERMS_JSON=$(echo "$USER_PERMS" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')

openclaw config patch <<EOF
{
  "plugins": {
    "telegram": {
      "accessControl": {
        "allowedUsers": [
          ... (paste your current allowedUsers here) ...,
          {
            "telegramId": $USER_ID,
            "name": "$USER_NAME",
            "agents": $AGENTS_JSON,
            "permissions": $PERMS_JSON
          }
        ]
      }
    }
  }
}
EOF

echo ""
echo "Restarting OpenClaw..."
openclaw gateway restart
sleep 5

echo "✅ User added: $USER_NAME"
