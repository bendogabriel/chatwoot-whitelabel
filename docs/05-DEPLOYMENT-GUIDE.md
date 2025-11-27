# Nexa AI Platform - Deployment Guide

**Complete guide to deploy white-labeled Chatwoot + Atlas Nexa + Dashboard for new clients**

---

## Pre-Deployment Checklist

### Infrastructure Requirements

**Minimum Server Specs:**
- ✅ 4 CPU cores
- ✅ 8GB RAM
- ✅ 50GB SSD storage
- ✅ Ubuntu 20.04+ or Debian 11+
- ✅ Docker 20.10+ and Docker Compose 2.x

**Network Requirements:**
- ✅ Domain names configured (DNS A records)
- ✅ Ports 80, 443 open (for Traefik)
- ✅ SMTP server access (for emails)

**External Services:**
- ✅ OpenAI API key (for Atlas Nexa)
- ✅ WhatsApp Business API credentials
- ✅ Email SMTP credentials

---

## Deployment Options

### Option A: Docker Swarm (Current Setup)

**Pros:**
- ✅ Already configured in Portainer
- ✅ Easy to manage via UI
- ✅ Simple scaling

**Cons:**
- ❌ Manual deployment per client
- ❌ Hard to automate

### Option B: Docker Compose (Recommended for New Clients)

**Pros:**
- ✅ Single YAML file
- ✅ Easy to replicate
- ✅ Version controlled

**Cons:**
- ❌ No built-in HA (high availability)

### Option C: Kubernetes (Future)

**Pros:**
- ✅ Auto-scaling
- ✅ High availability
- ✅ Production-grade

**Cons:**
- ❌ Complex setup
- ❌ Overkill for <10 clients

**Recommendation for Nexa:** Start with **Option B** (Docker Compose), migrate to **Option C** (K8s) when >20 clients.

---

## Step-by-Step Deployment

### Phase 1: Server Preparation

#### 1.1 Provision Server

**DigitalOcean Droplet (Recommended):**
```bash
# Create droplet via CLI
doctl compute droplet create nexa-client-abc \
  --region nyc3 \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys <your-ssh-key-id>

# Get IP address
doctl compute droplet get nexa-client-abc --format PublicIPv4
```

**Or manually:** Create 4GB RAM droplet in DigitalOcean dashboard

#### 1.2 Configure DNS

Add A records for client domains:

```
Type  Name         Value           TTL
A     inbox        <server-ip>     300
A     atlas        <server-ip>     300
A     dashboard    <server-ip>     300
A     n8n          <server-ip>     300
```

**Verify DNS propagation:**
```bash
dig inbox.client.com +short
# Should return server IP
```

#### 1.3 Install Docker & Docker Compose

```bash
# SSH into server
ssh root@<server-ip>

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
apt install docker-compose-plugin -y

# Verify installations
docker --version
docker compose version

# Enable Docker service
systemctl enable docker
systemctl start docker
```

#### 1.4 Install Portainer (Optional, for UI management)

```bash
docker volume create portainer_data

docker run -d \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Access: https://<server-ip>:9443
```

---

### Phase 2: Deploy Nexa Platform

#### 2.1 Clone Repository

```bash
# Create project directory
mkdir -p /opt/nexa-platform
cd /opt/nexa-platform

# Clone (or upload files via SCP)
git clone https://github.com/nexateam/chatwoot-whitelabel.git .

# Or via SCP from local machine:
# scp -r chatwoot-whitelabel/ root@<server-ip>:/opt/nexa-platform/
```

#### 2.2 Configure Environment

```bash
cd /opt/nexa-platform/docker

# Copy template
cp .env.template .env

# Edit configuration
nano .env
```

**Fill in client-specific values:**

```bash
# Client branding
CLIENT_NAME=client_abc
BRAND_NAME=Client ABC Support
BRAND_LOGO_URL=https://client-abc.com/logo.svg
BRAND_PRIMARY_COLOR=#ff6600
SUPPORT_EMAIL=support@client-abc.com

# Domains
CHATWOOT_DOMAIN=inbox.client-abc.com
ATLAS_DOMAIN=atlas.client-abc.com
DASHBOARD_DOMAIN=dashboard.client-abc.com
N8N_DOMAIN=n8n.client-abc.com

# Generate secrets (IMPORTANT!)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
CHATWOOT_SECRET_KEY=$(openssl rand -hex 64)
DASHBOARD_JWT_SECRET=$(openssl rand -hex 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Client-specific API keys
OPENAI_API_KEY=sk-...
WHATSAPP_API_KEY=...
SMTP_USERNAME=noreply@client-abc.com
SMTP_PASSWORD=...

# (Leave CHATWOOT_API_TOKEN empty for now, will generate after first login)
```

**Save secrets to password manager:**
```bash
# Create secrets backup
cat .env | grep -E 'PASSWORD|SECRET|KEY' > .env.secrets
chmod 600 .env.secrets

# Upload to 1Password / Bitwarden
# Then delete from server:
# rm .env.secrets
```

#### 2.3 Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

#### 2.4 Start Platform

```bash
# First run (includes database initialization)
./scripts/start.sh

# Expected output:
# 🚀 Starting Nexa AI Platform...
# 📋 Checking configuration...
# ✅ Configuration valid
# 📦 Pulling Docker images...
# 🐳 Starting services...
# 🗄️  Initializing databases...
# ✅ Nexa AI Platform started successfully!
```

#### 2.5 Verify Services

```bash
# Check all services are running
docker compose -f docker-compose.nexa-platform.yml ps

# Should show:
# nexa_postgres        running (healthy)
# nexa_redis           running (healthy)
# nexa_chatwoot_app    running (healthy)
# nexa_chatwoot_sidekiq running
# nexa_atlas_sdr       running (healthy)
# nexa_dashboard       running
# nexa_n8n             running

# Check logs
./scripts/logs.sh chatwoot_app
```

---

### Phase 3: Initial Configuration

#### 3.1 Access Chatwoot

1. Open browser: https://inbox.client-abc.com
2. You should see white-labeled login page (no "Chatwoot" branding)
3. Default admin credentials (from seed):
   - Email: `admin@example.com`
   - Password: `password`

**⚠️ IMPORTANT:** Change admin password immediately!

#### 3.2 Create Chatwoot Account & Inbox

```bash
# OR create via Rails console for more control:
docker exec -it nexa_chatwoot_app bundle exec rails c

# In Rails console:
account = Account.create!(name: 'Client ABC')
user = User.create!(
  email: 'admin@client-abc.com',
  name: 'Admin',
  password: 'temp-password-change-me',
  confirmed_at: Time.now
)
AccountUser.create!(account: account, user: user, role: :administrator)

# Create WhatsApp inbox
inbox = Inbox.create!(
  account: account,
  name: 'WhatsApp',
  channel_type: 'Channel::Whatsapp'
)
puts inbox.id  # Save this ID for .env
exit
```

#### 3.3 Generate Chatwoot API Token

**Via UI:**
1. Login to Chatwoot
2. Settings → Integrations → API Access
3. Click "Platform" tab
4. Click "Create Token"
5. Copy token

**Via Rails console:**
```bash
docker exec -it nexa_chatwoot_app bundle exec rails c

account = Account.first
api_token = account.platform_app_api_keys.create!(
  name: 'Atlas Nexa Integration'
)
puts api_token.access_token
# Output: abc123xyz789...
exit
```

**Add to .env:**
```bash
nano .env

# Update these lines:
CHATWOOT_API_TOKEN=abc123xyz789...
CHATWOOT_ACCOUNT_ID=1  # From account.id above
CHATWOOT_INBOX_ID=1    # From inbox.id above

# Save and exit
```

#### 3.4 Restart Services

```bash
./scripts/restart.sh
```

---

### Phase 4: Integration Setup

#### 4.1 Configure WhatsApp (Evolution API or UAZAPI)

**If using Evolution API:**

```bash
# Add to .env
WHATSAPP_API_URL=https://evolution.nexateam.com.br
WHATSAPP_API_KEY=...
WHATSAPP_PHONE_ID=...

# Restart Atlas Nexa
docker compose -f docker-compose.nexa-platform.yml restart atlas_nexa
```

#### 4.2 Set Up N8N Workflows

1. Access N8N: https://n8n.client-abc.com
2. Create owner account on first login
3. Import workflows:
   - Go to Workflows → Import from File
   - Upload: `n8n-workflows/atlas-chatwoot-handoff.json`
   - Upload: `n8n-workflows/chatwoot-atlas-sync.json`

4. Configure credentials:
   - Add Chatwoot API credentials
   - Add Supabase credentials (for Atlas database)
   - Add WhatsApp API credentials

5. Activate workflows

#### 4.3 Test Integration

**Manual test:**

```bash
# Trigger handoff webhook
curl -X POST https://n8n.client-abc.com/webhook/atlas-qualified-lead \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-lead-123",
    "name": "Test Lead",
    "phone": "+5511999999999",
    "qualification_score": 8,
    "interest": "Test integration",
    "bot_history": "Bot: Hello\nLead: Hi there"
  }'

# Check Chatwoot inbox for new conversation
# Should appear in https://inbox.client-abc.com/app/accounts/1/conversations
```

---

### Phase 5: Dashboard Setup

#### 5.1 Access Dashboard

1. Open: https://dashboard.client-abc.com
2. Login with credentials (configured in dashboard app)

#### 5.2 Verify Metrics

Dashboard should show:
- Total leads (from Atlas Nexa)
- Qualified leads
- Active conversations (from Chatwoot)
- Resolution time
- Agent performance

**If metrics are missing:**

```bash
# Check database connections
docker exec -it nexa_dashboard /bin/sh

# Test Postgres connection
psql $CHATWOOT_DATABASE_URL -c "SELECT COUNT(*) FROM conversations;"
psql $ATLAS_DATABASE_URL -c "SELECT COUNT(*) FROM leads;"

exit
```

---

### Phase 6: Production Hardening

#### 6.1 SSL/TLS Configuration

**If using Traefik (included in docker-compose):**

Traefik will auto-generate Let's Encrypt certificates for all domains.

**Verify SSL:**
```bash
# Check certificate
curl -vI https://inbox.client-abc.com 2>&1 | grep -i "SSL certificate"

# Should show "SSL certificate verify ok"
```

**If SSL fails:**

```bash
# Check Traefik logs
docker logs nexa_traefik

# Common issues:
# 1. DNS not propagated → wait 5-10 minutes
# 2. Port 80/443 not accessible → check firewall
# 3. Rate limit hit → use staging Let's Encrypt first
```

#### 6.2 Firewall Configuration

```bash
# Install UFW (if not present)
apt install ufw

# Allow SSH (IMPORTANT! Do this first to avoid lockout)
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow Portainer (optional)
ufw allow 9443/tcp

# Enable firewall
ufw enable

# Verify rules
ufw status
```

#### 6.3 Backup Configuration

**Automated backups with cron:**

```bash
# Create backup script
cat > /opt/nexa-platform/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/nexa-platform"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec nexa_postgres pg_dumpall -U postgres | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# Backup Redis
docker exec nexa_redis redis-cli --rdb /data/dump.rdb save
docker cp nexa_redis:/data/dump.rdb $BACKUP_DIR/redis_$DATE.rdb

# Backup volumes
docker run --rm \
  -v nexa_chatwoot_storage:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/chatwoot_storage_$DATE.tar.gz /data

# Backup .env
cp /opt/nexa-platform/docker/.env $BACKUP_DIR/env_$DATE

# Cleanup old backups (keep last 30 days)
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/nexa-platform/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e

# Add line:
0 2 * * * /opt/nexa-platform/backup.sh >> /var/log/nexa-backup.log 2>&1
```

**Upload backups to cloud storage (optional):**

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure DigitalOcean Spaces / S3
rclone config

# Add to backup script:
rclone sync /opt/backups/nexa-platform remote:nexa-backups/client-abc/
```

#### 6.4 Monitoring Setup

**Install monitoring stack (optional but recommended):**

```bash
# Add to docker-compose.nexa-platform.yml:

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - nexa_network
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=<strong-password>
    networks:
      - nexa_network
    ports:
      - "3100:3000"
    restart: unless-stopped
```

**Access Grafana:** https://dashboard.client-abc.com:3100

---

### Phase 7: Client Handoff

#### 7.1 Create Admin User for Client

```bash
# Via Chatwoot UI
# Settings → Team → Add Agent → Role: Administrator

# Or via Rails console
docker exec -it nexa_chatwoot_app bundle exec rails c

account = Account.first
client_user = User.create!(
  email: 'admin@client-abc.com',
  name: 'Client Admin',
  password: SecureRandom.hex(16),  # Generate strong password
  confirmed_at: Time.now
)
AccountUser.create!(
  account: account,
  user: client_user,
  role: :administrator
)

puts "Email: #{client_user.email}"
puts "Temp Password: #{client_user.password}"  # Note: won't work, use password reset
exit

# Send password reset email
# Chatwoot UI → Team → Client Admin → Send Reset Password
```

#### 7.2 Documentation for Client

**Create client-specific docs:**

```markdown
# Client ABC - Nexa AI Platform Guide

## Access Points

- **Inbox (Chatwoot):** https://inbox.client-abc.com
- **Dashboard:** https://dashboard.client-abc.com
- **Support:** support@nexateam.com.br

## Login Credentials

- **Email:** admin@client-abc.com
- **Password:** [sent separately via secure channel]

## Quick Start

1. Login to Chatwoot inbox
2. Connect your WhatsApp number (Settings → Inboxes → Add WhatsApp)
3. Configure team members (Settings → Team)
4. Atlas Nexa (AI SDR) will automatically qualify leads and create conversations

## Support

For technical support, contact Nexa Team:
- Email: support@nexateam.com.br
- WhatsApp: +55 11 9 9999-9999
```

#### 7.3 Knowledge Base

**Create internal KB for team:**

```markdown
# Client ABC Deployment

**Deployed:** 2025-11-06
**Server:** nexa-client-abc (IP: x.x.x.x)
**Location:** DigitalOcean NYC3

## Credentials

Stored in: 1Password vault "Client ABC"

- Server SSH
- Postgres root
- Chatwoot admin
- OpenAI API key
- WhatsApp API key

## Maintenance

**Backups:** Daily 2 AM → DigitalOcean Spaces
**Monitoring:** Grafana dashboard
**Logs:** Portainer or `./scripts/logs.sh`

## Contacts

- **Client:** John Doe (john@client-abc.com)
- **Technical:** Jane Smith (tech@client-abc.com)
```

---

## Troubleshooting

### Services Won't Start

**Check logs:**
```bash
./scripts/logs.sh
```

**Common issues:**

1. **Port already in use:**
   ```bash
   # Check what's using port
   netstat -tulpn | grep :3000

   # Change port in .env
   CHATWOOT_PORT=3001
   ```

2. **Database connection failed:**
   ```bash
   # Check Postgres is running
   docker exec -it nexa_postgres pg_isready

   # Verify password
   docker exec -it nexa_postgres psql -U postgres -c "SELECT 1"
   ```

3. **Out of memory:**
   ```bash
   # Check memory usage
   free -h

   # Upgrade server or reduce service limits in docker-compose.yml
   ```

### SSL Certificate Errors

```bash
# Check Traefik logs
docker logs nexa_traefik | grep -i acme

# Test DNS resolution
nslookup inbox.client-abc.com

# Force certificate refresh
docker exec nexa_traefik rm /letsencrypt/acme.json
docker restart nexa_traefik
```

### Chatwoot UI Shows "Chatwoot" Branding

**Means custom image not being used:**

```bash
# Verify image
docker inspect nexa_chatwoot_app | grep Image

# Should show: nexateam/chatwoot-custom:v3.15.0
# If shows: chatwoot/chatwoot:v3.15.0 → wrong image

# Fix:
# 1. Build custom image (see 03-BUILD-PROCESS.md)
# 2. Push to registry
# 3. Update .env:
CHATWOOT_IMAGE=nexateam/chatwoot-custom:v3.15.0

# 4. Restart
./scripts/restart.sh
```

### Atlas Nexa Not Creating Chatwoot Conversations

**Debug checklist:**

```bash
# 1. Check Atlas Nexa logs
./scripts/logs.sh atlas_nexa

# 2. Verify API token
docker exec -it nexa_atlas_sdr env | grep CHATWOOT_API_TOKEN

# 3. Test API manually
curl https://inbox.client-abc.com/api/v1/accounts/1/conversations \
  -H "Authorization: Bearer $CHATWOOT_API_TOKEN"

# Should return list of conversations

# 4. Check N8N workflow
# Login to N8N → Workflows → atlas-chatwoot-handoff
# Click "Test Workflow"
```

---

## Cost Estimation

### Per-Client Infrastructure

**DigitalOcean Droplet:**
- $24/month (4GB RAM, 2 vCPU, 80GB SSD)

**Domain + DNS:**
- $12/year (if using client's domain, $0)

**Backups:**
- $5/month (DigitalOcean Spaces, 250GB)

**Monitoring:**
- $0 (self-hosted Grafana)

**Total:** ~$30/month per client

### Scaling Economics

| Clients | Infrastructure Cost | Revenue (@ $200/mo) | Margin |
|---------|---------------------|---------------------|--------|
| 1       | $30/mo              | $200/mo             | 85%    |
| 5       | $150/mo             | $1,000/mo           | 85%    |
| 10      | $300/mo             | $2,000/mo           | 85%    |
| 20      | $600/mo             | $4,000/mo           | 85%    |

**At 20+ clients:** Migrate to Kubernetes cluster for better economics (shared infrastructure).

---

## Next Steps

✅ **Deployment guide complete!**

You're now ready to deploy Nexa AI Platform for clients.

**Quick deployment checklist:**
- [ ] Provision server (DigitalOcean droplet)
- [ ] Configure DNS (A records for 4 subdomains)
- [ ] Clone repository to server
- [ ] Configure .env (client branding, secrets, API keys)
- [ ] Run `./scripts/start.sh`
- [ ] Generate Chatwoot API token
- [ ] Set up N8N workflows
- [ ] Test integration (Atlas → Chatwoot handoff)
- [ ] Create client admin user
- [ ] Deliver access credentials

**For next client:**
Simply repeat Phase 2-7 (infrastructure is reusable template).

**Template repository:** Create GitHub template from this for easy cloning:
```bash
gh repo create nexateam/nexa-platform-template --template --public
```
