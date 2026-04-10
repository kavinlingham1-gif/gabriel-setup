#!/bin/bash
echo "Testing Gabriel agents..."
echo ""
echo "NOTE: Agents must be fed data first:"
echo "  @bot Remember: Domain $450K/mo, 12 staff..."
echo ""
read -p "Continue? (y/n): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
  exit 0
fi

echo ""
echo "Test prompts to send in Telegram:"
echo ""
echo "Agent 1 (Franchise):"
echo "  @bot franchise: Model out Tampa launch. Show me the math."
echo ""
echo "Agent 2 (Operations):"
echo "  @bot ops: Which location is overstaffed?"
echo ""
echo "Agent 3 (Streamlining):"
echo "  @bot streamline: SoCo labor is 30%. Fix?"
echo ""
echo "After sending these, agents should respond within 5-10 seconds."
echo ""
