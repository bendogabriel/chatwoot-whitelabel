#!/bin/bash
# View logs for Nexa AI Platform services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.nexa-platform.yml"

SERVICE="${1:-}"

if [ -z "$SERVICE" ]; then
    echo "📋 Available services:"
    echo "  - chatwoot_app"
    echo "  - chatwoot_sidekiq"
    echo "  - atlas_nexa"
    echo "  - dashboard"
    echo "  - postgres"
    echo "  - redis"
    echo "  - n8n"
    echo ""
    echo "📊 Showing logs for all services (use Ctrl+C to stop)..."
    echo ""
    docker-compose -f "$COMPOSE_FILE" logs -f
else
    echo "📊 Showing logs for $SERVICE (use Ctrl+C to stop)..."
    echo ""
    docker-compose -f "$COMPOSE_FILE" logs -f "$SERVICE"
fi
