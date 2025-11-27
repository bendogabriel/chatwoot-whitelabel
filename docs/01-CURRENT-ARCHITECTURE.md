# Current Chatwoot Architecture Analysis

**Date:** 2025-11-06
**Version:** Chatwoot v3.15.0
**Environment:** Docker Swarm + Portainer
**Domain:** chatwoot.nexateam.com.br

---

## Stack Overview

The current Chatwoot deployment consists of 3 separate stacks in Portainer:

### 1. PostgreSQL Stack (pgvector/pg16)

```yaml
Image: pgvector/pgvector:pg16
Purpose: Primary database + Vector embeddings support
Resources: 1 CPU, 2GB RAM
Network: minha_rede (external)
Volume: postgres_data (external, persistent)
```

**Key Features:**
- ✅ **pgvector extension** - Ready for RAG/embeddings (Atlas Nexa integration)
- ✅ Timezone: America/Sao_Paulo
- ✅ Persistent storage
- ✅ Production-grade resource limits

**Environment:**
- `POSTGRES_PASSWORD`: KEqXBMXMU4sC44UV
- Default database: `chatwoot` (created by Chatwoot)

---

### 2. Redis Stack

```yaml
Image: redis:latest
Purpose: Cache + background job queue (Sidekiq)
Resources: 1 CPU, 1GB RAM
Network: minha_rede (external)
Volume: redis_data (external, persistent)
```

**Configuration:**
- AOF (Append Only File) enabled for persistence
- Port: 6379 (internal)
- Command: `redis-server --appendonly yes --port 6379`

**Used by:**
- Chatwoot Rails app (session cache, action cable)
- Sidekiq (background job queue)
- **Can be shared with Atlas Nexa** (different database number)

---

### 3. Chatwoot Application Stack

```yaml
Image: chatwoot/chatwoot:v3.15.0
Services:
  - chatwoot_app (Rails web server)
  - chatwoot_sidekiq (Background jobs processor)
Resources: 1 CPU, 1GB RAM (each service)
Network: minha_rede (external)
Volume: chatwoot_data (external, shared between both services)
```

#### Service: chatwoot_app (Rails Server)

**Command:** `bundle exec rails s -p 3000 -b 0.0.0.0`
**Entrypoint:** `docker/entrypoints/rails.sh`
**Port:** 3000 (internal)

**Traefik Configuration:**
- Domain: `chatwoot.nexateam.com.br`
- HTTPS with Let's Encrypt (certresolver: le)
- HTTP → HTTPS redirect
- Load balancer: port 3000

**Key Features:**
- ✅ Brazilian Portuguese locale (pt_BR)
- ✅ SSL enforcement
- ✅ Account signup disabled (admin-only)
- ✅ Gmail SMTP integration
- ✅ Bot uses inbox avatar

#### Service: chatwoot_sidekiq (Background Worker)

**Command:** `bundle exec sidekiq -C config/sidekiq.yml`

**Responsibilities:**
- Email sending (async)
- Webhook processing
- Report generation
- Message delivery status updates
- Scheduled jobs (follow-ups, auto-assignments)

**Same environment variables as Rails app** (shared configuration)

---

## Environment Variables Analysis

### Critical Configuration

| Variable | Value | Purpose |
|----------|-------|---------|
| `INSTALLATION_NAME` | chatwoot | Instance identifier |
| `SECRET_KEY_BASE` | N4HqZRHH9gzWbDOJBobLWiWpaM2Vw1Qt | Rails secret (⚠️ must be unique per instance) |
| `FRONTEND_URL` | https://chatwoot.nexateam.com.br | Used for links in emails, webhooks |
| `DEFAULT_LOCALE` | pt_BR | Brazilian Portuguese interface |
| `FORCE_SSL` | true | Enforce HTTPS |
| `ENABLE_ACCOUNT_SIGNUP` | false | Only admins can create accounts |

### Database Connection

| Variable | Value | Notes |
|----------|-------|-------|
| `POSTGRES_HOST` | postgres | DNS name in Docker network |
| `POSTGRES_USERNAME` | postgres | Default user |
| `POSTGRES_PASSWORD` | KEqXBMXMU4sC44UV | ⚠️ Should be in secrets |
| `POSTGRES_DATABASE` | chatwoot | Auto-created on first run |
| `REDIS_URL` | redis://redis:6379 | Redis connection string |

### Storage & Email

| Variable | Value | Notes |
|----------|-------|-------|
| `ACTIVE_STORAGE_SERVICE` | local | Files stored in `/app/storage` volume |
| `SMTP_ADDRESS` | smtp.gmail.com | Gmail SMTP |
| `SMTP_PORT` | 587 | STARTTLS |
| `SMTP_USERNAME` | seuemail@gmail.com | ⚠️ Placeholder, needs real email |
| `SMTP_PASSWORD` | suasenhadeapp | ⚠️ App password required |

---

## Network Architecture

```
Internet (HTTPS)
    ↓
Traefik (reverse proxy, SSL termination)
    ↓
chatwoot_app:3000 (Rails)
    ↓
├── postgres:5432 (database)
├── redis:6379 (cache/jobs)
└── chatwoot_sidekiq (background worker)
```

**Network:** `minha_rede` (Docker bridge, external)

All services communicate via Docker DNS:
- `postgres` → resolves to PostgreSQL container
- `redis` → resolves to Redis container

---

## Storage Volumes

| Volume | Purpose | Mount Point | Shared |
|--------|---------|-------------|--------|
| `postgres_data` | PostgreSQL database files | `/var/lib/postgresql/data` | No |
| `redis_data` | Redis AOF persistence | `/data` | No |
| `chatwoot_data` | Uploaded files, attachments | `/app/storage` | Yes (app + sidekiq) |

**Important:** `chatwoot_data` is shared between Rails app and Sidekiq worker for file access.

---

## Resource Allocation

**Total Resources:**
- **CPU:** 4 cores (1 per service)
- **RAM:** 5GB (Postgres 2GB, others 1GB each)

**Deployment:**
- Swarm mode: `node.role == manager` (all services on manager node)
- Replicas: 1 per service (no HA yet)

---

## Migration & Initialization

**On first deployment, run:**

```bash
docker exec -it <chatwoot_app_container_id> bundle exec rails db:chatwoot_prepare
```

This command:
1. Creates database if not exists
2. Runs migrations
3. Seeds initial data (default account, inbox types)
4. Sets up default configuration

---

## Current Limitations

### White-Label Challenges

1. **Branding:**
   - ❌ Logo shows "Chatwoot" in UI
   - ❌ Footer links to chatwoot.com
   - ❌ Email templates have Chatwoot branding
   - ❌ Mobile apps connect to official Chatwoot
   - ❌ Help docs point to docs.chatwoot.com

2. **Multi-Tenancy:**
   - ⚠️ Single installation name (all clients share same instance)
   - ⚠️ Cannot easily create isolated instances per client
   - ⚠️ Shared SECRET_KEY_BASE across all accounts

3. **Customization:**
   - ❌ Cannot change UI colors without forking
   - ❌ Cannot add custom features without code changes
   - ❌ Hard to inject client-specific branding dynamically

### Integration Challenges

1. **API Access:**
   - ✅ REST API available (needs access token)
   - ⚠️ No documented webhook for "lead qualified" event
   - ⚠️ Need custom integration for Atlas Nexa handoff

2. **Database Isolation:**
   - ⚠️ Single Postgres instance for all clients
   - ⚠️ Need multi-database strategy for client isolation

3. **Scalability:**
   - ⚠️ Single replica (no horizontal scaling)
   - ⚠️ All services on manager node (single point of failure)

---

## Strengths of Current Setup

✅ **Production-ready:** SSL, persistence, proper resource limits
✅ **Modern stack:** Latest Redis, PostgreSQL 16 with pgvector
✅ **Clean architecture:** Separate stacks for each component
✅ **Portuguese support:** Already configured for Brazilian market
✅ **Email configured:** SMTP ready for notifications
✅ **Bot-friendly:** `USE_INBOX_AVATAR_FOR_BOT=true` improves UX

---

## Next Steps

Based on this analysis, the white-label + integration project will need:

1. **Fork Chatwoot** - Custom Docker image with branding removed
2. **Multi-instance strategy** - One stack per client OR database isolation
3. **Atlas Nexa integration** - API bridge for lead handoff
4. **Template system** - Environment-based branding configuration
5. **Unified stack** - Single docker-compose with all services

See next document: `02-WHITELABEL-PLAN.md`
