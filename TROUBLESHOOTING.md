# Troubleshooting

## Bot not responding in Telegram

**Check OpenClaw is running:**
```bash
openclaw status
```
Should show: Gateway running, agents online

**Check logs:**
```bash
openclaw logs --tail 50 | grep telegram
```

**Verify bot token:**
```bash
openclaw config get plugins.telegram.token
```

**Test bot directly:**
```bash
curl -s https://api.telegram.org/bot{YOUR_TOKEN}/getMe | jq
```
Should show bot info

---

## Token verification failed

- Token format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyzABCdeFGHi`
- No extra spaces or characters
- Copy directly from @BotFather
- Create new bot if corrupted

---

## Group not detected

- Send message in "Gabriel Agents" group
- Forward to @userinfobot
- Copy the chat ID (negative number like -1001234567890)
- Paste when asked

---

## Agents respond empty

- Check model running: `openclaw system stats`
- Increase context: `openclaw config patch --model-context-window 8192`
- Restart: `openclaw gateway restart`

---

## Access control not working

- Restart: `openclaw gateway restart`
- Check whitelist: `openclaw config get plugins.telegram.accessControl`
- Verify user ID (use @userinfobot)
- Test: unauthorized user should get denied message

---

## Cluster machines not visible

- Check Tailscale: `tailscale status`
- Verify auth: `tailscale auth-status`
- Ping machines: `ping sovereign-studio-1.local`
- Check network: both machines on same WiFi/Tailscale

---

## Memory not working

- Send data properly: `@bot Remember: [fact]. [fact]. [fact].`
- Agent should say "Remembered N facts"
- If not, data may be malformed

---

## Performance slow

- Check model: `ollama ps`
- Check CPU/memory: `openclaw system stats`
- Switch to faster model if needed
- Reduce context window: `openclaw config patch --model-context-window 4096`

---

## Need detailed logs

```bash
openclaw logs --level debug --tail 200
```

---

**Still stuck?** 

Check:
1. OpenClaw running: `openclaw status`
2. Logs: `openclaw logs --tail 100`
3. Config: `openclaw config get`
4. Network: `ping sovereign-studio-1.local`

Then debug from there.
