# Access Control

Only authorized users can access agents. Set it up during initial installation.

## Current Setup

- **Gabriel:** All agents, all permissions
- **Others:** Added on demand

## Permission Tiers

**Agents:**
- franchise — Franchise & Growth agent
- operations — Operations agent
- streamlining — Streamlining agent

**Permissions:**
- read — View responses, query memory
- write — Update memory, trigger actions
- schedule — Create cron jobs (automated daily briefings, etc.)

## Blocked Actions (everyone)

- delete_memory — Can't erase data
- export_data — Can't download database
- modify_config — Can't change bot settings

## Adding Users

Get their Telegram user ID:
1. They send message in group
2. Forward to @userinfobot
3. Copy their user ID

Then:
```bash
openclaw config patch <<EOF
{
  "plugins": {
    "telegram": {
      "accessControl": {
        "allowedUsers": [
          ... (existing users) ...,
          {
            "telegramId": NEW_USER_ID,
            "name": "New Person",
            "agents": ["operations"],
            "permissions": ["read"]
          }
        ]
      }
    }
  }
}
EOF

openclaw gateway restart
```

## Removing Users

Delete their entry and restart:
```bash
openclaw config patch <<EOF
{
  "plugins": {
    "telegram": {
      "accessControl": {
        "allowedUsers": [
          ... (without their entry) ...
        ]
      }
    }
  }
}
EOF

openclaw gateway restart
```

## Audit Log

All queries logged:
```bash
openclaw logs --filter telegram | grep "Gabriel\|Operations\|Finance"
```

Shows: who asked, what they asked, when, agent response.

## Examples

**Operations Manager:**
```
{
  "telegramId": 987654321,
  "name": "Operations Manager",
  "agents": ["operations", "streamlining"],
  "permissions": ["read", "write"]
}
```

**Finance Manager (read-only):**
```
{
  "telegramId": 555666777,
  "name": "Finance Manager",
  "agents": ["streamlining"],
  "permissions": ["read"]
}
```

**Franchise Development (franchise + streamlining for ROI):**
```
{
  "telegramId": 111222333,
  "name": "Franchise Dev Lead",
  "agents": ["franchise", "streamlining"],
  "permissions": ["read", "write"]
}
```

That's it. Granular, flexible, enforced at every level.
