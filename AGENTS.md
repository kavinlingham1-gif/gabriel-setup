# Gabriel's Three Agents

## Agent 1: Franchise & Growth

**What it does:**
- Models new location economics (revenue, costs, timeline)
- Reviews contracts and agreements (franchise, leases, vendor)
- Analyzes markets and demographics
- Drafts franchise/partnership outreach
- Prepares board presentations

**Example prompts:**
```
@bot franchise: Model out a Tampa location launch. Show me the financial model.
@bot franchise: Review this franchise agreement. What should we negotiate?
@bot franchise: What's the addressable market in Atlanta for coffee franchises?
```

**Tone:** Strategic, numbers-focused, direct

---

## Agent 2: Operations

**What it does:**
- Analyzes daily performance (revenue, transactions, traffic)
- Tracks staffing levels and efficiency
- Manages inventory and reorders
- Drafts SOPs and training materials
- Identifies operational bottlenecks

**Example prompts:**
```
@bot ops: Which location is overstaffed for its revenue?
@bot ops: SoCo waste spiked 15% last week. Is it training or supply?
@bot ops: Give me this morning's briefing on all three locations.
@bot ops: Draft an opening procedures guide for new baristas.
```

**Tone:** Direct, practical, no fluff

---

## Agent 3: Streamlining

**What it does:**
- Identifies cost reduction opportunities
- Models CapEx decisions (lease vs. buy, ROI)
- Optimizes operational efficiency (staffing, waste, suppliers)
- Provides financial modeling for "what if" scenarios
- Tracks profitability and efficiency metrics

**Example prompts:**
```
@bot streamline: SoCo labor is 30% of revenue. That's above our 28% target. What should we do?
@bot streamline: Our bean supplier wants to raise prices. Should we switch?
@bot streamline: Espresso machine at Domain is 7 years old. Lease or buy replacement?
@bot streamline: Compare our supplier costs to market rates. Where are we overpaying?
```

**Tone:** Numbers-first, analytical, respectful of quality

---

## Memory System

All agents share permanent memory:

```
@bot Remember: Domain does $450K/month revenue with 12 staff
@bot Remember: We switched bean suppliers to save $7K/year
@bot Remember: Peak hours are 7-9 AM and 12-2 PM
```

Agents never forget. They reference this data automatically.

---

## Verification Rules

All agents verify claims against known data:

✅ Known data: cites source
❌ Unknown data: says "I don't know"
❌ Cost cuts that hurt quality: agent refuses

No BS. No guessing. All claims verified.

---

## Daily Workflows

**Morning (automated, 6 AM):**
```
Agent: "Morning briefing: Domain up 3%, SoCo down 2%. SoCo waste high again (18%)."
```

**During day (on-demand):**
```
You: @bot ops Should we add another person at Domain lunch?
Agent: "Current: 4 people, $800/hr labor. Historical data shows 3 handles it fine. Too risky to cut without more data."
```

**Evening (automated, 5 PM):**
```
Agent: "Day summary: 12 conversations logged, 3 decisions made, 1 alert: supplier pricing up 8%."
```

---

## Permissions

**Gabriel:** All agents, all permissions (read/write/schedule)
**Ops Manager:** Operations + Streamlining, read/write
**Finance Manager:** Streamlining only, read-only
**Others:** Added on demand

---

## Common Use Cases

### Financial Planning
- Model new location ROI
- Compare scenarios (lease vs. buy equipment)
- Forecast revenue per location
- Track labor efficiency metrics

### Operations Management
- Morning briefing on all locations
- Identify staffing gaps
- Spot bottlenecks (lunch rush, closing)
- Flag unusual metrics (waste, waste, transaction count)

### Cost Optimization
- Find supplier alternatives
- Analyze labor efficiency
- Model CapEx decisions
- Track and reduce waste

### Growth
- Model new markets
- Review franchise agreements
- Prepare investor presentations
- Plan expansion strategy

---

That's it. Three specialized agents. One memory system. All available 24/7 in Telegram.
