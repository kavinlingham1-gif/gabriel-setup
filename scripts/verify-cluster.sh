#!/bin/bash
echo "Verifying Gabriel cluster..."
echo ""

MACHINES=("sovereign-studio-1" "sovereign-3" "sovereign-4" "sovereign-5")
ALL_UP=true

for machine in "${MACHINES[@]}"; do
  if ping -c 1 "$machine.local" &> /dev/null; then
    echo "✅ $machine is online"
  else
    echo "❌ $machine is offline"
    ALL_UP=false
  fi
done

echo ""
if [ "$ALL_UP" = true ]; then
  echo "✅ All machines online. Cluster ready."
  exit 0
else
  echo "❌ Some machines offline. Check Tailscale and WiFi."
  exit 1
fi
