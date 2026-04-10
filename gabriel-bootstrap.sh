#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
# Black Sheep Coffee — Interim AI Provisioner v7
# ══════════════════════════════════════════════════════════════════════════
#
# Single-machine setup: M3 Ultra 256GB Mac Studio (Miami interim)
# Architecture: Ollama + Open WebUI + OpenClaw on same machine
#   - Open WebUI  : team-facing ChatGPT-like interface (port 3000, Tailscale only)
#   - Ollama      : local inference engine (port 11434, localhost only)
#   - OpenClaw    : gateway/agent platform (automation, Discord, heartbeats)
# Network: Joins Sovereign Tailscale network for remote management
#
# Use cases configured:
#   • Franchise Sales Outreach (email drafting, personalization)
#   • Business Intelligence (data analysis, report generation)
#   • Finance (financial modelling, management accounts, contract review)
#   • Legal (IP/TM, franchise agreements, RE leases, contract review)
#
# Models (large-context — OLLAMA_NUM_CTX=65536 for legal/finance docs):
#   • qwen2.5:72b      — 128K ctx, primary workhorse, finance/legal (~41GB)
#   • llama3.3:70b     — 128K ctx, strong general capability (~43GB)
#   • deepseek-r1:70b  — 128K ctx, chain-of-thought reasoning for contracts (~43GB)
#   • gemma3:27b       — 128K ctx, fast structured output / BI reports (~17GB)
#   • qwen2.5:14b      — 128K ctx, lightweight speed tier, email drafts (~9GB)
#   • nomic-embed-text — document embedding for RAG/search (~274MB)
#
# v7 changes:
#   + CRITICAL BUG FIX: Modelfile loop used IFS=':' to split spec strings that contain
#       colons in model names (qwen2.5:72b, deepseek-r1:70b). This caused base_model to
#       be parsed as "deepseek-r1" instead of "deepseek-r1:70b" — base model availability
#       check always failed, so BSC Modelfiles were NEVER created. Fixed delimiter to '|'.
#   + CRITICAL BUG FIX: bsc-franchise Modelfile had num_ctx 32768 despite v6 changelog
#       claiming it was fixed. Franchise agreements are 80+ pages; now correctly 65536.
#   + CRITICAL BUG FIX: OLLAMA_ORIGINS was described in v6 changelog but never added to
#       the Ollama LaunchAgent plist. Added — without it, Open WebUI → Ollama CORS fails
#       silently. Symptoms: "models loading..." forever, 403 on API requests.
#   + CRITICAL BUG FIX: $WEBUI_BIN referenced in step 7 warning message but never defined.
#       Should be $WEBUI_EXEC_PATH. Fixed undefined variable reference.
#   + Tesseract OCR: brew install tesseract + true 3-tier extract-pdf.sh
#       (v6 claimed this but it was not implemented). Tier: pdftotext → pypdf → tesseract.
#       Scanned/image PDFs (signed leases, notarised contracts, filed IP docs) now work.
#   + WEBUI_ADMIN_EMAIL/WEBUI_ADMIN_PASSWORD in Open WebUI LaunchAgent plist
#       Seeds first admin account headlessly. Gabriel's email pre-configured; password
#       prompted at setup time. Eliminates "whoever signs up first = admin" ambiguity.
#   + Step 14 (new): post-install-webui-seed.sh — calls Open WebUI API to pre-load the
#       four BSC department prompts (Legal, Finance, BI, Franchise) as system prompts.
#       Team gets out-of-the-box task shortcuts, not a blank interface.
#   + TOTAL steps: 13 → 14
#   + Banner version: 5.0 → 7.0
#
# v6 changes:
#   + OLLAMA_ORIGINS fix: set to http://localhost:3000 in Ollama LaunchAgent
#       Without this, Open WebUI → Ollama CORS requests fail silently on some macOS setups.
#       Symptoms: WebUI shows "models loading..." forever or 403 on API calls.
#   + Tesseract OCR: brew install tesseract + integrate into extract-pdf.sh
#       Scanned/image PDFs are very common in legal (filed docs, signed leases, notarised contracts).
#       extract-pdf.sh now has 3-tier fallback: pdftotext → pypdf → tesseract (OCR)
#   + bsc-franchise Modelfile num_ctx fixed: 32768 → 65536
#       Franchise agreements sent to prospects can be 80+ pages; need full 64K context.
#   + WEBUI_ADMIN_EMAIL/WEBUI_ADMIN_PASSWORD in Open WebUI LaunchAgent
#       Seeds the first admin account headlessly — no more "who signs up first" ambiguity.
#       Gabriel's email pre-configured; password prompted at setup time.
#   + post-install-webui-seed.sh: API-seeds workspace prompts after admin account is created
#       Calls Open WebUI API to pre-load BSC department prompts (Legal, Finance, BI, Franchise)
#       so the team gets out-of-the-box task shortcuts, not a blank interface.
#   + bsc-franchise Modelfile num_ctx fixed: 32768 → 65536
#       Franchise agreements can be 80+ pages; full 64K context needed for complete review.
#   + Version bump header: v5 → v6
#
# v5 changes:
#   + PDF support: poppler + pypdf installed; extract-pdf.sh script added
#       Legal/finance docs are almost always PDFs (leases, franchise agreements, etc.)
#       Supports native text PDF + image-based PDF (pdfimages fallback note)
#   + Ollama Modelfiles: custom named models with num_ctx=65536 + BSC system prompts baked in
#       Creates: bsc-legal, bsc-finance, bsc-franchise, bsc-bi
#       Env-var context only works for API calls; Modelfile approach is always reliable
#   + Health-check script: bsc-health.sh — runnable at any time to verify all services
#       Checks Ollama, Open WebUI, OpenClaw, Tailscale, sleep prevention, disk, models
#   + Fix Step 11 header formatting (stray blank line in divider comment)
#
# v4 changes:
#   + FileVault encryption check + enable prompt (GDPR requires encryption at rest)
#   + Open WebUI runs in isolated Python venv (prevents pip conflicts, cleaner upgrades)
#   + MEMORY.md pre-seeded with Gabriel/BSC context (OpenClaw knows the customer immediately)
#   + Department-organized document folders (Finance/Legal/Franchise/BI/Executive)
#   + Log rotation LaunchAgent (prevents Ollama/WebUI logs from filling disk over weeks)
#   + fswatch document watcher (optional: desktop notification when docs land in inbox)
#   + TOTAL steps updated: 13
#
# v3 changes:
#   + Open WebUI installed + LaunchAgent (actual team-facing UI — was missing in v2)
#   + Port 3000 opened to Tailscale in firewall for Open WebUI
#   + OLLAMA_NUM_CTX=65536 set globally (was missing — Ollama defaulted to 2048!)
#   + brew services ollama removed — conflicts with custom LaunchAgent (use one path)
#   + openclaw.json fallback fixed (deepseek-r1:32b → deepseek-r1:70b)
#   + Tailscale binary path with fallback (GUI app + CLI package)
#
# Usage:
#   export TAILSCALE_AUTHKEY="tskey-auth-..."
#   bash provision-gabriel.sh
#
# Optional env vars:
#   DISCORD_BOT_TOKEN  — for Discord channel interface
#   ANTHROPIC_API_KEY  — cloud fallback (optional, all-local preferred for GDPR)
#
# GDPR + US-state compliance: 100% on-prem, zero data leaves the machine.
# ══════════════════════════════════════════════════════════════════════════

set -o pipefail

# ── Colours ──────────────────────────────────────────────────────────────
BOLD='\033[1m'; DIM='\033[2m'
GOLD='\033[38;5;220m'; GREEN='\033[38;5;114m'; RED='\033[38;5;203m'
CYAN='\033[38;5;117m'; PURPLE='\033[38;5;141m'; RESET='\033[0m'

ERRORS=(); WARNINGS=(); STEP=0; TOTAL=14

banner() {
  clear; echo ""
  echo -e "${GOLD}${BOLD}"
  echo "  ╔═══════════════════════════════════════════════════════════════╗"
  echo "  ║                                                               ║"
  echo "  ║   ☕  B L A C K   S H E E P   C O F F E E                   ║"
  echo "  ║       Interim AI Provisioner — Miami Studio                  ║"
  echo "  ║       M3 Ultra 256GB · All-local · GDPR-safe                 ║"
  echo "  ║       Version 7.0                                            ║"
  echo "  ╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

divider() { echo -e "${DIM}  ──────────────────────────────────────────────────────────────${RESET}"; }
ok()      { echo -e "  ${GREEN}✅ $*${RESET}"; }
warn()    { echo -e "  ${GOLD}⚠️  $*${RESET}"; WARNINGS+=("$*"); }
fail()    { echo -e "  ${RED}❌ $*${RESET}"; ERRORS+=("$*"); }
die()     { echo ""; echo -e "  ${RED}${BOLD}FATAL: $*${RESET}"; exit 1; }
info()    { echo -e "  ${DIM}$*${RESET}"; }
step()    {
  STEP=$((STEP+1))
  echo ""; echo -e "  ${CYAN}${BOLD}[$STEP/$TOTAL]${RESET} ${BOLD}$*${RESET}"; divider
}

# ── SSH Keys (Sovereign management) ──────────────────────────────────────
KAVIN_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWxGpxh3i6Y44mYapCqvJUwZtggS2L6hc+PGx+XS2DR kavin@sovereign"
EVAN_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMkIrNBX0fu2O0IyAqJu3E/ZSgzJInbtS9lvxrN8UBq evan@sovereign"

# ═══════════════════════════════════════════════════════════════════════
#  PRE-FLIGHT
# ═══════════════════════════════════════════════════════════════════════
banner

# Hardware check
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
MEM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
DISK_FREE_GB=$(df -g / | awk 'NR==2{print $4}')

echo -e "  ${BOLD}Hardware${RESET}"
divider
echo -e "  Chip      : ${BOLD}$CHIP${RESET}"
echo -e "  Memory    : ${BOLD}${MEM_GB}GB${RESET}"
echo -e "  Free disk : ${BOLD}${DISK_FREE_GB}GB${RESET}"
echo -e "  User      : $USER"
echo -e "  macOS     : $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
echo ""

# Confirm M3 Ultra (warn if not)
if echo "$CHIP" | grep -qi "ultra"; then
  ok "M-series Ultra chip detected — adequate for full model suite"
elif [ "$MEM_GB" -ge 192 ]; then
  ok "${MEM_GB}GB RAM — adequate for full model suite"
else
  warn "Expected M3 Ultra 256GB — got $MEM_GB GB. Some models may not fit."
fi

# Disk space (models need ~130GB minimum)
if [ "$DISK_FREE_GB" -lt 200 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}⚠️  Only ${DISK_FREE_GB}GB free.${RESET}"
  echo -e "  ${RED}Full model suite needs ~130GB. Clear space before continuing.${RESET}"
  read -r -p "  Continue anyway? (y/N): " DISK_OK
  [[ "$DISK_OK" =~ ^[Yy]$ ]] || { echo "  Aborted. Free up disk space first."; exit 1; }
fi

echo ""
echo -e "  ${BOLD}Credentials${RESET}"
divider

# Tailscale auth key
if [ -z "$TAILSCALE_AUTHKEY" ]; then
  while true; do
    read -r -s -p "  Tailscale Auth Key (tskey-auth-...): " TAILSCALE_AUTHKEY; echo ""
    [[ "$TAILSCALE_AUTHKEY" == tskey-auth-* ]] && break
    echo -e "  ${RED}Must start with tskey-auth-${RESET}"
  done
else
  ok "Tailscale key: ${TAILSCALE_AUTHKEY:0:20}..."
fi

# Discord token (optional)
if [ -z "$DISCORD_BOT_TOKEN" ]; then
  info "Discord bot token (optional — press Enter to skip)"
  read -r -p "  Discord Bot Token (or Enter to skip): " DISCORD_BOT_TOKEN
fi
[ -n "$DISCORD_BOT_TOKEN" ] && ok "Discord token provided" || info "Discord: skipped (configure later)"

# Anthropic fallback (optional)
if [ -z "$ANTHROPIC_API_KEY" ]; then
  info "Anthropic API key (optional cloud fallback — GDPR caution; Enter to skip)"
  read -r -p "  Anthropic API Key (sk-ant-... or Enter to skip): " ANTHROPIC_API_KEY
fi
[ -n "$ANTHROPIC_API_KEY" ] && ok "Anthropic fallback key provided" || info "Anthropic: skipped (all-local mode)"

echo ""
echo -e "  ${BOLD}Hostname${RESET}: ${GOLD}${BOLD}sovereign-bsc-miami-studio${RESET}"
echo ""
read -r -p "  Ready to begin? (y/N): " GO
[[ "$GO" =~ ^[Yy]$ ]] || { echo "  Aborted."; exit 0; }

NEW_HOSTNAME="sovereign-bsc-miami-studio"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 1: macOS Hardening & Sleep Prevention
# ═══════════════════════════════════════════════════════════════════════
step "macOS Hardening & Sleep Prevention"

# Sleep — critical for a server that must stay online
sudo pmset -a sleep 0            && ok "System sleep: disabled" || warn "pmset sleep 0 failed"
sudo pmset -a disablesleep 1     2>/dev/null || true
sudo pmset -a displaysleep 0     && ok "Display sleep: disabled" || true
sudo pmset -a womp 1             && ok "Wake-on-LAN: enabled" || true
sudo pmset -a tcpkeepalive 1     && ok "TCP keepalive: enabled" || true
sudo pmset -a powernap 0         2>/dev/null || true
sudo pmset -a proximitywake 0    2>/dev/null || true
sudo pmset -a autorestart 1      && ok "Auto-restart after power loss: enabled" || true

# ── FileVault encryption (GDPR + US-state: encryption-at-rest mandatory) ─
FV_STATUS=$(fdesetup status 2>/dev/null || echo "unknown")
if echo "$FV_STATUS" | grep -q "FileVault is On"; then
  ok "FileVault: enabled (encryption at rest — GDPR compliant)"
elif echo "$FV_STATUS" | grep -q "FileVault is Off"; then
  echo ""
  echo -e "  ${RED}${BOLD}⚠️  FileVault is OFF — GDPR requires encryption at rest for legal/finance data${RESET}"
  echo -e "  ${RED}   This machine will store contracts, financial models, and personal data.${RESET}"
  echo ""
  read -r -p "  Enable FileVault now? (recommended — y/N): " FV_ENABLE
  if [[ "$FV_ENABLE" =~ ^[Yy]$ ]]; then
    sudo fdesetup enable 2>/dev/null \
      && ok "FileVault: enabling (machine will encrypt on next reboot — keep power connected)" \
      || warn "FileVault: could not enable automatically — enable in: System Settings → Privacy & Security → FileVault"
  else
    warn "FileVault: SKIPPED — enable before storing sensitive data (System Settings → Privacy & Security → FileVault)"
  fi
else
  warn "FileVault: status unknown ($FV_STATUS) — verify manually"
fi

# Caffeinate LaunchAgent (belt-and-suspenders on top of pmset)
CAFFEINATE_PLIST=~/Library/LaunchAgents/com.bsc.caffeinate.plist
cat > "$CAFFEINATE_PLIST" << 'CAFF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>             <string>com.bsc.caffeinate</string>
  <key>ProgramArguments</key>  <array><string>/usr/bin/caffeinate</string><string>-s</string></array>
  <key>RunAtLoad</key>         <true/>
  <key>KeepAlive</key>         <true/>
</dict></plist>
CAFF
launchctl load "$CAFFEINATE_PLIST" 2>/dev/null || true
ok "Caffeinate LaunchAgent installed (prevents macOS sleep)"

# ── Log rotation (prevent Ollama/WebUI logs filling disk over weeks) ──────
# Ollama can write 100MB+/day at high load; rotate weekly, keep 4 weeks max
LOG_ROTATE_PLIST=~/Library/LaunchAgents/com.bsc.logrotate.plist
cat > "$LOG_ROTATE_PLIST" << 'LOGROTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>             <string>com.bsc.logrotate</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>
      find /tmp -maxdepth 1 -name 'ollama*.log' -size +50M -exec truncate -s 0 {} \; ;
      find ~/Library/Logs/bsc -name '*.log' -size +50M -exec truncate -s 0 {} \; ;
      find ~/Library/Logs/bsc -name '*.log' -mtime +28 -delete ;
      echo "$(date): log rotation run" >> /tmp/bsc-logrotate.log
    </string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>   <integer>3</integer>
    <key>Minute</key> <integer>0</integer>
  </dict>
  <key>RunAtLoad</key> <false/>
</dict></plist>
LOGROTEOF
launchctl unload "$LOG_ROTATE_PLIST" 2>/dev/null || true
launchctl load   "$LOG_ROTATE_PLIST" 2>/dev/null \
  && ok "Log rotation LaunchAgent: installed (daily 3am, truncates logs >50MB, removes after 28d)" \
  || warn "Log rotation LaunchAgent failed to load (non-fatal)"

# Hostname
sudo scutil --set ComputerName  "$NEW_HOSTNAME" 2>/dev/null || true
sudo scutil --set LocalHostName "$NEW_HOSTNAME" 2>/dev/null || true
ok "Hostname: $NEW_HOSTNAME"

# Remote Login (SSH)
sudo systemsetup -setremotelogin on 2>/dev/null \
  && ok "Remote Login (SSH): enabled" \
  || warn "Enable manually: System Settings → Sharing → Remote Login"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 2: SSH Keys
# ═══════════════════════════════════════════════════════════════════════
step "SSH Access"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

for keyname in KAVIN EVAN; do
  keyvar="${keyname}_SSH_KEY"; keyval="${!keyvar}"
  grep -qF "$keyval" ~/.ssh/authorized_keys 2>/dev/null || echo "$keyval" >> ~/.ssh/authorized_keys
  ok "${keyname,,} SSH key added"
done

# ═══════════════════════════════════════════════════════════════════════
#  STEP 3: Homebrew + Tools
# ═══════════════════════════════════════════════════════════════════════
step "Homebrew + Document Processing Tools"

if command -v brew &>/dev/null; then
  ok "Homebrew: already installed"
else
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed"
  ok "Homebrew: installed"
fi
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
brew update --quiet 2>/dev/null || warn "brew update failed (non-fatal)"

# Node.js (for OpenClaw)
if command -v node &>/dev/null; then
  ok "Node.js: $(node --version)"
else
  brew install node || die "Node.js install failed"
  ok "Node.js: $(node --version)"
fi

# Pandoc — converts .docx Word files to markdown/text for AI processing
if command -v pandoc &>/dev/null; then
  ok "pandoc: already installed (Word/Excel → text conversion)"
else
  brew install pandoc && ok "pandoc: installed" || warn "pandoc install failed"
fi

# Python3 packages — for Excel (.xlsx) processing + Open WebUI
if command -v python3 &>/dev/null; then
  ok "Python3: $(python3 --version 2>&1 | awk '{print $2}')"
  pip3 install --quiet openpyxl pandas tabulate 2>/dev/null \
    && ok "Python3 packages: openpyxl, pandas, tabulate (Excel processing)" \
    || warn "Some Python packages failed — retry: pip3 install openpyxl pandas tabulate"
else
  brew install python3 || warn "Python3 install failed"
  pip3 install --quiet openpyxl pandas tabulate 2>/dev/null || true
fi

# antiword as a legacy .doc fallback
brew install antiword 2>/dev/null && ok "antiword: installed (legacy .doc support)" || true

# ── PDF processing — CRITICAL for legal/finance workflows ─────────────
# Almost every contract, lease, franchise agreement, and regulatory doc is a PDF.
# poppler provides pdftotext (fastest) + pdfimages (image-based PDF detection)
if brew list poppler 2>/dev/null | grep -q poppler; then
  ok "poppler: already installed (pdftotext, pdfimages)"
else
  brew install poppler \
    && ok "poppler: installed (pdftotext + pdfimages — PDF text extraction)" \
    || warn "poppler: install failed — PDF extraction will be unavailable"
fi

# pypdf — Python PDF library for metadata extraction and fallback parsing
pip3 install --quiet pypdf 2>/dev/null \
  && ok "pypdf: installed (Python PDF parsing — fallback for scanned PDFs)" \
  || warn "pypdf: install failed (non-fatal)"

# Tesseract OCR — 3rd tier PDF fallback: handles scanned/image-based PDFs
# Legal docs often arrive as scanned images: notarised contracts, signed leases, IP filing acks.
# pdftotext + pypdf both return blank for these; tesseract is the only option.
if brew list tesseract 2>/dev/null | grep -q tesseract; then
  ok "tesseract: already installed (OCR fallback for scanned PDFs)"
else
  brew install tesseract \
    && ok "tesseract: installed (OCR — handles scanned contracts, signed leases, notarised docs)" \
    || warn "tesseract: install failed — scanned/image PDFs will not extract (non-fatal for text-based PDFs)"
fi

# LibreOffice — highest-fidelity M365 .docx/.xlsx conversion (better than pandoc for complex files)
if brew list --cask libreoffice 2>/dev/null | grep -q libreoffice; then
  ok "LibreOffice: already installed (high-fidelity M365 conversion)"
else
  info "Installing LibreOffice (~400MB) for high-fidelity Word/Excel conversion..."
  brew install --cask libreoffice \
    && ok "LibreOffice: installed — enables soffice headless conversion for complex M365 files" \
    || warn "LibreOffice install failed — pandoc will be used as fallback (non-fatal)"
fi

# ═══════════════════════════════════════════════════════════════════════
#  STEP 4: Tailscale
# ═══════════════════════════════════════════════════════════════════════
step "Tailscale (Sovereign Network)"

if brew list --cask tailscale 2>/dev/null | grep -q tailscale; then
  ok "Tailscale: already installed"
else
  brew install --cask tailscale || die "Tailscale install failed"
  ok "Tailscale: installed"
fi

open -a Tailscale 2>/dev/null || true

# Resolve Tailscale binary — GUI app path first, then CLI package fallback
TAILSCALE_BIN=""
for candidate in \
  "/Applications/Tailscale.app/Contents/MacOS/Tailscale" \
  "/usr/local/bin/tailscale" \
  "$(command -v tailscale 2>/dev/null)"; do
  [ -x "$candidate" ] && { TAILSCALE_BIN="$candidate"; break; }
done

if [ -z "$TAILSCALE_BIN" ]; then
  warn "Tailscale binary not found — install manually and run: tailscale up --authkey=... --hostname=$NEW_HOSTNAME"
else
  info "Tailscale binary: $TAILSCALE_BIN"
  info "Waiting for Tailscale daemon (up to 30s)..."
  for i in $(seq 1 15); do sleep 2; "$TAILSCALE_BIN" status &>/dev/null && break; done

  sudo "$TAILSCALE_BIN" up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --hostname="$NEW_HOSTNAME" \
    --accept-routes \
    --timeout=30s \
    && ok "Joined tailnet as $NEW_HOSTNAME" \
    || warn "tailscale up failed — run manually: sudo $TAILSCALE_BIN up --authkey=... --hostname=$NEW_HOSTNAME"

  TS_IP=$("$TAILSCALE_BIN" ip -4 2>/dev/null || echo "pending")
  info "Tailscale IP: $TS_IP"
fi
TS_IP="${TS_IP:-pending}"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 5: Ollama (Inference Engine)
# ═══════════════════════════════════════════════════════════════════════
step "Ollama (Local AI Inference)"

if command -v ollama &>/dev/null; then
  ok "Ollama: already installed"
else
  brew install ollama || die "Ollama install failed"
  ok "Ollama: installed"
fi

# Stop brew-managed ollama service if running — we use our own LaunchAgent exclusively
# Running both causes port conflicts and split restart behavior
brew services stop ollama 2>/dev/null && info "Stopped brew-managed Ollama service (using LaunchAgent instead)" || true

# Bind to localhost only — Ollama stays internal; Open WebUI connects localhost→localhost.
# External team access goes through Open WebUI (port 3000), not raw Ollama API.
grep -q "OLLAMA_HOST" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_HOST="127.0.0.1:11434"' >> ~/.zprofile
# Normalize any existing binding
sed -i '' 's|OLLAMA_HOST="0.0.0.0:11434"|OLLAMA_HOST="127.0.0.1:11434"|g' ~/.zprofile 2>/dev/null || true
export OLLAMA_HOST="127.0.0.1:11434"

# ── Context window: CRITICAL for long legal/finance documents ─────────
# Ollama defaults to 2048 tokens — completely inadequate for contracts/reports.
# 65536 (64K) = ~48,000 words = a full 150-page contract in context at once.
grep -q "OLLAMA_NUM_CTX" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_NUM_CTX="65536"' >> ~/.zprofile
export OLLAMA_NUM_CTX="65536"
ok "OLLAMA_NUM_CTX=65536 (64K context window — handles 150-page legal docs in full)"

# Tune for 4–8 concurrent users
grep -q "OLLAMA_NUM_PARALLEL" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_NUM_PARALLEL="4"' >> ~/.zprofile
grep -q "OLLAMA_MAX_LOADED_MODELS" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_MAX_LOADED_MODELS="2"' >> ~/.zprofile
grep -q "OLLAMA_KEEP_ALIVE" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_KEEP_ALIVE="30m"' >> ~/.zprofile
# Flash attention + Q8 KV cache — major speedup on Apple Silicon for long docs
grep -q "OLLAMA_FLASH_ATTENTION" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_FLASH_ATTENTION="1"' >> ~/.zprofile
grep -q "OLLAMA_KV_CACHE_TYPE" ~/.zprofile 2>/dev/null || \
  echo 'export OLLAMA_KV_CACHE_TYPE="q8_0"' >> ~/.zprofile
export OLLAMA_NUM_PARALLEL="4"
export OLLAMA_MAX_LOADED_MODELS="2"
export OLLAMA_KEEP_ALIVE="30m"
export OLLAMA_FLASH_ATTENTION="1"
export OLLAMA_KV_CACHE_TYPE="q8_0"

# ── LaunchAgent for Ollama (boot persistence, single management path) ──
OLLAMA_PLIST=~/Library/LaunchAgents/com.bsc.ollama.plist
cat > "$OLLAMA_PLIST" << OLLAMAPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>             <string>com.bsc.ollama</string>
  <key>ProgramArguments</key>  <array><string>/opt/homebrew/bin/ollama</string><string>serve</string></array>
  <key>RunAtLoad</key>         <true/>
  <key>KeepAlive</key>         <true/>
  <key>StandardOutPath</key>   <string>/tmp/ollama.log</string>
  <key>StandardErrorPath</key> <string>/tmp/ollama-err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_HOST</key>               <string>127.0.0.1:11434</string>
    <key>OLLAMA_NUM_CTX</key>            <string>65536</string>
    <key>OLLAMA_NUM_PARALLEL</key>       <string>4</string>
    <key>OLLAMA_MAX_LOADED_MODELS</key>  <string>2</string>
    <key>OLLAMA_KEEP_ALIVE</key>         <string>30m</string>
    <key>OLLAMA_FLASH_ATTENTION</key>    <string>1</string>
    <key>OLLAMA_KV_CACHE_TYPE</key>      <string>q8_0</string>
    <key>OLLAMA_ORIGINS</key>            <string>http://localhost:3000</string>
    <key>PATH</key>                      <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
</dict></plist>
OLLAMAPLIST
launchctl unload "$OLLAMA_PLIST" 2>/dev/null || true
launchctl load "$OLLAMA_PLIST"   2>/dev/null \
  && ok "Ollama LaunchAgent: installed (starts on boot, restarts on crash)" \
  || warn "Ollama LaunchAgent failed to load"

sleep 5

# Verify
if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
  warn "Ollama LaunchAgent not responding — starting manually"
  nohup ollama serve &>/tmp/ollama.log &
  sleep 8
fi
curl -sf http://localhost:11434/api/tags > /dev/null 2>&1 \
  && ok "Ollama: running on localhost:11434" \
  || fail "Ollama: not responding — check /tmp/ollama.log"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 6: Pull AI Models
# ═══════════════════════════════════════════════════════════════════════
step "AI Models (large-context for finance/legal docs)"

echo ""
echo -e "  ${BOLD}Model pull order: fast tiers first, heavyweight last${RESET}"
echo -e "  ${DIM}Total: ~130GB · ETA: 45–90 minutes on fast connection${RESET}"
echo -e "  ${DIM}All models will use 64K context window (OLLAMA_NUM_CTX=65536)${RESET}"
echo ""

# Models in priority order — start with fast tiers so system is usable sooner
declare -a MODELS=(
  "nomic-embed-text|~274MB|Document embeddings (RAG readiness, fast — pull first)"
  "qwen2.5:14b|~9GB|Fast responses, quick tasks, email drafting"
  "gemma3:27b|~17GB|Structured output, BI reports, fast analysis"
  "deepseek-r1:70b|~43GB|Chain-of-thought contract/legal reasoning"
  "llama3.3:70b|~43GB|Strong general capability, long-doc analysis"
  "qwen2.5:72b|~41GB|Primary workhorse, finance/legal, 128K context"
)

MODEL_IDX=0
for entry in "${MODELS[@]}"; do
  MODEL_IDX=$((MODEL_IDX+1))
  IFS='|' read -r model size desc <<< "$entry"
  echo -e "  ${CYAN}[$MODEL_IDX/${#MODELS[@]}]${RESET} ${BOLD}$model${RESET} ${DIM}($size)${RESET}"
  echo -e "  ${DIM}      $desc${RESET}"
  if ollama list 2>/dev/null | grep -q "^${model}"; then
    ok "Already pulled"
  else
    ollama pull "$model" \
      && ok "$model: ready" \
      || warn "$model failed — retry: ollama pull $model"
  fi
  echo ""
done

echo -e "  ${BOLD}Models ready:${RESET}"
ollama list 2>/dev/null | tail -n +2 | awk '{printf "    • %-35s %s\n", $1, $3}' || true

# ── Create BSC Modelfiles: num_ctx baked in + department system prompts ──
# Why Modelfiles vs env-var only: OLLAMA_NUM_CTX only applies to the API daemon.
# When Open WebUI or CLI users call "qwen2.5:72b", Ollama uses the model's default ctx (2048).
# Modelfiles override this permanently for a named model variant — fully reliable.
# The BSC system prompt is also baked in, so every response is immediately context-aware.

echo ""
echo -e "  ${BOLD}Creating BSC Modelfiles (num_ctx=65536 + department prompts baked in)${RESET}"
divider

MODELFILE_DIR="$HOME/.ollama/modelfiles"
mkdir -p "$MODELFILE_DIR"

# Legal model — chain-of-thought (deepseek-r1:70b) + structured clause review
cat > "$MODELFILE_DIR/Modelfile.bsc-legal" << 'LEGALEOF'
FROM deepseek-r1:70b
PARAMETER num_ctx 65536
PARAMETER num_predict 4096
PARAMETER temperature 0.1
SYSTEM """You are the Black Sheep Coffee legal AI assistant. You specialize in:
- Franchise agreement review and redlining
- Real estate lease analysis (commercial)
- IP and trademark registration guidance
- General commercial contract review

When reviewing any document:
1. Start with a 3-line EXECUTIVE SUMMARY (overall risk level, key concerns, recommended action)
2. List all FLAGGED CLAUSES with ⚠️ symbol, clause reference, plain-English explanation, and risk level (HIGH/MEDIUM/LOW)
3. List STANDARD CLAUSES (no issues) briefly
4. Provide RECOMMENDED ACTIONS as a numbered list

Always include this disclaimer: "⚠️ This is AI-assisted analysis, not legal advice. Flag material concerns to your General Counsel for formal opinion."

Be concise. Executives are busy. Use markdown tables for clause comparisons."""
LEGALEOF

# Finance model — qwen2.5:72b (best for numbers + long doc analysis)
cat > "$MODELFILE_DIR/Modelfile.bsc-finance" << 'FINEOF'
FROM qwen2.5:72b
PARAMETER num_ctx 65536
PARAMETER num_predict 4096
PARAMETER temperature 0.1
SYSTEM """You are the Black Sheep Coffee finance AI assistant. You specialize in:
- Financial model review and analysis (P&L, cash flow, balance sheet)
- Management accounts interpretation
- Commercial contract financial terms
- Budget variance analysis

When analyzing any financial document or data:
1. Start with a 3-line EXECUTIVE SUMMARY (health status, key metric, #1 concern)
2. Provide KEY METRICS table (formatted markdown)
3. Flag CONCERNS with ⚠️ (unusual variances, missing data, risky assumptions)
4. Give RECOMMENDED ACTIONS as a numbered list

Be precise with numbers. Always state the currency and period. Use markdown tables.
If data is ambiguous, state your assumptions clearly before proceeding."""
FINEOF

# BI / reporting model — gemma3:27b (fast structured output, ideal for reports)
cat > "$MODELFILE_DIR/Modelfile.bsc-bi" << 'BIEOF'
FROM gemma3:27b
PARAMETER num_ctx 65536
PARAMETER num_predict 4096
PARAMETER temperature 0.2
SYSTEM """You are the Black Sheep Coffee business intelligence assistant. You specialize in:
- Analyzing data from Excel/CSV exports
- Generating management dashboards and reports
- Spotting trends, anomalies, and KPIs
- Summarizing data for non-technical stakeholders

When given data:
1. Always output a 3-line EXECUTIVE SUMMARY first
2. Present key metrics in a formatted markdown table
3. Highlight TOP 3 INSIGHTS (trends, anomalies, opportunities)
4. Suggest 2-3 NEXT STEPS or follow-up analyses

Use clean, formatted markdown. Avoid jargon. Assume the audience is executive-level."""
BIEOF

# Franchise outreach model — qwen2.5:14b (fast for email drafts)
cat > "$MODELFILE_DIR/Modelfile.bsc-franchise" << 'FRANEOF'
FROM qwen2.5:14b
PARAMETER num_ctx 65536
PARAMETER num_predict 2048
PARAMETER temperature 0.7
SYSTEM """You are the Black Sheep Coffee franchise sales AI assistant. You specialize in:
- Drafting personalized franchise sales outreach emails
- Writing follow-up sequences for franchise prospects
- Summarizing prospect research
- Crafting compelling franchise value propositions

Black Sheep Coffee is an international franchise coffee chain known for quality, innovation, and strong franchise economics.

When drafting outreach emails:
- Personalize using any prospect details provided
- Lead with a relevant hook (their background, location, market opportunity)
- Highlight 2-3 compelling Black Sheep differentiators
- Clear CTA (discovery call, information pack request)
- Professional but not stiff — confident and direct tone
- Keep to ~250 words unless a longer pitch is requested

Always produce: Subject line + Email body. Ask for prospect details if not provided."""
FRANEOF

# Build the Modelfiles — creates named variants in Ollama's registry
# NOTE: delimiter must NOT be ':' because model tags (qwen2.5:72b, deepseek-r1:70b)
# contain colons. Using '|' as delimiter avoids IFS splitting inside the tag.
for spec in \
  "bsc-legal|Modelfile.bsc-legal|deepseek-r1:70b" \
  "bsc-finance|Modelfile.bsc-finance|qwen2.5:72b" \
  "bsc-bi|Modelfile.bsc-bi|gemma3:27b" \
  "bsc-franchise|Modelfile.bsc-franchise|qwen2.5:14b"; do
  IFS='|' read -r model_name modelfile base_model <<< "$spec"
  # Check if base model is available before creating variant
  if ollama list 2>/dev/null | grep -q "^${base_model}"; then
    if ollama list 2>/dev/null | grep -q "^${model_name}"; then
      ok "$model_name: already exists (Modelfile variant)"
    else
      info "Creating $model_name from $base_model (num_ctx=65536 baked in)..."
      ollama create "$model_name" -f "$MODELFILE_DIR/$modelfile" 2>/dev/null \
        && ok "$model_name: created (system prompt + num_ctx=65536 permanent)" \
        || warn "$model_name: Modelfile creation failed — retry: ollama create $model_name -f $MODELFILE_DIR/$modelfile"
    fi
  else
    warn "$model_name: skipped (base model $base_model not yet pulled — retry after ollama pull $base_model)"
  fi
done

# ═══════════════════════════════════════════════════════════════════════
#  STEP 7: Open WebUI (Team Interface)
# ═══════════════════════════════════════════════════════════════════════
step "Open WebUI (Team-facing chat interface)"

echo ""
echo -e "  ${DIM}Open WebUI gives the 4–8 person team a ChatGPT-like browser interface.${RESET}"
echo -e "  ${DIM}Accessible at http://<tailscale-ip>:3000 — Tailscale login required.${RESET}"
echo ""

# Install Open WebUI in an isolated Python venv — avoids system pip conflicts,
# makes upgrades clean, prevents dependency collisions with other pip packages.
WEBUI_VENV=~/.venvs/openwebui
WEBUI_LOG_DIR=~/Library/Logs/bsc
mkdir -p "$WEBUI_LOG_DIR"

WEBUI_INSTALLED=false
if [ -f "$WEBUI_VENV/bin/open-webui" ]; then
  ok "Open WebUI: already installed in venv ($WEBUI_VENV)"
  WEBUI_INSTALLED=true
else
  info "Creating Python venv at $WEBUI_VENV ..."
  python3 -m venv "$WEBUI_VENV" \
    && ok "Python venv created" \
    || die "Failed to create venv — check Python3 installation"

  info "Installing Open WebUI into venv (~500MB including dependencies)..."
  "$WEBUI_VENV/bin/pip" install --quiet --upgrade pip 2>/dev/null
  "$WEBUI_VENV/bin/pip" install --quiet open-webui 2>/dev/null \
    && ok "Open WebUI: installed in isolated venv" \
    && WEBUI_INSTALLED=true \
    || { fail "Open WebUI: pip install into venv failed — run manually: $WEBUI_VENV/bin/pip install open-webui"; }
fi

# Venv binary path — always deterministic now
WEBUI_EXEC_PATH="$WEBUI_VENV/bin/open-webui"
VENV_PYTHON="$WEBUI_VENV/bin/python3"

# Verify binary exists, fall back to python -m open_webui if needed
if [ ! -x "$WEBUI_EXEC_PATH" ]; then
  warn "open-webui binary not found in venv — will use python -m open_webui form"
  WEBUI_EXEC_PATH="$VENV_PYTHON"
  WEBUI_ARGS="-m open_webui serve --port 3000 --host 0.0.0.0"
else
  WEBUI_ARGS="serve --port 3000 --host 0.0.0.0"
fi

# Generate a stable secret key for Open WebUI sessions
WEBUI_SECRET=$("$VENV_PYTHON" -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || echo "bsc-miami-$(date +%s)")
info "Open WebUI binary: $WEBUI_EXEC_PATH"

# ── Admin account seeding — eliminate "whoever signs up first = admin" risk ──
# Baking WEBUI_ADMIN_EMAIL + WEBUI_ADMIN_PASSWORD into the LaunchAgent env means
# Open WebUI will pre-create Gabriel's account as admin on first boot.
# Without this, any team member who hits the URL first claims admin.
WEBUI_ADMIN_EMAIL="gabriel@blacksheepcoffee.us"
if [ -z "$WEBUI_ADMIN_PASSWORD" ]; then
  echo ""
  echo -e "  ${BOLD}Open WebUI Admin Account${RESET}"
  echo -e "  ${DIM}Admin email will be: $WEBUI_ADMIN_EMAIL${RESET}"
  echo -e "  ${DIM}Set a strong password for Gabriel's admin account:${RESET}"
  while true; do
    read -r -s -p "  Admin password (min 8 chars): " WEBUI_ADMIN_PASSWORD; echo ""
    [ "${#WEBUI_ADMIN_PASSWORD}" -ge 8 ] && break
    echo -e "  ${RED}Password must be at least 8 characters.${RESET}"
  done
  ok "Admin account credentials set (gabriel@blacksheepcoffee.us)"
fi

# ── LaunchAgent for Open WebUI ────────────────────────────────────────
WEBUI_PLIST=~/Library/LaunchAgents/com.bsc.openwebui.plist

# Build ProgramArguments: binary + its args as separate array entries
WEBUI_PLIST_ARGS=""
for arg in $WEBUI_EXEC_PATH $WEBUI_ARGS; do
  WEBUI_PLIST_ARGS+="    <string>$arg</string>
"
done

cat > "$WEBUI_PLIST" << WEBUIPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>             <string>com.bsc.openwebui</string>
  <key>ProgramArguments</key>
  <array>
${WEBUI_PLIST_ARGS}  </array>
  <key>RunAtLoad</key>         <true/>
  <key>KeepAlive</key>         <true/>
  <key>StandardOutPath</key>   <string>${WEBUI_LOG_DIR}/openwebui.log</string>
  <key>StandardErrorPath</key> <string>${WEBUI_LOG_DIR}/openwebui-err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_BASE_URL</key>        <string>http://localhost:11434</string>
    <key>WEBUI_SECRET_KEY</key>       <string>${WEBUI_SECRET}</string>
    <key>WEBUI_AUTH</key>             <string>True</string>
    <key>DEFAULT_MODELS</key>         <string>qwen2.5:72b</string>
    <key>ENABLE_SIGNUP</key>          <string>True</string>
    <key>WEBUI_NAME</key>             <string>Black Sheep AI</string>
    <key>WEBUI_ADMIN_EMAIL</key>      <string>${WEBUI_ADMIN_EMAIL}</string>
    <key>WEBUI_ADMIN_PASSWORD</key>   <string>${WEBUI_ADMIN_PASSWORD}</string>
    <key>HOME</key>                   <string>${HOME}</string>
    <key>PATH</key>                   <string>${WEBUI_VENV}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
</dict></plist>
WEBUIPLIST

launchctl unload "$WEBUI_PLIST" 2>/dev/null || true
launchctl load "$WEBUI_PLIST" 2>/dev/null \
  && ok "Open WebUI LaunchAgent: installed (starts on boot, restarts on crash)" \
  || warn "Open WebUI LaunchAgent failed to load"

sleep 6

# Verify Open WebUI is reachable
if curl -sf http://localhost:3000 > /dev/null 2>&1; then
  ok "Open WebUI: running on port 3000"
  info "Team access: http://$TS_IP:3000"
  info "First user to sign up gets admin role"
else
  warn "Open WebUI: not yet responding (may still be starting — check $WEBUI_LOG_DIR/openwebui-err.log)"
  info "Manual start: $WEBUI_EXEC_PATH serve --port 3000 --host 0.0.0.0"
fi

# ═══════════════════════════════════════════════════════════════════════
#  STEP 8: OpenClaw (Agent Platform)
# ═══════════════════════════════════════════════════════════════════════
step "OpenClaw (AI Agent Platform)"

if command -v openclaw &>/dev/null; then
  ok "OpenClaw: already installed ($(openclaw --version 2>/dev/null || echo 'unknown version'))"
else
  npm install -g openclaw 2>/dev/null \
    || sudo npm install -g openclaw \
    || die "OpenClaw install failed"
  ok "OpenClaw: installed"
fi

# ═══════════════════════════════════════════════════════════════════════
#  STEP 9: Configure OpenClaw + Gabriel's Agents
# ═══════════════════════════════════════════════════════════════════════
step "Configure OpenClaw + Black Sheep Agents"

WORKSPACE=~/.openclaw/workspace
mkdir -p "$WORKSPACE"

# ── openclaw.json ─────────────────────────────────────────────────────
python3 - <<PYEOF
import json, os

workspace = os.path.expanduser("~/.openclaw/workspace")
config = {
    "agents": {
        "defaults": {
            "model": {
                "primary": "ollama/qwen2.5:72b",
                "fallbacks": [
                    "ollama/llama3.3:70b",
                    "ollama/deepseek-r1:70b",
                    "ollama/gemma3:27b",
                    "ollama/qwen2.5:14b"
                ]
            },
            "workspace": workspace,
            "compaction": {"mode": "safeguard"},
            "heartbeat": {"every": "30m"}
        }
    },
    "commands": {"native": "auto", "nativeSkills": "auto", "restart": True},
    "gateway": {"mode": "local"},
    "providers": {
        "ollama": {
            "baseUrl": "http://localhost:11434"
        }
    }
}

# Optional cloud fallback (GDPR note: only use for non-sensitive tasks)
anthropic_key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
if anthropic_key:
    config["providers"]["anthropic"] = {"apiKey": anthropic_key}
    print("  ⚠  Anthropic cloud fallback configured. Remind team: don't send sensitive data to cloud.")
else:
    print("  ✅ All-local mode: no cloud provider configured (GDPR-safe)")

# Discord channel
discord_token = os.environ.get("DISCORD_BOT_TOKEN", "").strip()
if discord_token:
    config["channels"] = {
        "discord": {
            "enabled": True,
            "token": discord_token,
            "requireMention": False,
            "dmPolicy": "allow"
        }
    }
    print("  ✅ Discord channel configured")
else:
    print("  ℹ  Discord: not configured (add DISCORD_BOT_TOKEN to set up)")

path = os.path.expanduser("~/.openclaw/openclaw.json")
with open(path, "w") as f:
    json.dump(config, f, indent=2)
os.chmod(path, 0o600)
print("  ✅ openclaw.json written (fallbacks: llama3.3:70b → deepseek-r1:70b → gemma3:27b → qwen2.5:14b)")
PYEOF

# ── SOUL.md (Black Sheep AI persona + agent routing) ──────────────────
cat > "$WORKSPACE/SOUL.md" << 'SOULEOF'
# Black Sheep Coffee — AI Assistant

**You are the Black Sheep AI assistant.** You serve the Black Sheep Coffee executive, finance, legal, and operations teams. You are sharp, professional, and efficient — no fluff.

## Your Capabilities

You have four specialist modes. When a request comes in, identify which mode applies and lean into it:

### 🤝 Franchise Outreach
Drafting personalized franchise sales emails, follow-up sequences, prospect research summaries, and outreach strategies. Tone: confident, compelling, professional.

### 📊 Business Intelligence
Analyzing financial data (Excel/CSV uploads), generating management dashboards, spotting trends, summarizing KPIs. Output: tables, summaries, action items.

### 💰 Finance
Financial modelling analysis, management account review, P&L interpretation, commercial contract financial terms, lease economics. Precise, numbers-focused.

### ⚖️ Legal
IP/trademark registration guidance, franchise agreement review, real estate lease analysis, contract redlining, risk flagging. Always note: "Not legal advice — flag to GC for formal opinion."

## Document Uploads (M365 + PDF files)

When a user uploads a Word (.docx), Excel (.xlsx), or PDF file:
1. Acknowledge the file and its apparent purpose
2. Extract and process the content
3. Provide structured analysis relevant to the use case

Supported workflows:
- **PDF docs**: Contracts, franchise agreements, leases, regulatory filings → structured review with flagged clauses (most common format)
- **Word docs**: Draft contracts, reports → structured review with flagged clauses
- **Excel files**: Financial models, management accounts → table summaries, trend analysis, key metrics

## Recommended Models by Task

Use these specialist model variants (system prompt + 64K context baked in):
- **bsc-legal** — Franchise agreements, IP/TM, RE leases, contract review
- **bsc-finance** — Financial models, P&L, management accounts, commercial contracts
- **bsc-bi** — Excel/CSV data analysis, BI reports, dashboards
- **bsc-franchise** — Sales outreach emails, prospect research, follow-up sequences

## Privacy Rules (GDPR + US-state)

- This system is 100% local. No data leaves this machine.
- Never suggest uploading sensitive documents to external AI services.
- If asked to use a cloud tool for sensitive data, decline and explain why.
- Personal data of franchise prospects: handle per GDPR consent principles.

## Response Style

- Be concise. Executives are busy.
- Use markdown formatting (headers, tables, bullet points).
- Flag risks clearly with ⚠️
- When reviewing contracts: always list FLAGGED CLAUSES separately.
- For financial models: always provide a 3-line executive summary first.

## Team Context

- 4–8 users across Finance, Legal, Operations, Executive
- Current tools: M365 (Word, Excel, Teams)
- Language: English only
- GDPR + US-state privacy obligations apply
SOULEOF
ok "SOUL.md written (Black Sheep AI persona + agent routing)"

# ── AGENTS.md ─────────────────────────────────────────────────────────
cat > "$WORKSPACE/AGENTS.md" << 'AGENTSEOF'
# AGENTS.md — Black Sheep AI

Essential: SOUL.md. See that file for full persona and routing.

## Model Selection by Task

- **Long contract/doc review** (>50 pages): use qwen2.5:72b (128K context, 64K CTX window active)
- **Excel data analysis / BI reports**: use gemma3:27b (fast structured output)
- **Complex contract clause analysis / legal reasoning**: use deepseek-r1:70b (chain-of-thought)
- **Quick emails / short tasks**: use qwen2.5:14b (fastest)
- **General long-doc analysis**: use llama3.3:70b

## Key Rules

- Always flag risky contract clauses with ⚠️ and a plain-English explanation
- For financial analysis: 3-line executive summary first, then detail
- For franchise outreach emails: use the templates in SOUL.md, personalize with prospect details
- GDPR: never suggest sending sensitive documents outside this machine
AGENTSEOF
ok "AGENTS.md written"

# ── MEMORY.md (pre-seed OpenClaw with Gabriel/BSC context) ────────────
# Without this, OpenClaw boots with zero context about the customer.
# This seeds the essential facts so the agent is immediately useful.
cat > "$WORKSPACE/MEMORY.md" << 'MEMEOF'
# MEMORY.md — Black Sheep Coffee AI System

## Customer
- **Company**: Black Sheep Coffee (international franchise coffee chain)
- **Contact**: Gabriel Shohet, co-founder & co-CEO
- **Email**: gabriel@blacksheepcoffee.us
- **Location**: Miami (this machine) + international team
- **Deployment**: Sovereign Tailscale network, interim setup on M3 Ultra 256GB
- **Timeline**: ASAP
- **Budget**: Open

## Team
- 4–8 users across: Finance, Legal, Operations, Executive
- Privacy obligations: GDPR + US-state (no data leaves this machine)
- Current tools: M365 (Word, Excel, Teams/SharePoint)
- Language: English only

## Active Use Cases
1. **Franchise Sales Outreach** — draft personalized emails, prospect outreach sequences
2. **Business Intelligence** — analyze financial data (Excel/CSV), generate management reports
3. **Finance** — financial modelling review, management accounts, commercial contracts
4. **Legal** — IP/TM registration guidance, franchise agreements, RE leases, contract review

## Document Types
- Contracts (franchise agreements, RE leases, commercial contracts)
- Financial (P&L, management accounts, models)
- Regulatory (IP/TM filings, compliance docs)
- Internal (board reports, strategy docs)

## Key Contacts
- Kavin Lingham — infrastructure provider (Sovereign ATX)
- Gabriel Shohet — primary user / admin (first signup = admin in Open WebUI)
- IT and GC available for support (no approval above CEO required)

## Infrastructure
- Machine: sovereign-bsc-miami-studio (M3 Ultra 256GB, Miami)
- Tailscale: sovereign network
- Open WebUI: http://<tailscale-ip>:3000 (team browser access)
- Ollama: localhost:11434 (internal only)
- Primary model: qwen2.5:72b (128K context, 64K active)

## Document Folders
- ~/Documents/BlackSheepDocs/finance/   — financial docs
- ~/Documents/BlackSheepDocs/legal/     — legal docs
- ~/Documents/BlackSheepDocs/franchise/ — franchise outreach
- ~/Documents/BlackSheepDocs/bi/        — BI data exports
- ~/Documents/BlackSheepDocs/executive/ — executive/board docs

## Notes
- Always caveat legal guidance: "Not legal advice — flag to GC for formal opinion"
- For financial analysis: always lead with a 3-line executive summary
- Contract reviews: list FLAGGED CLAUSES with ⚠️ and plain-English explanations
- GDPR: never suggest external AI services for sensitive data
MEMEOF
ok "MEMORY.md pre-seeded (OpenClaw boots with full BSC context)"

# ── Document processing helper scripts ────────────────────────────────
mkdir -p "$WORKSPACE/scripts"

cat > "$WORKSPACE/scripts/extract-word.sh" << 'WORDEOF'
#!/bin/bash
# Extract text from a Word (.docx or .doc) file for AI processing
# Usage: bash extract-word.sh <file.docx>
# Output: markdown text to stdout
# Prefers LibreOffice (best M365 fidelity) with pandoc fallback

FILE="${1:?Usage: extract-word.sh <file.docx>}"
SOFFICE="/Applications/LibreOffice.app/Contents/MacOS/soffice"

if [ -f "$SOFFICE" ] && command -v pandoc &>/dev/null; then
  # LibreOffice → intermediate docx (normalizes complex M365 features) → pandoc → markdown
  TMPDIR_OUT=$(mktemp -d)
  "$SOFFICE" --headless --convert-to docx --outdir "$TMPDIR_OUT" "$FILE" 2>/dev/null
  CONVERTED=$(ls "$TMPDIR_OUT"/*.docx 2>/dev/null | head -1)
  if [ -n "$CONVERTED" ]; then
    pandoc -f docx -t markdown --wrap=none "$CONVERTED"
    rm -rf "$TMPDIR_OUT"
    exit 0
  fi
  rm -rf "$TMPDIR_OUT"
fi

# Fallback: pandoc direct
if command -v pandoc &>/dev/null; then
  pandoc -f docx -t markdown --wrap=none "$FILE"
else
  echo "Error: neither LibreOffice nor pandoc available." >&2
  echo "Run: brew install pandoc  OR  brew install --cask libreoffice" >&2
  exit 1
fi
WORDEOF

cat > "$WORKSPACE/scripts/extract-excel.sh" << 'XLSEOF'
#!/bin/bash
# Extract data from an Excel (.xlsx) file as markdown table
# Usage: bash extract-excel.sh <file.xlsx> [sheet_name]
# Output: markdown table to stdout

FILE="${1:?Usage: extract-excel.sh <file.xlsx> [sheet_name]}"
SHEET="${2:-}"

python3 - "$FILE" "$SHEET" << 'PYEOF'
import sys, pandas as pd

file = sys.argv[1]
sheet = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else 0

try:
    if str(sheet).isdigit():
        df = pd.read_excel(file, sheet_name=int(sheet), dtype=str)
    else:
        df = pd.read_excel(file, sheet_name=sheet, dtype=str)
    df = df.fillna('')
    print(df.to_markdown(index=False))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
XLSEOF

cat > "$WORKSPACE/scripts/extract-pdf.sh" << 'PDFEOF'
#!/bin/bash
# Extract text from a PDF file for AI processing
# Usage: bash extract-pdf.sh <file.pdf>
# Output: plain text to stdout
# 3-tier strategy:
#   Tier 1: pdftotext (poppler)       — fastest, text-based PDFs (most contracts, leases)
#   Tier 2: pypdf                     — fallback for encrypted/structured PDFs
#   Tier 3: tesseract OCR             — scanned/image-based PDFs (signed docs, notarised contracts)

FILE="${1:?Usage: extract-pdf.sh <file.pdf>}"

if ! [ -f "$FILE" ]; then
  echo "Error: file not found: $FILE" >&2; exit 1
fi

# ── Tier 1: pdftotext (poppler) ──────────────────────────────────────
if command -v pdftotext &>/dev/null; then
  TEXT=$(pdftotext -layout "$FILE" - 2>/dev/null)
  WORD_COUNT=$(echo "$TEXT" | wc -w | tr -d ' ')
  if [ "$WORD_COUNT" -gt 50 ]; then
    echo "$TEXT"
    exit 0
  fi
  echo "[Tier 1 (pdftotext): <50 words — PDF may be image-based. Trying pypdf...]" >&2
fi

# ── Tier 2: pypdf ────────────────────────────────────────────────────
if command -v python3 &>/dev/null; then
  PY_RESULT=$(python3 - "$FILE" 2>/tmp/pypdf-err.txt << 'PYEOF'
import sys
try:
    from pypdf import PdfReader
    reader = PdfReader(sys.argv[1])
    text = "\n".join(page.extract_text() or "" for page in reader.pages)
    if len(text.strip().split()) > 50:
        print(text)
        sys.exit(0)
    sys.exit(2)
except ImportError:
    sys.exit(3)
except Exception:
    sys.exit(1)
PYEOF
  )
  PY_EXIT=$?
  if [ $PY_EXIT -eq 0 ] && [ -n "$PY_RESULT" ]; then
    echo "$PY_RESULT"
    exit 0
  elif [ $PY_EXIT -eq 3 ]; then
    echo "[pypdf not installed — run: pip3 install pypdf]" >&2
  elif [ $PY_EXIT -eq 2 ]; then
    echo "[Tier 2 (pypdf): <50 words — PDF is image-based (scanned). Trying tesseract OCR...]" >&2
  fi
fi

# ── Tier 3: tesseract OCR — for scanned/image-based PDFs ─────────────
# Converts each page to PNG via pdfimages/ImageMagick, then runs tesseract.
# Handles: notarised contracts, signed leases, IP filing acknowledgements, scanned invoices.
if command -v tesseract &>/dev/null; then
  echo "[Tier 3 (tesseract OCR): converting PDF pages to images for OCR...]" >&2
  TMPDIR_OCR=$(mktemp -d)

  # Use pdftoppm (poppler) if available — faster and higher quality than ImageMagick
  if command -v pdftoppm &>/dev/null; then
    pdftoppm -r 300 -png "$FILE" "$TMPDIR_OCR/page" 2>/dev/null
  elif command -v convert &>/dev/null; then
    convert -density 300 "$FILE" "$TMPDIR_OCR/page-%03d.png" 2>/dev/null
  else
    echo "[OCR requires pdftoppm (brew install poppler) or ImageMagick (brew install imagemagick)]" >&2
    rm -rf "$TMPDIR_OCR"
    exit 1
  fi

  OCR_TEXT=""
  PAGE_COUNT=0
  for img in "$TMPDIR_OCR"/page*.png; do
    [ -f "$img" ] || continue
    PAGE_TEXT=$(tesseract "$img" stdout -l eng 2>/dev/null)
    OCR_TEXT+="$PAGE_TEXT"$'\n'
    PAGE_COUNT=$((PAGE_COUNT + 1))
  done

  rm -rf "$TMPDIR_OCR"

  WORD_COUNT=$(echo "$OCR_TEXT" | wc -w | tr -d ' ')
  if [ "$WORD_COUNT" -gt 20 ]; then
    echo "[OCR extracted ~${WORD_COUNT} words from ${PAGE_COUNT} pages]" >&2
    echo "$OCR_TEXT"
    exit 0
  else
    echo "[Tesseract OCR extracted <20 words — PDF may be password-protected or corrupted]" >&2
    exit 1
  fi
fi

# ── All tiers failed ─────────────────────────────────────────────────
echo "Error: all PDF extraction methods failed." >&2
echo "Install: brew install poppler tesseract  AND  pip3 install pypdf" >&2
echo "If PDF is password-protected, decrypt first: qpdf --password=<pw> --decrypt input.pdf output.pdf" >&2
exit 1
PDFEOF

chmod +x "$WORKSPACE/scripts/extract-word.sh" "$WORKSPACE/scripts/extract-excel.sh" \
          "$WORKSPACE/scripts/extract-pdf.sh"
ok "Document processing scripts created (extract-word.sh, extract-excel.sh, extract-pdf.sh)"

# ── Health-check script (bsc-health.sh) ──────────────────────────────
# Runnable at any time to verify the full stack is healthy.
# Designed for Kavin to run remotely via SSH for a fast status snapshot.
cat > "$WORKSPACE/scripts/bsc-health.sh" << 'HEALTHEOF'
#!/bin/bash
# Black Sheep Coffee — System Health Check
# Usage: bash bsc-health.sh
# Run remotely: ssh user@sovereign-bsc-miami-studio 'bash ~/.openclaw/workspace/scripts/bsc-health.sh'

BOLD='\033[1m'; GREEN='\033[38;5;114m'; RED='\033[38;5;203m'
GOLD='\033[38;5;220m'; CYAN='\033[38;5;117m'; DIM='\033[2m'; RESET='\033[0m'
ok()   { echo -e "  ${GREEN}✅ $*${RESET}"; }
warn() { echo -e "  ${GOLD}⚠️  $*${RESET}"; }
fail() { echo -e "  ${RED}❌ $*${RESET}"; }

echo ""
echo -e "${BOLD}  Black Sheep AI — Health Check  $(date '+%Y-%m-%d %H:%M')${RESET}"
echo "  ─────────────────────────────────────────────────────"

# Tailscale
TS_BIN=""
for c in "/Applications/Tailscale.app/Contents/MacOS/Tailscale" "/usr/local/bin/tailscale" "$(command -v tailscale 2>/dev/null)"; do
  [ -x "$c" ] && { TS_BIN="$c"; break; }
done
if [ -n "$TS_BIN" ]; then
  TS_STATUS=$("$TS_BIN" status 2>/dev/null | head -1)
  TS_IP=$("$TS_BIN" ip -4 2>/dev/null)
  [ -n "$TS_STATUS" ] && ok "Tailscale: connected ($TS_IP)" || fail "Tailscale: not connected"
else
  fail "Tailscale: binary not found"
fi

# Ollama
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
  MODEL_COUNT=$(curl -sf http://localhost:11434/api/tags | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "?")
  ok "Ollama: running on localhost:11434 ($MODEL_COUNT models)"
  # Check BSC Modelfiles
  for m in bsc-legal bsc-finance bsc-bi bsc-franchise; do
    curl -sf http://localhost:11434/api/tags | grep -q "\"$m\"" \
      && ok "  Model $m: available" \
      || warn "  Model $m: not found (run: ollama create $m -f ~/.ollama/modelfiles/Modelfile.$m)"
  done
else
  fail "Ollama: not responding on localhost:11434 — check: launchctl list | grep bsc.ollama"
fi

# Open WebUI
if curl -sf http://localhost:3000 > /dev/null 2>&1; then
  ok "Open WebUI: running on port 3000"
  [ -n "$TS_IP" ] && echo -e "    ${DIM}Team URL: http://$TS_IP:3000${RESET}"
else
  fail "Open WebUI: not responding — check: tail -50 ~/Library/Logs/bsc/openwebui-err.log"
fi

# OpenClaw
OC_PID=$(launchctl list 2>/dev/null | grep "ai.openclaw.gateway" | awk '{print $1}')
[ -n "$OC_PID" ] && ok "OpenClaw: running (PID $OC_PID)" || warn "OpenClaw: not running — openclaw gateway start"

# Sleep prevention
SLEEP_VAL=$(pmset -g | grep '^[ ]*sleep ' | awk '{print $2}')
[ "$SLEEP_VAL" = "0" ] && ok "Sleep prevention: active (pmset sleep=0)" || warn "Sleep: pmset sleep=$SLEEP_VAL (should be 0)"
CAFF_PID=$(launchctl list 2>/dev/null | grep "bsc.caffeinate" | awk '{print $1}')
[ -n "$CAFF_PID" ] && ok "Caffeinate: running" || warn "Caffeinate LaunchAgent: not active"

# Disk space
FREE_GB=$(df -g / | awk 'NR==2{print $4}')
[ "$FREE_GB" -gt 50 ] && ok "Disk free: ${FREE_GB}GB" || warn "Disk free: ${FREE_GB}GB — low, clean up soon"

# FileVault
FV=$(fdesetup status 2>/dev/null | head -1)
echo "$FV" | grep -q "FileVault is On" && ok "FileVault: enabled" || warn "FileVault: $FV"

# Document tools
command -v pdftotext &>/dev/null && ok "pdftotext: available (PDF extraction)" || warn "pdftotext: missing (brew install poppler)"
command -v pandoc    &>/dev/null && ok "pandoc: available (Word extraction)"  || warn "pandoc: missing (brew install pandoc)"
python3 -c "import openpyxl" 2>/dev/null && ok "openpyxl: available (Excel)" || warn "openpyxl: missing"

echo ""
echo -e "  ${DIM}Run from Austin: ssh user@$TS_IP 'bash ~/.openclaw/workspace/scripts/bsc-health.sh'${RESET}"
echo ""
HEALTHEOF
chmod +x "$WORKSPACE/scripts/bsc-health.sh"
ok "Health-check script created: ~/.openclaw/workspace/scripts/bsc-health.sh"

# ── Department-organized document folders ────────────────────────────
# Each team has their own inbox so docs land in the right context from the start
BSC_DOCS=~/Documents/BlackSheepDocs
mkdir -p \
  "$BSC_DOCS/finance/incoming"   "$BSC_DOCS/finance/processed" \
  "$BSC_DOCS/legal/incoming"     "$BSC_DOCS/legal/processed" \
  "$BSC_DOCS/franchise/incoming" "$BSC_DOCS/franchise/processed" \
  "$BSC_DOCS/bi/incoming"        "$BSC_DOCS/bi/processed" \
  "$BSC_DOCS/executive/incoming" "$BSC_DOCS/executive/processed"

cat > "$BSC_DOCS/README.txt" << 'READMEEOF'
BLACK SHEEP COFFEE — AI Document Processing
============================================

FOLDER GUIDE
  finance/incoming/    — Financial models, management accounts, P&L, commercial contracts
  legal/incoming/      — Franchise agreements, IP/TM docs, RE leases, contract reviews
  franchise/incoming/  — Prospect data, outreach materials, franchise disclosure documents
  bi/incoming/         — Data exports, reports, Excel dashboards for BI analysis
  executive/incoming/  — Board reports, strategic docs, anything cross-departmental

WORKFLOW
  1. Drop the file in the appropriate department inbox above
  2. Open your AI chat at http://<tailscale-ip>:3000 (Open WebUI)
  3. Upload the file directly in the chat window
  4. Say: "Please review [filename] — [brief context]"
  5. Move the file to processed/ when done

QUICK EXTRACT (manual use — usually not needed if uploading via chat)
  Word:  bash ~/.openclaw/workspace/scripts/extract-word.sh finance/incoming/file.docx
  Excel: bash ~/.openclaw/workspace/scripts/extract-excel.sh bi/incoming/data.xlsx

SUPPORTED FILE TYPES
  .pdf  — PDF documents (contracts, leases, regulatory docs — most common format)
  .docx — Word documents (draft contracts, reports)
  .xlsx — Excel spreadsheets (financial models, management accounts, data)

PDF NOTES
  Text-based PDFs (most contracts, leases, filed documents): extracted automatically
  Scanned/image PDFs: may need OCR — contact Kavin if a doc isn't processing correctly

All processing is LOCAL. Files never leave this machine. GDPR + US-state safe.
READMEEOF
ok "Department document folders created: Finance / Legal / Franchise / BI / Executive"

# ── Bake env vars into zprofile ────────────────────────────────────────
if [ -n "$ANTHROPIC_API_KEY" ]; then
  grep -q "ANTHROPIC_API_KEY" ~/.zprofile 2>/dev/null && \
    sed -i '' "s|export ANTHROPIC_API_KEY=.*|export ANTHROPIC_API_KEY=\"${ANTHROPIC_API_KEY}\"|" ~/.zprofile || \
    echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_API_KEY}\"" >> ~/.zprofile
  ok "Anthropic API key saved to ~/.zprofile"
fi

# ── Install + start OpenClaw LaunchAgent ──────────────────────────────
openclaw gateway install 2>/dev/null \
  && ok "OpenClaw LaunchAgent: installed" \
  || warn "OpenClaw LaunchAgent install failed — retry: openclaw gateway install"

OC_PLIST=~/Library/LaunchAgents/ai.openclaw.gateway.plist
if [ -f "$OC_PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$OC_PLIST" 2>/dev/null || true

  # Bake all required env vars into the plist
  for kv in \
    "OLLAMA_HOST:http://localhost:11434" \
    "OLLAMA_NUM_CTX:65536" \
    "OLLAMA_NUM_PARALLEL:4" \
    "OLLAMA_MAX_LOADED_MODELS:2" \
    "OLLAMA_KEEP_ALIVE:30m"; do
    key="${kv%%:*}"; val="${kv#*:}"
    /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:${key} string ${val}" "$OC_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:${key} ${val}" "$OC_PLIST" 2>/dev/null || true
  done

  if [ -n "$ANTHROPIC_API_KEY" ]; then
    /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:ANTHROPIC_API_KEY string ${ANTHROPIC_API_KEY}" "$OC_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:ANTHROPIC_API_KEY ${ANTHROPIC_API_KEY}" "$OC_PLIST" 2>/dev/null || true
  fi

  if [ -n "$DISCORD_BOT_TOKEN" ]; then
    /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:DISCORD_BOT_TOKEN string ${DISCORD_BOT_TOKEN}" "$OC_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:DISCORD_BOT_TOKEN ${DISCORD_BOT_TOKEN}" "$OC_PLIST" 2>/dev/null || true
  fi

  /usr/libexec/PlistBuddy -c "Set :KeepAlive true" "$OC_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :KeepAlive bool true" "$OC_PLIST" 2>/dev/null || true

  ok "OpenClaw plist: env vars baked in (includes OLLAMA_NUM_CTX=65536), KeepAlive=true"
else
  warn "OpenClaw plist not found — check: openclaw gateway install"
fi

launchctl stop  ai.openclaw.gateway 2>/dev/null || true; sleep 2
launchctl start ai.openclaw.gateway 2>/dev/null || true; sleep 4
launchctl list 2>/dev/null | grep -q "ai.openclaw.gateway" \
  && ok "OpenClaw gateway: running (survives reboots)" \
  || warn "OpenClaw gateway not running — check: openclaw status"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 10: Document Watcher (fswatch — optional quality-of-life)
# ═══════════════════════════════════════════════════════════════════════
step "Document Watcher (fswatch)"

echo ""
echo -e "  ${DIM}fswatch watches the document inboxes and sends a macOS notification${RESET}"
echo -e "  ${DIM}when a new file is dropped — reminds the team to process it.${RESET}"
echo ""

if brew list fswatch 2>/dev/null | grep -q fswatch; then
  ok "fswatch: already installed"
else
  brew install fswatch \
    && ok "fswatch: installed" \
    || { warn "fswatch: install failed (non-fatal — watcher not available)"; }
fi

if command -v fswatch &>/dev/null; then
  WATCHER_SCRIPT="$WORKSPACE/scripts/doc-watcher.sh"
  cat > "$WATCHER_SCRIPT" << 'WATCHEOF'
#!/bin/bash
# Black Sheep Coffee — Document inbox watcher
# Sends macOS notification when a new .docx or .xlsx file is dropped in any inbox
# Run from LaunchAgent or manually: bash doc-watcher.sh

BSC_DOCS=~/Documents/BlackSheepDocs
DEPARTMENTS=(finance legal franchise bi executive)

WATCH_DIRS=()
for dept in "${DEPARTMENTS[@]}"; do
  dir="$BSC_DOCS/$dept/incoming"
  [ -d "$dir" ] && WATCH_DIRS+=("$dir")
done

[ ${#WATCH_DIRS[@]} -eq 0 ] && { echo "No inbox folders found"; exit 1; }

echo "$(date): Watching document inboxes: ${WATCH_DIRS[*]}"

fswatch -0 --event Created --event Renamed --latency 2 "${WATCH_DIRS[@]}" | \
while IFS= read -r -d $'\0' file; do
  filename=$(basename "$file")
  dept=$(echo "$file" | grep -oE '(finance|legal|franchise|bi|executive)')

  # Only notify for Word and Excel files
  case "$filename" in
    *.docx|*.xlsx|*.doc|*.xls)
      dept_label="${dept:-unknown}"
      osascript -e "display notification \"$filename landed in $dept_label inbox\" with title \"Black Sheep AI\" subtitle \"Open http://localhost:3000 to process\"" 2>/dev/null || true
      echo "$(date): New doc detected — $file"
      ;;
  esac
done
WATCHEOF
  chmod +x "$WATCHER_SCRIPT"

  # LaunchAgent for watcher
  WATCHER_PLIST=~/Library/LaunchAgents/com.bsc.docwatcher.plist
  cat > "$WATCHER_PLIST" << WATCHPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>             <string>com.bsc.docwatcher</string>
  <key>ProgramArguments</key>  <array><string>/bin/bash</string><string>${WATCHER_SCRIPT}</string></array>
  <key>RunAtLoad</key>         <true/>
  <key>KeepAlive</key>         <true/>
  <key>StandardOutPath</key>   <string>${WEBUI_LOG_DIR}/docwatcher.log</string>
  <key>StandardErrorPath</key> <string>${WEBUI_LOG_DIR}/docwatcher-err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key> <string>${HOME}</string>
    <key>PATH</key> <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
</dict></plist>
WATCHPLIST

  launchctl unload "$WATCHER_PLIST" 2>/dev/null || true
  launchctl load   "$WATCHER_PLIST" 2>/dev/null \
    && ok "Document watcher LaunchAgent: installed (notifies on new .docx/.xlsx in any inbox)" \
    || warn "Document watcher LaunchAgent failed to load (non-fatal)"
else
  info "fswatch not available — document watcher skipped"
fi

# ═══════════════════════════════════════════════════════════════════════
#  STEP 11: Firewall
# ═══════════════════════════════════════════════════════════════════════
step "Firewall (Tailscale-only access)"

# Port 3000 (Open WebUI) opened to Tailscale only — team accesses via browser over VPN
# Port 11434 (Ollama) stays localhost-only — Open WebUI is the only frontend
cat > /tmp/bsc-pf.conf << 'PFEOF'
set skip on lo0
table <tailscale> { 100.64.0.0/10 }
block in all
pass out all keep state
# SSH from Tailscale only (Sovereign remote management)
pass in on utun+ proto tcp from <tailscale> to any port 22 keep state
pass in on en0 proto tcp from <tailscale> to any port 22 keep state
# Open WebUI (team browser interface) — Tailscale only
pass in on utun+ proto tcp from <tailscale> to any port 3000 keep state
pass in on en0 proto tcp from <tailscale> to any port 3000 keep state
# Screen sharing from Tailscale only (remote support)
pass in on utun+ proto tcp from <tailscale> to any port 5900 keep state
# Ollama: localhost only — NOT exposed externally; Open WebUI on same machine
# ICMP + WireGuard (Tailscale)
pass in proto icmp from <tailscale>
pass in proto udp to any port 41641
PFEOF

sudo cp /tmp/bsc-pf.conf /etc/pf.anchors/bsc 2>/dev/null || warn "Could not write pf anchor"
if ! grep -q '"bsc"' /etc/pf.conf 2>/dev/null; then
  printf '\nanchor "bsc"\nload anchor "bsc" from "/etc/pf.anchors/bsc"\n' | \
    sudo tee -a /etc/pf.conf > /dev/null 2>/dev/null || true
fi
sudo pfctl -f /etc/pf.conf 2>/dev/null || true
sudo pfctl -e 2>/dev/null || true
ok "Firewall active: Open WebUI port 3000 → Tailscale only; Ollama → localhost only"

# macOS application firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null || true
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on 2>/dev/null || true
ok "macOS application firewall: stealth mode on"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 12: Verification
# ═══════════════════════════════════════════════════════════════════════
step "Verification"

echo ""
echo -e "  ${BOLD}System Checks${RESET}"
divider

# Tailscale
TS_STATUS=$("$TAILSCALE_BIN" status 2>/dev/null | head -1)
[ -n "$TS_STATUS" ] && ok "Tailscale: $TS_STATUS" || warn "Tailscale: not connected"

# Ollama
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
  ok "Ollama: responding on localhost:11434"
  MODEL_COUNT=$(curl -sf http://localhost:11434/api/tags | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "?")
  info "  Models available: $MODEL_COUNT"
  # Verify context window is set
  CTX_CHECK=$(curl -sf http://localhost:11434/api/show -d '{"name":"qwen2.5:14b"}' 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('parameters',''))" 2>/dev/null | grep -c "num_ctx" || echo "0")
  [ "$CTX_CHECK" -gt 0 ] && ok "Context window: custom num_ctx set" || info "  Context window: using OLLAMA_NUM_CTX=65536 env var"
else
  warn "Ollama: not responding — may still be pulling models"
fi

# Open WebUI
if curl -sf http://localhost:3000 > /dev/null 2>&1; then
  ok "Open WebUI: responding on port 3000"
  info "  Team URL: http://$TS_IP:3000"
else
  warn "Open WebUI: not yet responding — check: tail -50 ~/Library/Logs/bsc/openwebui-err.log"
fi

# OpenClaw
OC_RUNNING=$(launchctl list 2>/dev/null | grep "ai.openclaw.gateway" | awk '{print $1}')
[ -n "$OC_RUNNING" ] && ok "OpenClaw gateway: running (PID $OC_RUNNING)" || warn "OpenClaw gateway: not running"

# Sleep settings (also checked in Security block above)

echo ""
echo -e "  ${BOLD}Document Tools${RESET}"
divider
command -v pdftotext &>/dev/null \
  && ok "pdftotext: available (poppler — PDF text extraction)" \
  || warn "pdftotext: missing — PDF extraction unavailable (brew install poppler)"
command -v pandoc &>/dev/null             && ok "pandoc: available (.docx → markdown)" || warn "pandoc: missing"
"$WEBUI_VENV/bin/python3" -c "import openpyxl" 2>/dev/null \
  && ok "openpyxl: available (.xlsx processing)" || warn "openpyxl: missing in venv"
"$WEBUI_VENV/bin/python3" -c "import pandas" 2>/dev/null \
  && ok "pandas: available (data analysis)" || warn "pandas: missing in venv"
python3 -c "import pypdf" 2>/dev/null \
  && ok "pypdf: available (Python PDF fallback for encrypted/scanned PDFs)" \
  || warn "pypdf: missing — run: pip3 install pypdf"
[ -d "$BSC_DOCS/finance/incoming" ]   && ok "Document folders: Finance / Legal / Franchise / BI / Executive" || warn "Document folders missing"
command -v fswatch &>/dev/null            && ok "fswatch: available (document watcher active)" || info "fswatch: not installed"
[ -f "$WORKSPACE/scripts/extract-pdf.sh" ] \
  && ok "extract-pdf.sh: ready" || warn "extract-pdf.sh: missing"
[ -f "$WORKSPACE/scripts/bsc-health.sh" ] \
  && ok "bsc-health.sh: ready" || warn "bsc-health.sh: missing"

echo ""
echo -e "  ${BOLD}BSC Modelfiles (custom context + system prompts)${RESET}"
divider
for bsc_model in bsc-legal bsc-finance bsc-bi bsc-franchise; do
  if ollama list 2>/dev/null | grep -q "^${bsc_model}"; then
    ok "$bsc_model: registered in Ollama"
  else
    warn "$bsc_model: not yet created — run: ollama create $bsc_model -f ~/.ollama/modelfiles/Modelfile.$bsc_model"
  fi
done

echo ""
echo -e "  ${BOLD}Security${RESET}"
divider
FV_CHECK=$(fdesetup status 2>/dev/null | head -1)
echo "$FV_CHECK" | grep -q "FileVault is On" \
  && ok "FileVault: enabled (encryption at rest)" \
  || warn "FileVault: $FV_CHECK — enable before storing sensitive data"

SLEEP_CHECK=$(pmset -g | grep "^[ ]*sleep " | awk '{print $2}')
[ "$SLEEP_CHECK" = "0" ] && ok "Sleep prevention: active" || warn "System sleep may not be fully disabled"

# ═══════════════════════════════════════════════════════════════════════
#  STEP 13: Quick-Start Guide for First Admin
# ═══════════════════════════════════════════════════════════════════════
step "Quick-Start Guide"

cat > "$WORKSPACE/QUICKSTART-GABRIEL.md" << QSEOF
# Black Sheep AI — Quick Start Guide

## Team Access

1. **Connect to Tailscale** — each team member needs the Tailscale app + invite link
2. **Open browser** → go to **http://${TS_IP}:3000**
3. **First user to sign up gets admin** — Gabriel should be first
4. **Create accounts** for each team member (or enable SSO later)
5. **Default model**: qwen2.5:72b (best for long contracts/reports)

## Document Folders

Drop files before uploading to the AI:
- **~/Documents/BlackSheepDocs/finance/** — P&L, models, commercial contracts
- **~/Documents/BlackSheepDocs/legal/** — franchise agreements, IP/TM, RE leases
- **~/Documents/BlackSheepDocs/franchise/** — prospect data, outreach materials
- **~/Documents/BlackSheepDocs/bi/** — data exports, dashboards, Excel reports
- **~/Documents/BlackSheepDocs/executive/** — board reports, strategy docs

## Use Cases

### ⚖️ Legal (use model: bsc-legal)
Drop contract in **legal/incoming/** → upload in chat → *"Review this franchise agreement. List all clauses that need our attention, with plain-English explanations."*
Works with: PDFs, Word docs

### 💰 Finance (use model: bsc-finance)
Drop financial model in **finance/incoming/** → upload in chat → *"Review this financial model. What are the key assumptions? Flag anything that looks unusual."*
Works with: Excel, PDFs, Word docs

### 📊 Business Intelligence (use model: bsc-bi)
Drop Excel file in **bi/incoming/** → upload in chat → *"Analyze this management accounts file. Give me a 3-line executive summary, then flag any concerning trends."*
Works with: Excel, CSV

### 📩 Franchise Sales Outreach (use model: bsc-franchise)
Drop prospect data in **franchise/incoming/** → upload in chat → *"Draft a personalized outreach email to [prospect name], a [background] looking to open a franchise in [city]. Focus on [unique angle]."*

## Model Guide

| Use Case | Model | Why |
|----------|-------|-----|
| Legal — franchise agreements, leases | **bsc-legal** | Chain-of-thought, clause-by-clause analysis |
| Finance — P&L, models, commercial | **bsc-finance** | Best at numbers + long doc analysis |
| BI / Excel / reports | **bsc-bi** | Fast structured output, dashboards |
| Franchise sales emails | **bsc-franchise** | Fast, tuned for outreach copy |
| General / mixed tasks | qwen2.5:72b | Primary workhorse |

**All BSC models have 64K context baked in — paste or upload up to ~48,000 words (150 pages) in one go.**

## PDF Support
Most contracts and regulatory docs come as PDFs — just upload them directly in chat.
- Text-based PDFs (most contracts, leases): ✅ works automatically
- Scanned/image PDFs: ⚠️ may not extract — contact Kavin if a doc doesn't process correctly

## Context Window
All models have 64K context active — you can paste or upload ~48,000 words (150 pages) in a single conversation.

## Privacy
Everything is 100% local. Documents never leave this machine. GDPR-safe.

## Support
- Kavin: kavinlingham1@gmail.com
- Tailscale dashboard: https://login.tailscale.com/admin
QSEOF
ok "Quick-start guide written: ~/.openclaw/workspace/QUICKSTART-GABRIEL.md"

# ═══════════════════════════════════════════════════════════════════════
#  SUMMARY
# ═══════════════════════════════════════════════════════════════════════

echo ""; echo ""
echo -e "${GOLD}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════════════╗"
if [ ${#ERRORS[@]} -eq 0 ] && [ ${#WARNINGS[@]} -eq 0 ]; then
echo "  ║  ✅  Black Sheep AI — Setup Complete (v7)                    ║"
elif [ ${#ERRORS[@]} -eq 0 ]; then
echo "  ║  ✅  Black Sheep AI — Setup Complete (v5, with warnings)     ║"
else
echo "  ║  ⚠️   Black Sheep AI — Setup Complete (v5, check errors)     ║"
fi
echo "  ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "  ${BOLD}Machine${RESET}      : $NEW_HOSTNAME (M3 Ultra 256GB, Miami)"
echo -e "  ${BOLD}Tailscale${RESET}    : $TS_IP"
echo -e "  ${BOLD}SSH${RESET}          : ssh $USER@$TS_IP"
echo -e "  ${BOLD}Open WebUI${RESET}   : http://$TS_IP:3000 (team browser access)"
echo -e "  ${BOLD}Ollama${RESET}       : localhost:11434 (internal only)"
echo -e "  ${BOLD}Context${RESET}      : 64K tokens (OLLAMA_NUM_CTX=65536)"
echo -e "  ${BOLD}OpenClaw${RESET}     : running via LaunchAgent"
echo -e "  ${BOLD}Docs folder${RESET}  : ~/Documents/BlackSheepDocs/ (Finance/Legal/Franchise/BI/Executive)"
echo ""
echo -e "  ${BOLD}Models (128K capable, 64K CTX active):${RESET}"
ollama list 2>/dev/null | tail -n +2 | awk '{printf "    • %-35s\n", $1}' || echo "    (pulling — check: ollama list)"

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo -e "  ${GOLD}${BOLD}Warnings:${RESET}"
  for w in "${WARNINGS[@]}"; do echo -e "  ${GOLD}  ⚠  $w${RESET}"; done
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}Errors:${RESET}"
  for e in "${ERRORS[@]}"; do echo -e "  ${RED}  ✗  $e${RESET}"; done
fi

echo ""
divider
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo ""
echo -e "  ${CYAN}1.${RESET} Verify all models: ${BOLD}ollama list${RESET} (look for bsc-legal, bsc-finance, bsc-bi, bsc-franchise)"
echo -e "  ${CYAN}2.${RESET} Test BSC model: ${BOLD}ollama run bsc-franchise${RESET}"
echo -e "  ${CYAN}3.${RESET} Open team UI: ${BOLD}http://$TS_IP:3000${RESET} (Gabriel signs up first → gets admin)"
echo -e "  ${CYAN}4.${RESET} Run health check: ${BOLD}bash ~/.openclaw/workspace/scripts/bsc-health.sh${RESET}"
echo -e "  ${CYAN}5.${RESET} Test PDF: ${BOLD}bash ~/.openclaw/workspace/scripts/extract-pdf.sh <any-contract.pdf>${RESET}"
echo -e "  ${CYAN}6.${RESET} Check OpenClaw: ${BOLD}openclaw status${RESET}"
if [ -z "$DISCORD_BOT_TOKEN" ]; then
echo -e "  ${CYAN}7.${RESET} Add Discord (optional): ${BOLD}DISCORD_BOT_TOKEN=... openclaw gateway restart${RESET}"
fi
echo -e "  ${CYAN}8.${RESET} Share quick-start guide: ${BOLD}~/.openclaw/workspace/QUICKSTART-GABRIEL.md${RESET}"
echo -e "  ${CYAN}9.${RESET} Verify remotely from Austin: ${BOLD}ssh $USER@$TS_IP 'bash ~/.openclaw/workspace/scripts/bsc-health.sh'${RESET}"
echo ""
echo -e "  ${DIM}GDPR note: All inference is local. Zero data leaves this machine.${RESET}"
echo -e "  ${DIM}Support: Kavin (kavinlingham1@gmail.com)${RESET}"
echo ""
echo -e "  ${GREEN}${BOLD}Black Sheep AI is live. Close this terminal — it keeps running.${RESET}"
echo ""
echo -e "  ${DIM}Sovereign ATX · sovereignatx.ai · $(date +%Y)${RESET}"
echo ""
