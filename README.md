# Gabriel Agents — Complete Setup

Automated one-command setup for Black Sheep Coffee's private AI agent cluster.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/install.sh | bash
```

That's it. Just run it, answer a few prompts, and your cluster is live.

## What You Get

**Hardware:**
- M3 Ultra 256GB (sovereign-studio-1) — compute brain
- 3× Mac Mini M4 16GB (sovereign-3, 4, 5) — inference

**Agents (on Telegram):**
- Franchise & Growth — market modeling, financial analysis, expansion
- Operations — daily performance, staffing, inventory
- Streamlining — cost optimization, efficiency, profitability

**Features:**
- Private Telegram bot (secure, on-network)
- Access control (only authorized users)
- Persistent memory (never forgets)
- Verification-first (no BS)
- Quality balance (streamlining respects product quality)
- Full audit logging

**Network:**
- Tailscale (private, secure remote access)
- Local inference (nothing leaves your building)
- 24/7 availability

## Prerequisites

- macOS (M-series Mac Studio or Mini)
- Git installed (Xcode Command Line Tools)
- Telegram account
- Bot token from @BotFather (takes 2 minutes)

## Installation

1. **Run the installer:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/install.sh | bash
   ```

2. **Bootstrap each machine** (follow prompts):
   - Studio (sovereign-studio-1)
   - Mini 1 (sovereign-3)
   - Mini 2 (sovereign-4)
   - Mini 3 (sovereign-5)

3. **Setup Telegram** (answer prompts):
   - Bot token (from @BotFather)
   - Your Telegram user ID
   - Optional: additional users

4. **Done!** Your cluster is live.

## Usage

Go to your Telegram group and start using agents:

```
@gabriel_coffee_agents_bot /status
@bot franchise: Model out a Tampa launch
@bot ops: Which location is overstaffed?
@bot streamline: SoCo labor is 30%. Fix?
@bot Remember: We have 3 locations...
```

## Documentation

- **QUICK_START.md** — step-by-step walkthrough
- **AGENTS.md** — what each agent does and how to use them
- **ACCESS_CONTROL.md** — managing permissions and users
- **TROUBLESHOOTING.md** — common issues and fixes

## Support

Check logs:
```bash
openclaw logs --tail 100
```

Verify cluster:
```bash
bash verify-cluster.sh
```

Add users:
```bash
bash add-user.sh
```

## Files

- `install.sh` — Master installer (download this)
- `gabriel-bootstrap.sh` — Full hardware setup (Tailscale, OpenClaw, agents)
- `telegram-setup-cli.sh` — Telegram bot setup (interactive CLI)
- `scripts/verify-cluster.sh` — Check all machines are online
- `scripts/test-agents.sh` — Run test prompts on all agents
- `scripts/add-user.sh` — Add more Telegram users

## Timeline

- First setup: 30-45 minutes (includes software installs)
- Subsequent setups: 5 minutes

## What's Included

✅ 3 AI agents (Franchise, Operations, Streamlining)
✅ Telegram integration (mobile-first)
✅ Access control (whitelist-based)
✅ Persistent memory (never forgets)
✅ Verification rules (zero BS)
✅ Quality balance (cost cuts don't hurt product)
✅ Audit logging (who asked what, when)
✅ Tailscale networking (secure, remote)
✅ Local inference (private, fast)
✅ Full documentation

## License

Proprietary. For Black Sheep Coffee use only.

---

**Questions?** Check TROUBLESHOOTING.md or run:
```bash
openclaw logs --tail 100
```
