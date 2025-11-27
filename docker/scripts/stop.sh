#!/bin/bash
# Stop Nexa AI Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.nexa-platform.yml"

echo "🛑 Stopping Nexa AI Platform..."
echo ""

docker-compose -f "$COMPOSE_FILE" down

echo ""
echo "✅ Nexa AI Platform stopped"
echo ""
echo "💡 To remove volumes (⚠️  deletes all data):"
echo "   docker-compose -f $COMPOSE_FILE down -v"
echo ""
