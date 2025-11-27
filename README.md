# Nexa AI Platform - White-Label Chatwoot + Atlas Nexa

**Complete white-labeled customer support platform combining AI SDR (Atlas Nexa) with human support (Chatwoot)**

---

## Overview

Nexa AI Platform is a production-ready, white-labeled solution that integrates:

- **Chatwoot** (customized) - Human agent inbox, CRM, multi-channel support
- **Atlas Nexa** - AI-powered SDR agent for lead qualification
- **Dashboard** - Unified analytics and reporting
- **N8N** - Workflow automation for seamless handoffs

**Key Features:**
- ✅ Full white-label (remove all "Chatwoot" branding)
- ✅ Automated lead qualification (AI scores 1-10)
- ✅ Seamless bot-to-human handoff
- ✅ Multi-client deployment (one stack per client)
- ✅ Environment-based branding (logo, colors, domain)
- ✅ Production-ready (SSL, backups, monitoring)

---

## Quick Start

### 🐳 Usa Portainer? (Recomendado para Você!)

**Você usa Portainer e só sabe copiar/colar YAMLs?**

👉 **[COMECE-AQUI-PORTAINER.md](COMECE-AQUI-PORTAINER.md)**

Tudo pronto para usar direto no Portainer:
- ✅ Stacks prontas (copiar/colar)
- ✅ Sem linha de comando
- ✅ Guia passo a passo com interface
- ✅ Deploy em 10 minutos

**Arquivos:** [`portainer-stacks/`](portainer-stacks/)

---

### 💻 Usa Docker Compose via Terminal?

**Para quem prefere linha de comando:**

```bash
# 1. Create client configuration
cp templates/client-config.template.yml clients/your-client.yml
nano clients/your-client.yml  # Fill in client details

# 2. Generate deployment files
python scripts/generate-client-config.py clients/your-client.yml

# 3. Deploy to server
cd generated/your-client
# Follow DEPLOYMENT-CHECKLIST.md
```

---

### 🔗 Já Tem Chatwoot Rodando?

Integrar Atlas Nexa com Chatwoot existente:

**Via Portainer:**
- [`portainer-stacks/INICIO-RAPIDO.md`](portainer-stacks/INICIO-RAPIDO.md) → Passo 3 em diante

**Via Terminal:**
```bash
# See: docs/04-INTEGRATION-ARCHITECTURE.md
# Quick steps:
# 1. Deploy Atlas Nexa container
# 2. Configure N8N workflows
# 3. Generate Chatwoot API token
# 4. Test handoff
```

---

## Documentation

### Core Guides

1. **[Current Architecture](docs/01-CURRENT-ARCHITECTURE.md)**
   - Analysis of existing Chatwoot stack
   - Database schema, network topology
   - Resource allocation

2. **[White-Label Plan](docs/02-WHITELABEL-PLAN.md)**
   - Files to modify for branding
   - Build vs runtime customization
   - CSS/color customization

3. **[Build Process](docs/03-BUILD-PROCESS.md)**
   - How to fork Chatwoot
   - Building custom Docker image
   - Testing and validation

4. **[Integration Architecture](docs/04-INTEGRATION-ARCHITECTURE.md)**
   - Atlas Nexa ↔ Chatwoot integration
   - API endpoints, webhooks
   - Data model alignment

5. **[Deployment Guide](docs/05-DEPLOYMENT-GUIDE.md)**
   - Step-by-step server setup
   - SSL configuration
   - Backup and monitoring

### Quick References

- **[Template System](templates/README.md)** - Automated client config generator
- **[Docker Compose](docker/docker-compose.nexa-platform.yml)** - Unified stack
- **[Scripts](docker/scripts/)** - Start, stop, logs, backup

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Nexa AI Platform                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  WhatsApp → Evolution API → Atlas Nexa (AI SDR)            │
│                                  │                          │
│                                  ▼                          │
│                          Lead Scoring (1-10)                │
│                                  │                          │
│                    ┌─────────────┴─────────────┐            │
│                    ▼                           ▼            │
│              Score < 7                    Score >= 7        │
│         (Keep in bot)                 (Hand to human)       │
│                                              │              │
│                                              ▼              │
│                                  Create conversation        │
│                                  in Chatwoot via API        │
│                                              │              │
│                                              ▼              │
│                                    Human Agent Inbox        │
│                                       (Chatwoot)            │
│                                              │              │
│                                              ▼              │
│                                    Dashboard Analytics      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Shared Infrastructure:**
- PostgreSQL (pgvector) - Supports both Chatwoot and Atlas Nexa
- Redis - Cache and background jobs
- Traefik - Reverse proxy with auto-SSL

---

## Repository Structure

```
nexa-platform/
├── docs/                           # Complete documentation
│   ├── 01-CURRENT-ARCHITECTURE.md
│   ├── 02-WHITELABEL-PLAN.md
│   ├── 03-BUILD-PROCESS.md
│   ├── 04-INTEGRATION-ARCHITECTURE.md
│   └── 05-DEPLOYMENT-GUIDE.md
│
├── docker/                         # Deployment files
│   ├── docker-compose.nexa-platform.yml   # Unified stack
│   ├── .env.template              # Environment variables template
│   └── scripts/                   # Helper scripts
│       ├── start.sh               # Start all services
│       ├── stop.sh                # Stop all services
│       ├── logs.sh                # View logs
│       └── init-databases.sh      # Database initialization
│
├── templates/                      # Client configuration templates
│   ├── README.md                  # Template system guide
│   └── client-config.template.yml # YAML template
│
├── clients/                        # Client configs (git-ignored)
│   └── example-corp.yml           # Example configuration
│
├── generated/                      # Generated configs (git-ignored)
│   └── <client-id>/
│       ├── .env                   # Generated environment file
│       ├── DNS-CONFIG.md          # DNS setup guide
│       ├── DEPLOYMENT-CHECKLIST.md
│       └── README.md
│
├── scripts/                        # Automation scripts
│   ├── generate-client-config.py  # Config generator
│   └── build-custom-image.sh      # Docker image builder
│
├── n8n-workflows/                  # N8N automation workflows
│   ├── atlas-chatwoot-handoff.json
│   └── chatwoot-atlas-sync.json
│
└── chatwoot/                       # Current Chatwoot stack
    ├── stack chatwoot.txt
    ├── stack postgres.txt
    └── stack redis.txt
```

---

## Technology Stack

### Frontend
- **Chatwoot UI:** Vue.js 3, Tailwind CSS
- **Dashboard:** React 19, Vite, Tailwind

### Backend
- **Chatwoot:** Ruby on Rails 7
- **Atlas Nexa:** Node.js (or Python, depending on implementation)
- **N8N:** Node.js workflow automation

### Database & Cache
- **PostgreSQL 16** with pgvector extension (RAG support)
- **Redis 7** (cache, sessions, job queue)

### Infrastructure
- **Docker Compose** (development, small deployments)
- **Docker Swarm** (current Portainer setup)
- **Kubernetes** (planned, for 20+ clients)

### External Services
- **OpenAI GPT-4** - AI conversation and qualification
- **ElevenLabs** - Voice messages (optional)
- **WhatsApp Business API** - Message delivery
- **Gmail/SMTP** - Email notifications

---

## Use Cases

### 1. SaaS Product (Multi-Tenant)

Deploy one instance, multiple clients share same platform:

```bash
# Single server, database isolation per client
# Not recommended for production (data isolation concerns)
```

### 2. White-Label as a Service

Deploy one stack per client on separate servers:

```bash
# Client A: server-a.digitalocean.com
# Client B: server-b.digitalocean.com
# Client C: server-c.digitalocean.com

# Recommended approach (best isolation, customization)
```

### 3. Internal Use (Nexa Team)

Deploy for your own business:

```bash
# domains:
#   inbox: inbox.nexateam.com.br
#   atlas: atlas.nexateam.com.br
#   dashboard: dashboard.nexateam.com.br
```

---

## Pricing Model

### Infrastructure Costs (Per Client)

- **Server:** $24/month (DigitalOcean 4GB droplet)
- **Backups:** $5/month (DigitalOcean Spaces)
- **Domain:** $0 (client provides) or $12/year
- **SSL:** $0 (Let's Encrypt)

**Total:** ~$30/month per client

### SaaS Costs

- **OpenAI API:** ~$20-50/month (depends on usage)
- **WhatsApp API:** ~$10-30/month (depends on provider)

**Total variable:** ~$30-80/month

### Revenue Model

Charge clients: **$200-500/month**

**Gross margin:** 70-85%

**At scale (20 clients):**
- Infrastructure: $600/month
- Revenue: $4,000-10,000/month
- **Profit:** $3,400-9,400/month

---

## Roadmap

### ✅ Phase 1: Core Platform (Current)
- [x] Chatwoot white-label build process
- [x] Atlas Nexa integration architecture
- [x] Docker Compose unified stack
- [x] Template configuration system
- [x] Deployment documentation

### 🚧 Phase 2: Automation (In Progress)
- [ ] Terraform scripts for infrastructure provisioning
- [ ] Ansible playbooks for automated deployment
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Monitoring stack (Prometheus + Grafana)

### 📋 Phase 3: Enterprise Features (Planned)
- [ ] Kubernetes deployment (20+ clients)
- [ ] Multi-region support
- [ ] Advanced analytics dashboard
- [ ] Custom AI models per client
- [ ] Voice call support (Twilio integration)

### 🔮 Phase 4: Platform (Future)
- [ ] Self-service client portal
- [ ] Billing and subscription management
- [ ] Marketplace for integrations
- [ ] Mobile apps (iOS, Android)

---

## Contributing

This is a private repository for Nexa Team.

**Internal workflow:**
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes, test thoroughly
3. Update documentation
4. Create pull request
5. Review and merge

**Documentation updates:**
- Always update relevant docs when changing architecture
- Add examples for new features
- Keep README.md up-to-date

---

## Support

### For Nexa Team

- **Internal Slack:** #nexa-platform-dev
- **Documentation:** All docs in `docs/` directory
- **Issues:** GitHub Issues (this repo)

### For Clients

- **Email:** support@nexateam.com.br
- **WhatsApp:** +55 11 9 9999-9999
- **Knowledge Base:** docs.nexateam.com.br

---

## Security

**⚠️ Important Security Notes:**

1. **Never commit secrets:**
   - `.env` files are git-ignored
   - API keys should be in password manager
   - Use environment variables for all secrets

2. **Client data isolation:**
   - Each client gets own database
   - Separate servers recommended
   - No shared credentials

3. **Access control:**
   - Minimal permissions principle
   - Regular credential rotation
   - 2FA for all admin accounts

4. **Backup encryption:**
   - All backups encrypted at rest
   - Secure transfer protocols only
   - Regular backup testing

---

## License

**Proprietary - Nexa Team**

This software is proprietary to Nexa Team and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

**Chatwoot (upstream):** MIT License
**Our customizations:** Proprietary

---

## Credits

**Built by Nexa Team:**
- **Gabriel Bendo** - CEO, Lead Developer
- **Nexa Development Team** - Engineering

**Based on:**
- [Chatwoot](https://github.com/chatwoot/chatwoot) - Open-source customer engagement platform
- Built with Ruby on Rails, Vue.js, PostgreSQL

---

## Quick Links

- 📚 [Complete Documentation](docs/)
- 🚀 [Deployment Guide](docs/05-DEPLOYMENT-GUIDE.md)
- 🎨 [White-Label Guide](docs/02-WHITELABEL-PLAN.md)
- 🔧 [Build Process](docs/03-BUILD-PROCESS.md)
- 🔌 [Integration Guide](docs/04-INTEGRATION-ARCHITECTURE.md)
- 📝 [Template System](templates/README.md)

---

**Last Updated:** 2025-11-06
**Version:** 1.0.0
**Status:** Production Ready ✅
