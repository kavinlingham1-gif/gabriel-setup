# Quick Start — Gabriel Agents

## 1. Run the Installer

```bash
curl -fsSL https://raw.githubusercontent.com/kavinlingham1-gif/gabriel-setup/main/install.sh | bash
```

## 2. Bootstrap Hardware

Follow the prompts. You'll set up each machine:

**Studio (sovereign-studio-1):**
```bash
bash gabriel-bootstrap.sh
```
- Installs Tailscale
- Installs OpenClaw
- Joins Sovereign network
- Configures Ollama

**Mini 1, 2, 3 (sovereign-3, 4, 5):**
- Same process, run on each Mini
- Takes ~20 min per machine

## 3. Setup Telegram

Once cluster is online:

```bash
bash telegram-setup-cli.sh
```

- Asks for bot token (from @BotFather)
- Detects Telegram group
- Configures access control
- Tests connection

## 4. Use Your Agents

Go to Telegram group "Gabriel Agents":

**Test connection:**
```
@gabriel_coffee_agents_bot /status
```

**Load data:**
```
@bot Remember: Domain $450K/mo, 12 staff. Sixth & Guad $380K/mo, 10 staff. SoCo $320K/mo, 9 staff.
```

**Test each agent:**
```
@bot franchise: Model out Tampa launch. Show me the math.
@bot ops: Which location is overstaffed?
@bot streamline: SoCo labor is 30%. What's the fix?
```

## 5. Verify Everything Works

Run test suite:
```bash
bash test-agents.sh
```

Should see:
- ✅ Franchise agent responds
- ✅ Operations agent responds
- ✅ Streamlining agent responds
- ✅ Access control enforced
- ✅ Memory working

## Done!

Your agents are live. Use them daily. They get smarter with every conversation.

---

**Need help?** See TROUBLESHOOTING.md
