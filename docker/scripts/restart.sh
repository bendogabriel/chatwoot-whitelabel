#!/bin/bash
# Restart Nexa AI Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Restarting Nexa AI Platform..."
echo ""

"$SCRIPT_DIR/stop.sh"
sleep 3
"$SCRIPT_DIR/start.sh"
