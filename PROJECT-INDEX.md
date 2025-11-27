# Nexa AI Platform - Complete Project Index

**Quick navigation guide for all project files**

---

## 📚 Start Here

| Document | When to Use |
|----------|-------------|
| [README.md](README.md) | Project overview, tech stack, architecture |
| [EXECUTIVE-SUMMARY.md](EXECUTIVE-SUMMARY.md) | Business value, ROI, roadmap |
| **This file** | Find any document quickly |

---

## 📖 Core Documentation

### 1. Architecture & Planning

- **[01-CURRENT-ARCHITECTURE.md](docs/01-CURRENT-ARCHITECTURE.md)**
  - Existing Chatwoot stack analysis
  - Database schema, network topology
  - Resource allocation
  - Strengths and limitations

- **[02-WHITELABEL-PLAN.md](docs/02-WHITELABEL-PLAN.md)**
  - Files to modify for branding
  - Build vs runtime customization
  - CSS and color schemes
  - Email template customization
  - Cost-benefit analysis

### 2. Implementation

- **[03-BUILD-PROCESS.md](docs/03-BUILD-PROCESS.md)**
  - How to fork Chatwoot repository
  - Building custom Docker image
  - Testing and validation
  - CI/CD automation (GitHub Actions)
  - Troubleshooting build issues

- **[04-INTEGRATION-ARCHITECTURE.md](docs/04-INTEGRATION-ARCHITECTURE.md)**
  - Atlas Nexa ↔ Chatwoot integration
  - Data model alignment
  - API endpoints and webhooks
  - N8N workflow automation
  - Real-time sync strategies

### 3. Operations

- **[05-DEPLOYMENT-GUIDE.md](docs/05-DEPLOYMENT-GUIDE.md)**
  - Step-by-step server setup
  - SSL/TLS configuration
  - Firewall and security hardening
  - Backup and monitoring
  - Client handoff procedures
  - Troubleshooting guide

---

## 🐳 Infrastructure Files

### Docker Deployment

- **[docker-compose.nexa-platform.yml](docker/docker-compose.nexa-platform.yml)**
  - Unified stack (all services)
  - PostgreSQL + Redis + Chatwoot + Atlas + Dashboard + N8N
  - Traefik reverse proxy
  - Health checks, resource limits

- **[.env.template](docker/.env.template)**
  - Environment variables template
  - Client branding configuration
  - Database credentials
  - API keys and secrets

### Helper Scripts

Located in `docker/scripts/`:

- **[start.sh](docker/scripts/start.sh)** - Start all services (with first-run initialization)
- **[stop.sh](docker/scripts/stop.sh)** - Graceful shutdown
- **[restart.sh](docker/scripts/restart.sh)** - Zero-downtime restart
- **[logs.sh](docker/scripts/logs.sh)** - View logs for specific service or all
- **[init-databases.sh](docker/scripts/init-databases.sh)** - PostgreSQL multi-database setup

---

## 🎨 Template System

### Configuration Templates

- **[templates/README.md](templates/README.md)**
  - Complete guide to template system
  - How to create client configs
  - YAML structure reference
  - Best practices

- **[client-config.template.yml](templates/client-config.template.yml)**
  - Blank template for new clients
  - All available options documented
  - Copy and customize for each client

- **[example-corp.yml](clients/example-corp.yml)**
  - Working example configuration
  - Demonstrates all features
  - Use as reference

### Automation Scripts

- **[generate-client-config.py](scripts/generate-client-config.py)**
  - Reads client YAML config
  - Generates `.env` file with secrets
  - Creates DNS configuration guide
  - Produces deployment checklist
  - Auto-generates README

---

## 🔌 Integration Components

### N8N Workflows

Located in `n8n-workflows/` (to be created):

- `atlas-chatwoot-handoff.json` - Lead qualification → Chatwoot conversation
- `chatwoot-atlas-sync.json` - Conversation updates → Atlas Nexa database

### API Integration

Covered in [04-INTEGRATION-ARCHITECTURE.md](docs/04-INTEGRATION-ARCHITECTURE.md):

- Chatwoot API endpoints
- Atlas Nexa webhooks
- N8N workflow examples
- Database sync queries

---

## 📊 Current Stack Reference

### Existing Chatwoot (Portainer)

Located in `chatwoot/`:

- **[stack chatwoot.txt](chatwoot/stack chatwoot.txt)** - Current Chatwoot services config
- **[stack postgres.txt](chatwoot/stack postgres.txt)** - PostgreSQL configuration
- **[stack redis.txt](chatwoot/stack redis.txt)** - Redis configuration

**Status:** Running in production at https://chatwoot.nexateam.com.br

---

## 🗂️ Directory Structure

```
nexa-platform/
│
├── 📄 README.md                      # Project overview
├── 📄 EXECUTIVE-SUMMARY.md           # Business summary
├── 📄 PROJECT-INDEX.md               # This file
│
├── 📁 docs/                          # Complete documentation
│   ├── 01-CURRENT-ARCHITECTURE.md
│   ├── 02-WHITELABEL-PLAN.md
│   ├── 03-BUILD-PROCESS.md
│   ├── 04-INTEGRATION-ARCHITECTURE.md
│   └── 05-DEPLOYMENT-GUIDE.md
│
├── 📁 docker/                        # Deployment infrastructure
│   ├── docker-compose.nexa-platform.yml
│   ├── .env.template
│   └── scripts/
│       ├── start.sh
│       ├── stop.sh
│       ├── restart.sh
│       ├── logs.sh
│       └── init-databases.sh
│
├── 📁 templates/                     # Client configuration
│   ├── README.md
│   └── client-config.template.yml
│
├── 📁 clients/                       # Client configs (git-ignored)
│   └── example-corp.yml
│
├── 📁 generated/                     # Auto-generated (git-ignored)
│   └── <client-id>/
│       ├── .env
│       ├── DNS-CONFIG.md
│       ├── DEPLOYMENT-CHECKLIST.md
│       └── README.md
│
├── 📁 scripts/                       # Automation
│   └── generate-client-config.py
│
├── 📁 n8n-workflows/                 # Integration workflows
│   ├── atlas-chatwoot-handoff.json
│   └── chatwoot-atlas-sync.json
│
└── 📁 chatwoot/                      # Current stack reference
    ├── stack chatwoot.txt
    ├── stack postgres.txt
    └── stack redis.txt
```

---

## 🚀 Common Workflows

### Deploy New Client

1. **Create configuration:**
   ```bash
   cp templates/client-config.template.yml clients/new-client.yml
   nano clients/new-client.yml
   ```

2. **Generate deployment files:**
   ```bash
   python scripts/generate-client-config.py clients/new-client.yml
   ```

3. **Review outputs:**
   ```bash
   cd generated/new-client
   cat .env                        # Verify configuration
   cat DNS-CONFIG.md              # Send to client
   cat DEPLOYMENT-CHECKLIST.md   # Follow steps
   ```

4. **Deploy:**
   - Follow [DEPLOYMENT-CHECKLIST.md](docs/05-DEPLOYMENT-GUIDE.md)
   - Or see: `generated/<client-id>/DEPLOYMENT-CHECKLIST.md`

### Build Custom Chatwoot Image

Follow: [03-BUILD-PROCESS.md](docs/03-BUILD-PROCESS.md)

Quick commands:
```bash
cd chatwoot-custom
./scripts/apply-whitelabel.sh
./scripts/build-custom-image.sh v3.15.0
docker push nexateam/chatwoot-custom:v3.15.0
```

### Update Documentation

1. **Edit relevant doc:**
   - Architecture changes → `docs/01-CURRENT-ARCHITECTURE.md`
   - Build process changes → `docs/03-BUILD-PROCESS.md`
   - New integration → `docs/04-INTEGRATION-ARCHITECTURE.md`

2. **Update this index if needed**

3. **Commit changes:**
   ```bash
   git add docs/
   git commit -m "Update documentation: <what changed>"
   git push
   ```

### Troubleshoot Deployment

1. **Check logs:**
   ```bash
   cd docker
   ./scripts/logs.sh <service-name>
   # Example: ./scripts/logs.sh chatwoot_app
   ```

2. **Common issues:**
   - See: [05-DEPLOYMENT-GUIDE.md#troubleshooting](docs/05-DEPLOYMENT-GUIDE.md#troubleshooting)
   - Or: `generated/<client-id>/DEPLOYMENT-CHECKLIST.md` (includes troubleshooting)

3. **Database issues:**
   ```bash
   docker exec -it nexa_postgres psql -U postgres -l
   docker exec -it nexa_postgres pg_isready
   ```

---

## 📋 Checklists

### Pre-Deployment Checklist

Before deploying for a new client:

- [ ] Client YAML config created and validated
- [ ] Generated deployment files reviewed
- [ ] DNS records configured and propagated
- [ ] Server provisioned (DigitalOcean or equivalent)
- [ ] API keys obtained (OpenAI, WhatsApp, SMTP)
- [ ] Custom Chatwoot image built and pushed
- [ ] Backup strategy planned

### Post-Deployment Checklist

After successful deployment:

- [ ] All services healthy (`docker ps` shows all running)
- [ ] SSL certificates issued and valid
- [ ] Chatwoot admin account created
- [ ] API token generated
- [ ] N8N workflows imported and activated
- [ ] Integration tested (WhatsApp → Atlas → Chatwoot)
- [ ] Client admin user created
- [ ] Access credentials sent securely
- [ ] Monitoring and alerting configured
- [ ] Backup verified

---

## 🔍 Quick Search

### I want to...

**...deploy a new client**
→ [templates/README.md](templates/README.md)
→ [05-DEPLOYMENT-GUIDE.md](docs/05-DEPLOYMENT-GUIDE.md)

**...customize Chatwoot branding**
→ [02-WHITELABEL-PLAN.md](docs/02-WHITELABEL-PLAN.md)
→ [03-BUILD-PROCESS.md](docs/03-BUILD-PROCESS.md)

**...integrate Atlas Nexa with Chatwoot**
→ [04-INTEGRATION-ARCHITECTURE.md](docs/04-INTEGRATION-ARCHITECTURE.md)

**...understand the architecture**
→ [01-CURRENT-ARCHITECTURE.md](docs/01-CURRENT-ARCHITECTURE.md)
→ [README.md](README.md)

**...see business value and ROI**
→ [EXECUTIVE-SUMMARY.md](EXECUTIVE-SUMMARY.md)

**...troubleshoot deployment issues**
→ [05-DEPLOYMENT-GUIDE.md#troubleshooting](docs/05-DEPLOYMENT-GUIDE.md)

**...automate client configuration**
→ [templates/README.md](templates/README.md)
→ [generate-client-config.py](scripts/generate-client-config.py)

---

## 📞 Support

### Internal (Nexa Team)

- **Slack:** #nexa-platform-dev
- **Issues:** GitHub Issues (this repo)
- **Documentation:** All files in this project

### External (Clients)

- **Email:** support@nexateam.com.br
- **WhatsApp:** +55 11 9 9999-9999
- **Docs:** Send link to relevant guide

---

## 🔄 Project Status

**Version:** 1.0.0
**Status:** ✅ Production Ready
**Last Updated:** 2025-11-06

**Next Milestone:** First client deployment

---

**Need something not listed here?**
Check [README.md](README.md) or [EXECUTIVE-SUMMARY.md](EXECUTIVE-SUMMARY.md)
