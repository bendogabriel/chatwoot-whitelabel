#!/bin/bash
# Start Nexa AI Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.nexa-platform.yml"
ENV_FILE="$DOCKER_DIR/.env"

echo "🚀 Starting Nexa AI Platform..."
echo ""

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found!"
    echo ""
    echo "Please create .env file from template:"
    echo "  cp $DOCKER_DIR/.env.template $ENV_FILE"
    echo ""
    echo "Then edit $ENV_FILE with your configuration."
    exit 1
fi

# Check if required variables are set
echo "📋 Checking configuration..."
source "$ENV_FILE"

REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "REDIS_PASSWORD"
    "CHATWOOT_SECRET_KEY"
    "CHATWOOT_DOMAIN"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ] || [[ "${!var}" == CHANGE_ME* ]]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Error: Missing or invalid configuration!"
    echo ""
    echo "Please set the following variables in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    exit 1
fi

echo "✅ Configuration valid"
echo ""

# Pull images
echo "📦 Pulling Docker images..."
docker-compose -f "$COMPOSE_FILE" pull

# Start services
echo "🐳 Starting services..."
docker-compose -f "$COMPOSE_FILE" up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check service health
echo ""
echo "🏥 Checking service health..."
docker-compose -f "$COMPOSE_FILE" ps

# Initialize databases (if first run)
if ! docker exec nexa_postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw chatwoot; then
    echo ""
    echo "🗄️  Initializing databases (first run)..."

    echo "  • Initializing Chatwoot database..."
    docker exec -it nexa_chatwoot_app bundle exec rails db:chatwoot_prepare

    echo "  • Creating Chatwoot admin user..."
    docker exec -it nexa_chatwoot_app bundle exec rails db:seed

    # TODO: Initialize Atlas Nexa database when available
    # docker exec -it nexa_atlas_sdr npm run migrate
fi

echo ""
echo "✅ Nexa AI Platform started successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Access Points:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Chatwoot:  ${CHATWOOT_URL}"
echo "  Dashboard: https://${DASHBOARD_DOMAIN}"
echo "  N8N:       https://${N8N_DOMAIN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Next Steps:"
echo "  1. Login to Chatwoot with admin credentials"
echo "  2. Create API token: Settings → Integrations → API"
echo "  3. Add token to .env: CHATWOOT_API_TOKEN=..."
echo "  4. Restart stack: ./scripts/restart.sh"
echo ""
echo "📊 View logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "🛑 Stop platform:"
echo "  ./scripts/stop.sh"
echo ""
